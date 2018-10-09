#tag Class
Protected Class ZipArchive
	#tag Method, Flags = &h0
		Sub Close()
		  If mArchiveStream <> Nil Then mArchiveStream.Close
		  If mZipStream <> Nil Then mZipStream.Close
		  mArchiveStream = Nil
		  mZipStream = Nil
		  mIndex = -1
		  mDirectoryFooter.Offset = 0
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(ArchiveStream As BinaryStream)
		  mArchiveStream = ArchiveStream
		  mArchiveStream.LittleEndian = True
		  If Not Me.Reset(0) Then Raise New zlibException(mLastError)
		  mZipStream = ZStream.Open(mArchiveStream, RAW_ENCODING)
		  mZipStream.BufferedReading = False
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function ConvertDate(NewDate As Date) As Pair
		  ' Convert the passed Date object into MS-DOS style datestamp and timestamp (16 bits each)
		  ' The DOS format has a resolution of two seconds, no concept of time zones, and is valid 
		  ' for dates between 1/1/1980 and 12/31/2107
		  
		  Dim h, m, s, dom, mon, year As UInt32
		  Dim dt, tm As UInt16
		  h = NewDate.Hour
		  m = NewDate.Minute
		  s = NewDate.Second
		  dom = NewDate.Day
		  mon = NewDate.Month
		  year = NewDate.Year - 1980
		  
		  If year > 127 Then Raise New OutOfBoundsException
		  
		  dt = dom
		  dt = dt Or ShiftLeft(mon, 5)
		  dt = dt Or ShiftLeft(year, 9)
		  
		  tm = s \ 2
		  tm = tm Or ShiftLeft(m, 5)
		  tm = tm Or ShiftLeft(h, 11)
		  
		  Return dt:tm
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function ConvertDate(Dt As UInt16, tm As UInt16) As Date
		  ' Convert the passed MS-DOS style date and time into a Date object. 
		  ' The DOS format has a resolution of two seconds, no concept of time zones, 
		  ' and is valid for dates between 1/1/1980 and 12/31/2107
		  
		  Dim h, m, s, dom, mon, year As Integer
		  h = ShiftRight(tm, 11)
		  m = ShiftRight(tm, 5) And &h3F
		  s = (tm And &h1F) * 2
		  dom = dt And &h1F
		  mon = ShiftRight(dt, 5) And &h0F
		  year = (ShiftRight(dt, 9) And &h7F) + 1980
		  
		  Return New Date(year, mon, dom, h, m, s)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Count() As Integer
		  Return mDirectoryFooter.ThisRecordCount
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  Me.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function FindDirectoryFooter(Stream As BinaryStream, ByRef Footer As ZipDirectoryFooter, ByRef IsEmpty As Boolean) As Boolean
		  Dim pos As UInt64 = Stream.Position
		  If Stream.Length >= MIN_ARCHIVE_SIZE + &hFFFF Then 
		    Stream.Position = Stream.Length - (MIN_ARCHIVE_SIZE + &hFFFF) ' footer size + max comment length
		  End If
		  Do Until Footer.Offset > 0
		    If Stream.ReadUInt32 = ZIP_DIRECTORY_FOOTER_SIGNATURE Then
		      Stream.Position = Stream.Position - 4
		      If ReadDirectoryFooter(Stream, Footer) Then Exit Do
		    Else
		      Stream.Position = Stream.Position - 3
		    End If
		  Loop Until Stream.EOF
		  Stream.Position = pos
		  IsEmpty = (Stream.Length = MIN_ARCHIVE_SIZE And Footer.Offset = 0 And Footer.DirectorySize = 0)
		  Return footer.Offset > MIN_ARCHIVE_SIZE Or IsEmpty
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function GetDirectory(Stream As BinaryStream) As Dictionary
		  Dim footer As ZipDirectoryFooter
		  Dim isempty As Boolean
		  If Not FindDirectoryFooter(Stream, footer, isempty) Then Return Nil
		  Stream.Position = footer.Offset
		  Dim data As MemoryBlock = Stream.Read(footer.DirectorySize)
		  Dim ret As New Dictionary
		  Dim bs As New BinaryStream(data)
		  Do Until bs.EOF
		    Dim header As ZipDirectoryHeader
		    If Not ReadDirectoryHeader(bs, header) Then Break
		    Dim name As String = bs.Read(header.FilenameLength)
		    Call bs.Read(header.CommentLength + header.ExtraLength)
		    ret.Value(name) = header.Offset
		  Loop
		  Return ret
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function GetEntryIndexByName(Stream As BinaryStream, Name As String) As Integer
		  Dim footer As ZipDirectoryFooter
		  Dim isempty As Boolean
		  If Not FindDirectoryFooter(Stream, footer, isempty) Then Return -2
		  Stream.Position = footer.Offset
		  Dim index As Integer
		  Do Until Stream.Position >= footer.Offset + footer.DirectorySize
		    Dim header As ZipDirectoryHeader
		    If Not ReadDirectoryHeader(Stream, header) Then Return -3
		    If name = Stream.Read(header.FilenameLength) Then Return index
		    index = index + 1
		  Loop
		  
		  Return -1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MoveNext(ExtractTo As FolderItem, Overwrite As Boolean) As Boolean
		  Dim bs As BinaryStream
		  If Not ExtractTo.Directory Then bs = BinaryStream.Create(ExtractTo, Overwrite)
		  Return Me.MoveNext(bs)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MoveNext(ExtractTo As Writeable) As Boolean
		  ' extract the current item
		  If ExtractTo <> Nil Then
		    Dim crc As UInt32
		    Select Case mCurrentEntry.Method
		    Case 0 ' not compressed
		      If mCurrentEntry.UncompressedSize > 0 Then ExtractTo.Write(mArchiveStream.Read(mCurrentEntry.CompressedSize))
		    Case 8 ' deflated
		      mZipStream.Reset
		      Dim p As UInt64 = mArchiveStream.Position
		      Do Until mArchiveStream.Position - p >= mCurrentEntry.CompressedSize
		        Dim offset As UInt64 = mArchiveStream.Position - p
		        Dim sz As Integer = Min(mCurrentEntry.CompressedSize - offset, CHUNK_SIZE)
		        Dim data As MemoryBlock = mZipStream.Read(sz)
		        If data.Size > 0 Then
		          If ValidateChecksums Then crc = CRC32(data, crc, data.Size)
		          ExtractTo.Write(data)
		        End If
		      Loop
		      If ValidateChecksums And (crc <> mCurrentEntry.CRC32) Then
		        mLastError = ERR_CHECKSUM_MISMATCH
		        Return False
		      End If
		    Else
		      mLastError = ERR_UNSUPPORTED_COMPRESSION
		      Return False
		    End Select
		    If ValidateChecksums Then mRunningCRC = CRC32Combine(mRunningCRC, crc, mCurrentEntry.UncompressedSize)
		  Else
		    mArchiveStream.Position = mArchiveStream.Position + mCurrentEntry.CompressedSize
		    If ValidateChecksums Then mRunningCRC = CRC32Combine(mRunningCRC, mCurrentEntry.CRC32, mCurrentEntry.UncompressedSize)
		  End If
		  
		  ' read the next entry header
		  If mArchiveStream.Position >= mDirectoryFooter.Offset Then
		    mLastError = ERR_END_ARCHIVE
		    Return False
		  End If
		  mIndex = mIndex + 1
		  If Not ReadEntryHeader(mArchiveStream, mCurrentEntry) Then
		    mLastError = ERR_INVALID_ENTRY
		    Return False
		  End If
		  mCurrentName = mArchiveStream.Read(mCurrentEntry.FilenameLength)
		  mCurrentExtra = mArchiveStream.Read(mCurrentEntry.ExtraLength)
		  
		  If BitAnd(mCurrentEntry.Flag, 4) = 4 And mCurrentEntry.CompressedSize = 0 Then ' footer follows
		    Dim footer As ZipEntryFooter
		    If Not ReadEntryFooter(mArchiveStream, footer) Then
		      mArchiveStream.Position = mArchiveStream.Position - ZIP_ENTRY_FOOTER_SIZE
		    Else
		      mCurrentEntry.CompressedSize = footer.ComressedSize
		      mCurrentEntry.UncompressedSize = footer.UncompressedSize
		    End If
		  End If
		  mStreamPosition = mArchiveStream.Position
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(ZipFile As FolderItem) As zlib.ZipArchive
		  Return New ZipArchive(BinaryStream.Open(ZipFile))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function ReadDirectoryFooter(Stream As BinaryStream, ByRef Footer As ZipDirectoryFooter) As Boolean
		  Footer.Signature = Stream.ReadUInt32
		  Footer.ThisDisk = Stream.ReadUInt16
		  Footer.FirstDisk = Stream.ReadUInt16
		  Footer.ThisRecordCount = Stream.ReadUInt16
		  Footer.TotalRecordCount = Stream.ReadUInt16
		  Footer.DirectorySize = Stream.ReadUInt32
		  Footer.Offset = Stream.ReadUInt32
		  Footer.CommentLength = Stream.ReadUInt16
		  
		  Return Footer.Signature = ZIP_DIRECTORY_FOOTER_SIGNATURE
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function ReadDirectoryHeader(Stream As BinaryStream, ByRef Header As ZipDirectoryHeader) As Boolean
		  Header.Signature = Stream.ReadUInt32
		  Header.Version = Stream.ReadUInt16
		  Header.VersionNeeded = Stream.ReadUInt16
		  Header.Flag = Stream.ReadUInt16
		  Header.Method = Stream.ReadUInt16
		  Header.ModTime = Stream.ReadUInt16
		  Header.ModDate = Stream.ReadUInt16
		  Header.CRC32 = Stream.ReadUInt32
		  Header.CompressedSize = Stream.ReadUInt32
		  Header.UncompressedSize = Stream.ReadUInt32
		  Header.FilenameLength = Stream.ReadUInt16
		  Header.ExtraLength = Stream.ReadUInt16
		  Header.CommentLength = Stream.ReadUInt16
		  Header.DiskNumber = Stream.ReadUInt16
		  Header.InternalAttributes = Stream.ReadUInt16
		  Header.ExternalAttributes = Stream.ReadUInt32
		  Header.Offset = Stream.ReadUInt32
		  
		  Return Header.Signature = ZIP_DIRECTORY_HEADER_SIGNATURE
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function ReadEntryFooter(Stream As BinaryStream, ByRef Footer As ZipEntryFooter) As Boolean
		  Footer.Signature = Stream.ReadUInt32
		  Footer.CRC32 = Stream.ReadUInt32
		  Footer.ComressedSize = Stream.ReadUInt32
		  Footer.UncompressedSize = Stream.ReadUInt32
		  
		  Return Footer.Signature = ZIP_ENTRY_FOOTER_SIGNATURE
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function ReadEntryHeader(Stream As BinaryStream, ByRef Header As ZipEntryHeader) As Boolean
		  Header.Signature = Stream.ReadUInt32
		  Header.Version = Stream.ReadUInt16
		  Header.Flag = Stream.ReadUInt16
		  Header.Method = Stream.ReadUInt16
		  Header.ModTime = Stream.ReadUInt16
		  Header.ModDate = Stream.ReadUInt16
		  Header.CRC32 = Stream.ReadUInt32
		  Header.CompressedSize = Stream.ReadUInt32
		  Header.UncompressedSize = Stream.ReadUInt32
		  Header.FilenameLength = Stream.ReadUInt16
		  Header.ExtraLength = Stream.ReadUInt16
		  
		  Return Header.Signature = ZIP_ENTRY_HEADER_SIGNATURE
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Reset(Index As Integer = 0) As Boolean
		  mRunningCRC = 0
		  mIndex = -1
		  mCurrentExtra = Nil
		  mCurrentEntry.StringValue(True) = ""
		  mCurrentName = ""
		  Dim isempty As Boolean
		  If Not FindDirectoryFooter(mArchiveStream, mDirectoryFooter, isempty) Then
		    mLastError = ERR_NOT_ZIPPED
		    Return False
		  End If
		  
		  mArchiveStream.Position = mDirectoryFooter.Offset
		  If Not isempty Then
		    Dim header As ZipDirectoryHeader
		    If Not ReadDirectoryHeader(mArchiveStream, header) Then
		      mLastError = ERR_NOT_ZIPPED
		      Return False
		    End If
		    mArchiveStream.Position = header.Offset ' move to offset of first entry
		  End If
		  
		  Do
		    If Not Me.MoveNext(Nil) Then Return ((Index = -1 Or isempty) And mLastError = ERR_END_ARCHIVE)
		  Loop Until mIndex >= Index And Index > -1
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Test() As Boolean
		  If Not Me.Reset(0) Then Return False
		  Dim vc As Boolean = ValidateChecksums
		  ValidateChecksums = True
		  Dim nullstream As New BinaryStream(New MemoryBlock(0))
		  nullstream.Close
		  Do
		  Loop Until Not Me.MoveNext(nullstream)
		  ValidateChecksums = vc
		  Return mLastError = ERR_END_ARCHIVE
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Select Case True
			  Case BitAnd(mCurrentEntry.Flag, 1) = 1 And BitAnd(mCurrentEntry.Flag, 2) = 2
			    Return 1 ' fastest
			  Case BitAnd(mCurrentEntry.Flag, 1) = 1 And BitAnd(mCurrentEntry.Flag, 2) <> 2
			    Return 9 ' best
			  Case BitAnd(mCurrentEntry.Flag, 1) <> 1 And BitAnd(mCurrentEntry.Flag, 2) <> 2
			    Return 6 ' normal
			  Case BitAnd(mCurrentEntry.Flag, 1) <> 1 And BitAnd(mCurrentEntry.Flag, 2) = 2
			    Return 3 ' fast
			  Case mCurrentEntry.Method = 0
			    Return 0 ' none
			  End Select
			  
			  
			End Get
		#tag EndGetter
		CompressionLevel As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mIndex > -1 Then Return mCurrentEntry.CRC32 Else Return 0
			End Get
		#tag EndGetter
		CurrentCRC32 As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mIndex > -1 Then Return mCurrentExtra
			End Get
		#tag EndGetter
		CurrentExtraData As MemoryBlock
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mIndex
			End Get
		#tag EndGetter
		CurrentIndex As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mIndex = -1 Then Return Nil
			  
			  Return ConvertDate(mCurrentEntry.ModDate, mCurrentEntry.ModTime)
			End Get
		#tag EndGetter
		CurrentModificationDate As Date
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mIndex > -1 Then Return mCurrentName
			End Get
		#tag EndGetter
		CurrentName As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mIndex > -1 Then Return mCurrentEntry.CompressedSize Else Return -1
			End Get
		#tag EndGetter
		CurrentSize As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mIndex > -1 Then Return mCurrentEntry.UncompressedSize Else Return -1
			End Get
		#tag EndGetter
		CurrentUncompressedSize As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return BitAnd(mCurrentEntry.Flag, 1) = 1
			End Get
		#tag EndGetter
		IsEncrypted As Boolean
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mArchiveStream As BinaryStream
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentEntry As ZipEntryHeader
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentExtra As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentName As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDirectoryFooter As ZipDirectoryFooter
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mExtraData As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mIndex As Integer = -1
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRunningCRC As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mStreamPosition As UInt64
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mZipStream As zlib.ZStream
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mStreamPosition
			End Get
		#tag EndGetter
		StreamPosition As UInt64
	#tag EndComputedProperty

	#tag Property, Flags = &h0
		ValidateChecksums As Boolean = True
	#tag EndProperty


	#tag Constant, Name = MIN_ARCHIVE_SIZE, Type = Double, Dynamic = False, Default = \"ZIP_DIRECTORY_FOOTER_SIZE\r", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ZIP_DIRECTORY_FOOTER_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h06054b50", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ZIP_DIRECTORY_FOOTER_SIZE, Type = Double, Dynamic = False, Default = \"22", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ZIP_DIRECTORY_HEADER_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h02014b50", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ZIP_DIRECTORY_HEADER_SIZE, Type = Double, Dynamic = False, Default = \"46", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ZIP_ENTRY_FOOTER_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h08074b50", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ZIP_ENTRY_FOOTER_SIZE, Type = Double, Dynamic = False, Default = \"16", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ZIP_ENTRY_HEADER_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h04034b50", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ZIP_ENTRY_HEADER_SIZE, Type = Double, Dynamic = False, Default = \"30", Scope = Private
	#tag EndConstant


	#tag Structure, Name = ZipDirectoryFooter, Flags = &h21
		Signature As UInt32
		  ThisDisk As UInt16
		  FirstDisk As UInt16
		  ThisRecordCount As UInt16
		  TotalRecordCount As UInt16
		  DirectorySize As UInt32
		  Offset As UInt32
		CommentLength As UInt16
	#tag EndStructure

	#tag Structure, Name = ZipDirectoryHeader, Flags = &h21
		Signature As UInt32
		  Version As UInt16
		  VersionNeeded As UInt16
		  Flag As UInt16
		  Method As UInt16
		  ModTime As UInt16
		  ModDate As UInt16
		  CRC32 As UInt32
		  CompressedSize As UInt32
		  UncompressedSize As UInt32
		  FilenameLength As UInt16
		  ExtraLength As UInt16
		  CommentLength As UInt16
		  DiskNumber As UInt16
		  InternalAttributes As UInt16
		  ExternalAttributes As UInt32
		Offset As UInt32
	#tag EndStructure

	#tag Structure, Name = ZipEntryFooter, Flags = &h21
		Signature As UInt32
		  CRC32 As UInt32
		  ComressedSize As UInt32
		UncompressedSize As UInt32
	#tag EndStructure

	#tag Structure, Name = ZipEntryHeader, Flags = &h21
		Signature As UInt32
		  Version As UInt16
		  Flag As UInt16
		  Method As UInt16
		  ModTime As UInt16
		  ModDate As UInt16
		  CRC32 As UInt32
		  CompressedSize As UInt32
		  UncompressedSize As UInt32
		  FilenameLength As UInt16
		ExtraLength As UInt16
	#tag EndStructure


	#tag ViewBehavior
		#tag ViewProperty
			Name="ArchiveComment"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ArchiveName"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="CompressionLevel"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="IsEncrypted"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ValidateChecksums"
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
