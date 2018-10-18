#tag Class
Protected Class ZipReader
	#tag Method, Flags = &h0
		Sub Close()
		  If mStream <> Nil Then mStream.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(ZipStream As BinaryStream, Force As Boolean = False)
		  mStream = ZipStream
		  mStream.LittleEndian = True
		  mForced = Force
		  If Not Me.Reset(0) Then Raise New ZipException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  Me.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function FindDirectoryFooter() As Boolean
		  mStream.Position = Max(0, mStream.Length - MAX_COMMENT_SIZE - MIN_ARCHIVE_SIZE)
		  Dim last As UInt64
		  ' a zip archive can contain other zip archives, in which case it's possible
		  ' for there to be more than one Central Directory Footer in the file. We only
		  ' want the "outermost" directory footer, i.e. the last one.
		  Do Until mStream.EOF
		    If Not SeekSignature(mStream, ZIP_DIRECTORY_FOOTER_SIGNATURE) Then
		      If last = 0 And mStream.Length >= MIN_ARCHIVE_SIZE + MAX_COMMENT_SIZE Then Return False
		      mStream.Position = last
		      Exit Do
		    Else
		      last = mStream.Position
		      mStream.Position = mStream.Position + 4
		    End If
		  Loop Until mStream.Position + MAX_COMMENT_SIZE + MIN_ARCHIVE_SIZE <= mStream.Length
		  
		  If Not ReadDirectoryFooter(mStream, mDirectoryFooter) Then Return False
		  mArchiveComment = mStream.Read(mDirectoryFooter.CommentLength)
		  mIsEmpty = (mStream.Length = MIN_ARCHIVE_SIZE + mDirectoryFooter.CommentLength)
		  Return mDirectoryFooter.Offset > MIN_ARCHIVE_SIZE Or mIsEmpty
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MoveNext(ExtractTo As Writeable) As Boolean
		  ' extract the current item
		  If Not ReadEntry(ExtractTo) Then Return False
		  Return ReadHeader()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ReadEntry(Destination As Writeable) As Boolean
		  If Destination = Nil Or mCurrentEntry.CompressedSize = 0 Then
		    ' skip the current item
		    mStream.Position = mStream.Position + mCurrentEntry.CompressedSize
		    Return True
		  End If
		  
		  Dim zipstream As Readable
		  Select Case mCurrentEntry.Method
		  Case METHOD_DEFLATED
		    #If USE_ZLIB Then
		      Dim z As zlib.ZStream = zlib.ZStream.Open(mStream, zlib.RAW_ENCODING)
		      z.BufferedReading = False
		      zipstream = z
		    #else
		      mLastError = ERR_UNSUPPORTED_COMPRESSION
		      mStream.Position = mStream.Position + mCurrentEntry.CompressedSize
		      Return False
		    #endif
		    
		  Case 0 ' store
		    zipstream = mStream
		  Else
		    mLastError = ERR_UNSUPPORTED_COMPRESSION
		    mStream.Position = mStream.Position + mCurrentEntry.CompressedSize
		    Return False
		  End Select
		  
		  ' read the compressed data
		  Dim p As UInt64 = mStream.Position
		  Dim CRC As UInt32
		  Do Until mStream.Position - p >= mCurrentEntry.CompressedSize
		    Dim offset As UInt64 = mStream.Position - p
		    Dim sz As Integer = Min(mCurrentEntry.CompressedSize - offset, CHUNK_SIZE)
		    Dim data As MemoryBlock = zipstream.Read(sz)
		    If data.Size > 0 Then
		      #If USE_ZLIB Then
		        If ValidateChecksums Then CRC = zlib.CRC32(data, crc, data.Size)
		      #Else
		        If ValidateChecksums Then CRC = mCurrentEntry.CRC32
		      #endif
		      Destination.Write(data)
		    End If
		  Loop Until zipstream.EOF
		  If BitAnd(mCurrentEntry.Flag, FLAG_DESCRIPTOR) = FLAG_DESCRIPTOR Then
		    mStream.Position = mStream.Position + ZIP_ENTRY_FOOTER_SIZE
		  End If
		  
		  If ValidateChecksums And (crc <> mCurrentEntry.CRC32) Then
		    mLastError = ERR_CHECKSUM_MISMATCH
		    Return False Or mForced
		  End If
		  
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ReadHeader() As Boolean
		  ' read the next entry header
		  Dim doitanyway As Boolean = mForced And (mStream.Length - mStream.Position >= MIN_ARCHIVE_SIZE)
		  If mStream.Position >= mDirectoryFooter.Offset And Not doitanyway Then
		    mLastError = ERR_END_ARCHIVE
		    Return False
		  End If
		  
		  mIndex = mIndex + 1
		  If Not ReadEntryHeader(mStream, mCurrentEntry) Then
		    If Not mForced Then
		      mLastError = ERR_INVALID_ENTRY
		    Else
		      mLastError = ERR_END_ARCHIVE
		    End If
		    Return False
		  End If
		  mCurrentName = mStream.Read(mCurrentEntry.FilenameLength).Trim
		  If BitAnd(mCurrentEntry.Flag, FLAG_NAME_ENCODING) = FLAG_NAME_ENCODING Then ' UTF8 names
		    mCurrentName = DefineEncoding(mCurrentName, Encodings.UTF8)
		  Else ' CP437 names
		    mCurrentName = DefineEncoding(mCurrentName, Encodings.DOSLatinUS)
		  End If
		  mCurrentExtra = mStream.Read(mCurrentEntry.ExtraLength)
		  
		  If BitAnd(mCurrentEntry.Flag, FLAG_DESCRIPTOR) = FLAG_DESCRIPTOR And mCurrentEntry.CompressedSize = 0 Then ' footer follows
		    Dim datastart As UInt64 = mStream.Position
		    Dim footer As ZipEntryFooter
		    If Not FindEntryFooter(mStream, footer) Then
		      mLastError = ERR_INVALID_ENTRY
		      Return False
		    Else
		      mCurrentEntry.CompressedSize = footer.CompressedSize
		      mCurrentEntry.UncompressedSize = footer.UncompressedSize
		      mCurrentEntry.CRC32 = footer.CRC32
		    End If
		    mStream.Position = datastart
		  End If
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Reset(Index As Integer) As Boolean
		  mIndex = -1
		  mCurrentExtra = Nil
		  mCurrentEntry.StringValue(True) = ""
		  mCurrentName = ""
		  
		  If mForced Then
		    mStream.Position = 0
		    If Not SeekSignature(mStream, ZIP_ENTRY_HEADER_SIGNATURE) Then
		      mLastError = ERR_NOT_ZIPPED
		      Return False
		    End If
		  Else
		    If Not FindDirectoryFooter() Then
		      mLastError = ERR_NOT_ZIPPED
		      Return False
		    End If
		    
		    mStream.Position = mDirectoryFooter.Offset
		    If Not mIsEmpty Then
		      Dim header As ZipDirectoryHeader
		      If Not ReadDirectoryHeader(mStream, header) Then
		        mLastError = ERR_NOT_ZIPPED
		        Return False
		      End If
		      mStream.Position = header.Offset ' move to offset of first entry
		    End If
		  End If
		  
		  Do
		    If Not Me.MoveNext(Nil) Then Return ((Index = -1 Or mIsEmpty) And mLastError = ERR_END_ARCHIVE)
		  Loop Until mIndex >= Index And Index > -1
		  Return True
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mArchiveComment
			End Get
		#tag EndGetter
		ArchiveComment As String
	#tag EndComputedProperty

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
			  Return mIndex
			End Get
		#tag EndGetter
		CurrentIndex As Integer
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

	#tag Property, Flags = &h21
		Private mArchiveComment As String
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
		Private mForced As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mIndex As Integer = -1
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mIsEmpty As Boolean
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mStream As BinaryStream
	#tag EndProperty

	#tag Property, Flags = &h0
		ValidateChecksums As Boolean = True
	#tag EndProperty


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
		#tag ViewProperty
			Name="ValidateChecksums"
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass