#tag Class
Protected Class ZipReader
Inherits ZipEngine
	#tag Method, Flags = &h0
		Sub Constructor(ZipStream As BinaryStream)
		  Super.Constructor(ZipStream)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function FindDirectoryFooter(ByRef Footer As ZipDirectoryFooter, ByRef IsEmpty As Boolean, ByRef ArchComment As String) As Boolean
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
		  
		  If Not ReadDirectoryFooter(Footer) Then Return False
		  ArchComment = mStream.Read(Footer.CommentLength)
		  IsEmpty = (mStream.Length = MIN_ARCHIVE_SIZE + Footer.CommentLength)
		  Return footer.Offset > MIN_ARCHIVE_SIZE Or IsEmpty
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function FindEntryFooter(ByRef Footer As ZipEntryFooter) As Boolean
		  If Not SeekSignature(mStream, ZIP_ENTRY_FOOTER_SIGNATURE) Then Return False
		  If Not ReadEntryFooter(Footer) Then Return False
		  Return footer.CompressedSize > 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ReadDirectoryFooter(ByRef Footer As ZipDirectoryFooter) As Boolean
		  Footer.Signature = mStream.ReadUInt32
		  Footer.ThisDisk = mStream.ReadUInt16
		  Footer.FirstDisk = mStream.ReadUInt16
		  Footer.ThisRecordCount = mStream.ReadUInt16
		  Footer.TotalRecordCount = mStream.ReadUInt16
		  Footer.DirectorySize = mStream.ReadUInt32
		  Footer.Offset = mStream.ReadUInt32
		  Footer.CommentLength = mStream.ReadUInt16
		  
		  Return Footer.Signature = ZIP_DIRECTORY_FOOTER_SIGNATURE
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ReadDirectoryHeader(ByRef Header As ZipDirectoryHeader) As Boolean
		  Header.Signature = mStream.ReadUInt32
		  Header.Version = mStream.ReadUInt16
		  Header.VersionNeeded = mStream.ReadUInt16
		  Header.Flag = mStream.ReadUInt16
		  Header.Method = mStream.ReadUInt16
		  Header.ModTime = mStream.ReadUInt16
		  Header.ModDate = mStream.ReadUInt16
		  Header.CRC32 = mStream.ReadUInt32
		  Header.CompressedSize = mStream.ReadUInt32
		  Header.UncompressedSize = mStream.ReadUInt32
		  Header.FilenameLength = mStream.ReadUInt16
		  Header.ExtraLength = mStream.ReadUInt16
		  Header.CommentLength = mStream.ReadUInt16
		  Header.DiskNumber = mStream.ReadUInt16
		  Header.InternalAttributes = mStream.ReadUInt16
		  Header.ExternalAttributes = mStream.ReadUInt32
		  Header.Offset = mStream.ReadUInt32
		  
		  Return Header.Signature = ZIP_DIRECTORY_HEADER_SIGNATURE
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ReadEntry(Destination As Writeable) As Boolean
		  If Destination = Nil Or mCurrentEntry.CompressedSize = 0 Then
		    ' skip the current item
		    mStream.Position = mStream.Position + mCurrentEntry.CompressedSize
		    Return True
		  End If
		  
		  Dim zipstream As Readable
		  Select Case mCurrentEntry.Method
		  Case Z_DEFLATED
		    If mZipStream = Nil Then
		      mZipStream = ZStream.Open(mStream, RAW_ENCODING)
		      mZipStream.BufferedReading = False
		    Else
		      mZipStream.Reset()
		    End If
		    zipstream = mZipStream
		  Case 0 ' store
		    zipstream = mStream
		  Else
		    mLastError = ERR_UNSUPPORTED_COMPRESSION
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
		      If ValidateChecksums Then CRC = CRC32(data, crc, data.Size)
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

	#tag Method, Flags = &h21
		Private Function ReadEntryFooter(ByRef Footer As ZipEntryFooter) As Boolean
		  Footer.Signature = mStream.ReadUInt32
		  Footer.CRC32 = mStream.ReadUInt32
		  Footer.CompressedSize = mStream.ReadUInt32
		  Footer.UncompressedSize = mStream.ReadUInt32
		  
		  Return Footer.Signature = ZIP_ENTRY_FOOTER_SIGNATURE
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ReadEntryHeader(ByRef Header As ZipEntryHeader) As Boolean
		  Header.Signature = mStream.ReadUInt32
		  Header.Version = mStream.ReadUInt16
		  Header.Flag = mStream.ReadUInt16
		  Header.Method = mStream.ReadUInt16
		  Header.ModTime = mStream.ReadUInt16
		  Header.ModDate = mStream.ReadUInt16
		  Header.CRC32 = mStream.ReadUInt32
		  Header.CompressedSize = mStream.ReadUInt32
		  Header.UncompressedSize = mStream.ReadUInt32
		  Header.FilenameLength = mStream.ReadUInt16
		  Header.ExtraLength = mStream.ReadUInt16
		  
		  Return Header.Signature = ZIP_ENTRY_HEADER_SIGNATURE
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ReadHeader() As Boolean
		  ' read the next entry header
		  Dim doitanyway As Boolean = mForced And (mStream.Length - mStream.Position >= MIN_ARCHIVE_SIZE)
		  If mStream.Position >= mDirectoryFooter.Offset And Not doitanyway Then
		    mLastError = ERR_END_ARCHIVE
		    Return False
		  End If
		  
		  mIndex = mIndex + 1
		  If Not ReadEntryHeader(mCurrentEntry) Then
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
		    If Not FindEntryFooter(footer) Then
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
	#tag EndViewBehavior
End Class
#tag EndClass
