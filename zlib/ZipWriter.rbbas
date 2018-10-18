#tag Class
Protected Class ZipWriter
Inherits ZipEngine
	#tag Method, Flags = &h0
		Sub Constructor(ZipStream As BinaryStream)
		  Super.Constructor(ZipStream)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub WriteDirectory(mStream As BinaryStream, Directory As MemoryBlock, Count As UInt32, ArchiveComment As String)
		  ArchiveComment = ConvertEncoding(ArchiveComment, Encodings.UTF8)
		  Dim footer As ZipDirectoryFooter
		  footer.Signature = ZIP_DIRECTORY_FOOTER_SIGNATURE
		  footer.CommentLength = ArchiveComment.LenB
		  footer.ThisRecordCount = Count
		  footer.TotalRecordCount = Count
		  footer.Offset = mStream.Position
		  mStream.Write(Directory)
		  
		  footer.DirectorySize = mStream.Position - footer.Offset
		  WriteDirectoryFooter(footer)
		  mStream.Write(ArchiveComment)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub WriteDirectoryFooter(Footer As ZipDirectoryFooter)
		  mStream.WriteUInt32(Footer.Signature)
		  mStream.WriteUInt16(Footer.ThisDisk)
		  mStream.WriteUInt16(Footer.FirstDisk)
		  mStream.WriteUInt16(Footer.ThisRecordCount)
		  mStream.WriteUInt16(Footer.TotalRecordCount)
		  mStream.WriteUInt32(Footer.DirectorySize)
		  mStream.WriteUInt32(Footer.Offset)
		  mStream.WriteUInt16(Footer.CommentLength)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub WriteDirectoryHeader(Header As ZipDirectoryHeader, Name As String, Comment As String, Extra As MemoryBlock)
		  If Comment.LenB > MAX_COMMENT_SIZE Then Comment = LeftB(Comment, MAX_COMMENT_SIZE)
		  If Name.LenB > MAX_NAME_SIZE Then Raise New zlibException(ERR_INVALID_NAME)
		  If Extra <> Nil And Extra.Size > MAX_EXTRA_SIZE Then Extra.Size = MAX_EXTRA_SIZE
		  
		  Header.CommentLength = Comment.LenB
		  Header.FilenameLength = Name.LenB
		  If Extra <> Nil Then Header.ExtraLength = Extra.Size Else Header.ExtraLength = 0
		  
		  mStream.WriteUInt32(Header.Signature)
		  mStream.WriteUInt16(Header.Version)
		  mStream.WriteUInt16(Header.VersionNeeded)
		  mStream.WriteUInt16(Header.Flag)
		  mStream.WriteUInt16(Header.Method)
		  mStream.WriteUInt16(Header.ModTime)
		  mStream.WriteUInt16(Header.ModDate)
		  mStream.WriteUInt32(Header.CRC32)
		  mStream.WriteUInt32(Header.CompressedSize)
		  mStream.WriteUInt32(Header.UncompressedSize)
		  mStream.WriteUInt16(Header.FilenameLength)
		  mStream.WriteUInt16(Header.ExtraLength)
		  mStream.WriteUInt16(Header.CommentLength)
		  mStream.WriteUInt16(Header.DiskNumber)
		  mStream.WriteUInt16(Header.InternalAttributes)
		  mStream.WriteUInt32(Header.ExternalAttributes)
		  mStream.WriteUInt32(Header.Offset)
		  mStream.Write(Name)
		  If Extra <> Nil Then mStream.Write(Extra)
		  mStream.Write(Comment)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub WriteEntryHeader(Name As String, Length As UInt32, Source As Readable, ModDate As Date, CompressionLevel As Integer, ByRef DirectoryHeader As ZipDirectoryHeader)
		  DirectoryHeader.Offset = mStream.Position
		  Dim crcoff, compszoff, dataoff As UInt64
		  mStream.WriteUInt32(ZIP_ENTRY_HEADER_SIGNATURE)
		  DirectoryHeader.Signature = ZIP_DIRECTORY_HEADER_SIGNATURE
		  
		  mStream.WriteUInt16(20) ' version
		  DirectoryHeader.Version = 20
		  DirectoryHeader.VersionNeeded = 10
		  
		  If Name.Encoding = Encodings.UTF8 Then
		    DirectoryHeader.Flag = 2048
		  End If
		  mStream.WriteUInt16(DirectoryHeader.Flag) ' flag
		  
		  If Length = 0 Or CompressionLevel = 0 Then
		    mStream.WriteUInt16(0) ' method=none
		    DirectoryHeader.Method = 0
		  Else
		    mStream.WriteUInt16(Z_DEFLATED) ' method=deflate
		    DirectoryHeader.Method = Z_DEFLATED
		  End If
		  Dim modtim As Pair = ConvertDate(ModDate)
		  mStream.WriteUInt16(modtim.Right) ' modtime
		  mStream.WriteUInt16(modtim.Left) ' moddate
		  DirectoryHeader.ModDate = modtim.Left
		  DirectoryHeader.ModTime = modtim.Right
		  
		  crcoff = mStream.Position
		  mStream.WriteUInt32(0) ' crc32; to be filled later
		  
		  compszoff = mStream.Position
		  mStream.WriteUInt32(0) ' compressed size; to be filled later
		  
		  DirectoryHeader.UncompressedSize = Length
		  mStream.WriteUInt32(Length) ' uncompressed size
		  
		  DirectoryHeader.FilenameLength = Name.LenB
		  mStream.WriteUInt16(Name.LenB) ' name length
		  
		  DirectoryHeader.ExtraLength = 0
		  mStream.WriteUInt16(0) ' extra length
		  
		  mStream.Write(name)
		  //mStream.Write("") ' extra
		  
		  dataoff = mStream.Position
		  Dim crc As UInt32
		  If Source <> Nil And Length > 0 Then
		    Dim z As Writeable
		    If CompressionLevel <> 0 Then
		      z = ZStream.Create(mStream, CompressionLevel, Z_DEFAULT_STRATEGY, RAW_ENCODING)
		    Else
		      z = mStream
		    End If
		    Do Until Source.EOF
		      Dim data As MemoryBlock = Source.Read(CHUNK_SIZE)
		      crc = zlib.CRC32(data, crc)
		      z.Write(data)
		    Loop
		    If z IsA ZStream Then ZStream(z).Close
		  End If
		  Dim endoff As UInt64 = mStream.Position
		  Dim compsz As UInt32 = endoff - dataoff
		  mStream.Position = compszoff
		  mStream.WriteUInt32(compsz)
		  DirectoryHeader.CompressedSize = compsz
		  mStream.Position = crcoff
		  mStream.WriteUInt32(crc)
		  DirectoryHeader.CRC32 = crc
		  mStream.Position = endoff
		End Sub
	#tag EndMethod


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
