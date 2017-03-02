#tag Class
Protected Class ZipArchive
	#tag Method, Flags = &h0
		Function AppendFile(ZipPath As String, FileData As Readable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, ResetIndex As Integer = - 1) As Boolean
		  If mDirectoryHeader.Signature <> DIRECTORY_SIGNATURE Then
		    mLastError = ERR_NOT_ZIPPED
		    Return False
		  End If
		  mArchiveStream.Flush
		  mArchiveStream.Position = mDirectoryHeaderOffset
		  
		  Dim header As ZipFileHeader
		  header.FilenameLength = ZipPath.LenB
		  header.ExtraLength = 0
		  header.Version = mDirectoryHeader.Version
		  header.Signature = FILE_SIGNATURE
		  Dim modtime As Pair = ConvertDate(New Date)
		  header.ModDate = modtime.Left
		  header.ModTime = modtime.Right
		  Dim newfileheaderoffset As UInt64 = mArchiveStream.Position
		  mArchiveStream.Length = mArchiveStream.Position + header.Size + ZipPath.LenB
		  mArchiveStream.Position = mArchiveStream.Length
		  Dim crc As UInt32
		  If FileData <> Nil And (CompressionLevel > 0 Or CompressionLevel = Z_DEFAULT_COMPRESSION) Then
		    header.Method = 8
		    mZipStream.Deflater.Reset
		    Do Until FileData.EOF
		      Dim data As MemoryBlock = FileData.Read(CHUNK_SIZE)
		      crc = CRC32(data, crc, data.Size)
		      mZipStream.Write(data)
		    Loop
		    mZipStream.Flush(Z_FINISH)
		    header.UncompressedSize = mZipStream.Deflater.Total_In
		    header.CompressedSize = mZipStream.Deflater.Total_Out
		  Else
		    header.Method = 0
		    Dim start As UInt64 = mArchiveStream.Position
		    If FileData <> Nil Then
		      Do Until FileData.EOF
		        Dim data As MemoryBlock = FileData.Read(CHUNK_SIZE)
		        crc = CRC32(data, crc, data.Size)
		        mArchiveStream.Write(data)
		      Loop
		    End If
		    header.CompressedSize = mArchiveStream.Position - start
		    header.UncompressedSize = header.CompressedSize
		  End If
		  header.CRC32 = crc
		  mDirectoryHeaderOffset = mArchiveStream.Position ' record the endoffile/startofdirectory
		  mArchiveStream.Flush
		  
		  ' write the file header
		  mArchiveStream.Position = newfileheaderoffset
		  mArchiveStream.Write(header.StringValue(True).Left(header.Size))
		  mArchiveStream.Write(ZipPath)
		  'mArchiveStream.Write(ZipExtra)
		  mArchiveStream.Flush
		  
		  
		  ' write the updated directory header
		  mArchiveStream.Position = mDirectoryHeaderOffset
		  mDirectoryHeader.CompressedSize = mDirectoryHeader.CompressedSize + header.CompressedSize
		  mDirectoryHeader.UncompressedSize = mDirectoryHeader.UncompressedSize + header.UncompressedSize
		  mDirectoryHeader.CRC32 = CRC32Combine(mDirectoryHeader.CRC32, header.CRC32, header.CompressedSize)
		  mDirectoryHeader.ModDate = modtime.Left
		  mDirectoryHeader.ModTime = modtime.Right
		  mDirectoryHeader.CommentLength = mArchiveComment.Size
		  If mArchiveName = "" Then mArchiveName = ZipPath
		  mDirectoryHeader.FilenameLength = mArchiveName.Size
		  mDirectoryHeader.ExtraLength = mExtraData.Size
		  mArchiveStream.Write(mDirectoryHeader.StringValue(True).Left(mDirectoryHeader.Size))
		  mArchiveStream.Write(mArchiveName)
		  mArchiveStream.Write(mExtraData)
		  mArchiveStream.Write(mArchiveComment)
		  mArchiveStream.Flush
		  
		  ' write the updated directory footer
		  mDirectoryFooter.DirectorySize = mArchiveStream.Position - mDirectoryHeaderOffset
		  mDirectoryFooter.Offset = mDirectoryHeaderOffset
		  mDirectoryFooter.ThisRecordCount = mDirectoryFooter.ThisRecordCount + 1
		  mDirectoryFooter.TotalRecordCount = mDirectoryFooter.TotalRecordCount + 1
		  mArchiveStream.Write(mDirectoryFooter.StringValue(True).Left(mDirectoryFooter.Size))
		  mArchiveStream.Flush
		  
		  Return Me.Reset(ResetIndex)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Close()
		  If mArchiveStream <> Nil Then
		    mArchiveStream.Close
		    mZipStream.Close
		    mArchiveStream = Nil
		    mIndex = -1
		    mDirectoryHeaderOffset = 0
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(ArchiveStream As BinaryStream)
		  mArchiveStream = ArchiveStream
		  mArchiveStream.LittleEndian = True
		  If Not Me.Reset(0) Then Raise New zlibException(ERR_NOT_ZIPPED)
		  mZipStream = ZStream.Open(mArchiveStream, RAW_ENCODING)
		  mZipStream.BufferedReading = False
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(ArchiveStream As BinaryStream, CompressionLevel As Integer)
		  mArchiveStream = ArchiveStream
		  mArchiveStream.LittleEndian = True
		  If Not Me.Reset(0) Then Raise New zlibException(ERR_NOT_ZIPPED)
		  mZipStream = ZStream.CreatePipe(mArchiveStream, mArchiveStream, CompressionLevel, Z_DEFAULT_STRATEGY, RAW_ENCODING, DEFAULT_MEM_LVL)
		  mZipStream.BufferedReading = False
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function ConvertDate(NewDate As Date) As Pair
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

	#tag Method, Flags = &h0
		 Shared Function Create(ZipFile As FolderItem, Overwrite As Boolean = False, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION) As zlib.ZipArchive
		  Dim bs As BinaryStream = BinaryStream.Create(ZipFile, Overwrite)
		  Dim footer As ZipDirectoryFooter
		  Dim header As ZipDirectoryHeader
		  header.Signature = DIRECTORY_SIGNATURE
		  header.Version = 2
		  header.VersionNeeded = 2
		  Dim nm As String = "Untitled.zip"
		  Dim cmnt As String = ""
		  Dim extra As String = ""
		  header.FilenameLength = nm.LenB
		  header.CommentLength = cmnt.LenB
		  header.ExtraLength = extra.LenB
		  footer.Offset = 0
		  footer.Signature = DIRECTORY_FOOTER_HEADER
		  bs.Write(header.StringValue(True))
		  bs.Write(nm)
		  bs.Write(extra)
		  bs.Write(cmnt)
		  bs.Write(footer.StringValue(True))
		  bs.Flush
		  bs.Position = 0
		  Return New ZipArchive(bs, CompressionLevel)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CurrentCRC32() As UInt32
		  If mIndex > -1 Then Return mCurrentFile.CRC32 Else Return 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CurrentDataOffset() As UInt64
		  Return mCurrentDataOffset
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CurrentExtra() As MemoryBlock
		  If mIndex > -1 Then Return mCurrentExtra
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CurrentIndex() As Integer
		  Return mIndex
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CurrentModificationDate() As Date
		  If mIndex = -1 Then Return Nil
		  
		  Return ConvertDate(mCurrentFile.ModDate, mCurrentFile.ModTime)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub CurrentModificationDate(Assigns NewModDate As Date)
		  If mIndex = -1 Then Raise New OutOfBoundsException
		  
		  Dim p As Pair = ConvertDate(NewModDate)
		  mCurrentFile.ModDate = p.Left
		  mCurrentFile.ModTime = p.Right
		  mArchiveStream.Position = mArchiveStream.Position - mCurrentFile.Size
		  mArchiveStream.Write(mCurrentFile.StringValue(True).Left(mCurrentFile.Size))
		  mArchiveStream.Flush
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CurrentName() As String
		  If mIndex > -1 Then Return mCurrentName
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CurrentSize() As Integer
		  If mIndex > -1 Then Return mCurrentFile.CompressedSize Else Return -1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CurrentUncompressedSize() As Integer
		  If mIndex > -1 Then Return mCurrentFile.UncompressedSize Else Return -1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  Me.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MoveNext(ExtractTo As FolderItem, Overwrite As Boolean) As Boolean
		  ExtractTo = CreateTree(ExtractTo, mCurrentName)
		  Dim bs As BinaryStream
		  If Not ExtractTo.Directory Then bs = BinaryStream.Create(ExtractTo, Overwrite)
		  Return Me.MoveNext(bs)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MoveNext(ExtractTo As Writeable) As Boolean
		  If mDirectoryHeaderOffset = 0 Then Raise New IOException
		  ' extract the current item
		  If ExtractTo <> Nil Then
		    Select Case mCurrentFile.Method
		    Case 0 ' not compressed
		      If mCurrentFile.UncompressedSize > 0 Then ExtractTo.Write(mArchiveStream.Read(mCurrentFile.CompressedSize))
		    Case 8 ' deflated
		      mZipStream.Inflater.Reset
		      Dim p As UInt64 = mArchiveStream.Position
		      If ValidateChecksums Then mCurrentCRC = 0 Else mCurrentCRC = mCurrentFile.CRC32
		      Do Until mArchiveStream.Position - p >= mCurrentFile.CompressedSize
		        Dim offset As UInt64 = mArchiveStream.Position - p
		        Dim sz As Integer = Min(mCurrentFile.CompressedSize - offset, CHUNK_SIZE)
		        Dim data As MemoryBlock = mZipStream.Read(sz)
		        If ValidateChecksums Then mCurrentCRC = CRC32(data, mCurrentCRC, data.Size)
		        ExtractTo.Write(data)
		      Loop
		      If ValidateChecksums And Not (mCurrentCRC = mCurrentFile.CRC32) Then
		        mLastError = ERR_CHECKSUM_MISMATCH
		        Return False
		      End If
		    Else
		      mLastError = ERR_NOT_ZIPPED
		      Return False
		    End Select
		  Else
		    mArchiveStream.Position = mArchiveStream.Position + mCurrentFile.CompressedSize
		  End If
		  If ValidateChecksums Then mRunningCRC = CRC32Combine(mRunningCRC, mCurrentCRC, mCurrentFile.UncompressedSize)
		  
		  ' read the next entry header
		  If mArchiveStream.Position >= mDirectoryHeaderOffset Then
		    mLastError = ERR_END_ARCHIVE
		    Return False
		  End If
		  mIndex = mIndex + 1
		  mCurrentFile.StringValue(True) = mArchiveStream.Read(mCurrentFile.Size)
		  If mCurrentFile.Signature <> FILE_SIGNATURE Then
		    mLastError = ERR_INVALID_ENTRY
		    Return False
		  Else
		    mCurrentName = mArchiveStream.Read(mCurrentFile.FilenameLength)
		    mCurrentExtra = mArchiveStream.Read(mCurrentFile.ExtraLength)
		    
		    If BitAnd(mCurrentFile.Flag, 4) = 4 And mCurrentFile.CompressedSize = 0 Then ' footer follows
		      Dim footer As ZipFileFooter
		      footer.StringValue(True) = mArchiveStream.Read(footer.Size)
		      If footer.Signature <> FILE_FOOTER_SIGNATURE Then
		        mArchiveStream.Position = mArchiveStream.Position - footer.Size
		      Else
		        mCurrentFile.CompressedSize = footer.ComressedSize
		        mCurrentFile.UncompressedSize = footer.UncompressedSize
		      End If
		    End If
		    mCurrentDataOffset = mArchiveStream.Position
		    Return True
		  End If
		  Break
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(ZipFile As FolderItem, Readwrite As Boolean = False, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION) As zlib.ZipArchive
		  Dim bs As BinaryStream = BinaryStream.Open(ZipFile, Readwrite)
		  If bs <> Nil Then
		    If Readwrite Then
		      Return New ZipArchive(bs, CompressionLevel)
		    Else
		      Return New ZipArchive(bs)
		    End If
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Reset(Index As Integer = 0) As Boolean
		  mArchiveStream.Position = mArchiveStream.Length - 4
		  mDirectoryHeaderOffset = 0
		  mDirectoryHeader.StringValue(True) = ""
		  mRunningCRC = 0
		  Do Until mDirectoryHeaderOffset > 0
		    If mArchiveStream.ReadUInt32 = DIRECTORY_FOOTER_HEADER Then
		      mArchiveStream.Position = mArchiveStream.Position - 4
		      mDirectoryFooter.StringValue(True) = mArchiveStream.Read(mDirectoryFooter.Size)
		      mArchiveStream.Position = mDirectoryFooter.Offset
		      mDirectoryHeaderOffset = mArchiveStream.Position
		      mDirectoryHeader.StringValue(True) = mArchiveStream.Read(mDirectoryHeader.Size)
		      mArchiveName = mArchiveStream.Read(mDirectoryHeader.FilenameLength)
		      mExtraData = mArchiveStream.Read(mDirectoryHeader.ExtraLength)
		      mArchiveComment = mArchiveStream.Read(mDirectoryHeader.CommentLength)
		      If mDirectoryFooter.ThisRecordCount = 0 Then
		        mIndex = -1
		        Return True
		      End If
		    Else
		      mArchiveStream.Position = mArchiveStream.Position - 5
		    End If
		  Loop Until mArchiveStream.Position < 22
		  
		  mIndex = -1
		  mCurrentExtra = Nil
		  mCurrentFile.StringValue(True) = ""
		  mCurrentName = ""
		  If mDirectoryHeaderOffset = 0 Then
		    mLastError = ERR_NOT_ZIPPED
		    Return False
		  End If
		  
		  mArchiveStream.Position = mDirectoryHeader.Offset
		  Do
		    If Not Me.MoveNext(Nil) Then Return (Index = -1 And mLastError = ERR_END_ARCHIVE)
		  Loop Until mIndex >= Index And Index > -1
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Test() As Boolean
		  If Not Me.Reset(0) Then Return False
		  Dim vc As Boolean = ValidateChecksums
		  ValidateChecksums = True
		  Dim bs As BinaryStream
		  Do
		    Dim data As New MemoryBlock(0)
		    bs = New BinaryStream(data)
		    bs.Close
		  Loop Until Not Me.MoveNext(bs)
		  ValidateChecksums = vc
		  If mLastError = ERR_END_ARCHIVE Then Return mRunningCRC = mDirectoryHeader.CRC32
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mArchiveComment <> Nil Then Return mArchiveComment
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  mArchiveComment = value
			End Set
		#tag EndSetter
		ArchiveComment As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mArchiveName <> Nil Then Return mArchiveName
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  mArchiveName = value
			End Set
		#tag EndSetter
		ArchiveName As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Select Case True
			  Case BitAnd(mDirectoryHeader.Flag, 1) = 1 And BitAnd(mDirectoryHeader.Flag, 2) = 2
			    Return 1 ' fastest
			  Case BitAnd(mDirectoryHeader.Flag, 1) = 1 And BitAnd(mDirectoryHeader.Flag, 2) <> 2
			    Return 9 ' best
			  Case BitAnd(mDirectoryHeader.Flag, 1) <> 1 And BitAnd(mDirectoryHeader.Flag, 2) <> 2
			    Return 6 ' normal
			  Case BitAnd(mDirectoryHeader.Flag, 1) <> 1 And BitAnd(mDirectoryHeader.Flag, 2) = 2
			    Return 3 ' fast
			  Case mDirectoryHeader.Method = 0
			    Return 0 ' none
			  End Select
			  
			  
			End Get
		#tag EndGetter
		CompressionLevel As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return BitAnd(mDirectoryHeader.Flag, 1) = 1
			End Get
		#tag EndGetter
		IsEncrypted As Boolean
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mArchiveComment As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mArchiveName As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mArchiveStream As BinaryStream
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentCRC As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentDataOffset As UInt64
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentExtra As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentFile As ZipFileHeader
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentName As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDirectoryFooter As ZipDirectoryFooter
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDirectoryHeader As ZipDirectoryHeader
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDirectoryHeaderOffset As UInt32
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
		Private mSpanOffset As UInt32 = 0
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mZipStream As zlib.ZStream
	#tag EndProperty

	#tag Property, Flags = &h0
		ValidateChecksums As Boolean = True
	#tag EndProperty


	#tag Constant, Name = DIRECTORY_FOOTER_HEADER, Type = Double, Dynamic = False, Default = \"&h06054b50", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = DIRECTORY_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h02014b50", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = FILE_FOOTER_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h08074b50", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = FILE_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h04034b50", Scope = Protected
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			InheritedFrom="Object"
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
	#tag EndViewBehavior
End Class
#tag EndClass
