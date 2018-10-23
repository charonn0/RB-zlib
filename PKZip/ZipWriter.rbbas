#tag Class
Protected Class ZipWriter
	#tag Method, Flags = &h0
		Function AppendDirectory(Entry As FolderItem, Recursive As Boolean = True) As String
		  If Not Entry.Directory Or Not Recursive Then Return AppendEntry(Entry)
		  Dim entries() As FolderItem
		  GetChildren(Entry, entries)
		  Dim c As Integer = UBound(entries)
		  For i As Integer = 0 To c
		    Call AppendEntry(entries(i), entry)
		  Next
		  Return Entry.Name + "/"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function AppendEntry(Entry As FolderItem, Optional RelativeRoot As FolderItem) As String
		  If Entry.Length > &hFFFFFFFF Then Raise New ZipException(ERR_TOO_LARGE)
		  Dim path As String = GetRelativePath(RelativeRoot, Entry)
		  Dim bs As BinaryStream
		  If Not Entry.Directory Then
		    bs = BinaryStream.Open(Entry)
		  Else
		    path = path + "/"
		  End If
		  AppendEntry(path, bs, Entry.Length, Entry.ModificationDate)
		  Return path
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AppendEntry(Path As String, Data As Readable, Length As UInt32, ModifyDate As Date = Nil)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, True)
		  If d = Nil Then Raise New ZipException(ERR_INVALID_NAME)
		  d.Value("$r") = Data
		  d.Value("$s") = Length
		  If ModifyDate = Nil Then ModifyDate = New Date
		  d.Value("$t") = ModifyDate
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Commit(WriteTo As BinaryStream, CompressionLevel As Integer = -1)
		  WriteTo.LittleEndian = True
		  Dim paths(), comments() As String
		  Dim lengths() As UInt32
		  Dim sources() As Readable
		  Dim modtimes() As Date
		  Dim extras() As MemoryBlock
		  Dim dirstatus() As Boolean
		  CollapseTree(mEntries, paths, lengths, modtimes, sources, comments, extras, dirstatus)
		  
		  Dim directory() As ZipDirectoryHeader
		  
		  Dim c As Integer = UBound(paths)
		  For i As Integer = 0 To c
		    Dim length As UInt32 = lengths(i)
		    Dim path As String = paths(i)
		    path = ConvertEncoding(path, Encodings.UTF8)
		    Dim source As Readable = sources(i)
		    Dim modtime As Date = modtimes(i)
		    If dirstatus(i) And Right(path, 1) <> "/" Then path = path + "/"
		    Dim dirheader As ZipDirectoryHeader
		    Dim extra As MemoryBlock = extras(i)
		    WriteEntryHeader(WriteTo, path, length, source, modtime, CompressionLevel, dirheader, extra, CompressionMethod)
		    directory.Append(dirheader)
		    If source IsA BinaryStream Then BinaryStream(source).Position = 0 ' be kind, rewind
		  Next
		  
		  WriteDirectory(WriteTo, directory, paths, comments, extras, ArchiveComment)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Commit(WriteTo As FolderItem, Overwrite As Boolean = False, CompressionLevel As Integer = - 1)
		  If WriteTo = Nil Or WriteTo.Directory Then Return
		  Dim bs As BinaryStream = BinaryStream.Create(WriteTo, Overwrite)
		  Commit(bs, CompressionLevel)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  mEntries = New Dictionary("$n":"$ROOT", "$p":Nil, "$d":True)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DeleteEntry(Path As String)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  Dim n As String = d.Lookup("$n", "$INVALID")
		  If n = "$INVALID" Then Return
		  Dim w As WeakRef = d.Lookup("$p", Nil)
		  If w.Value IsA Dictionary Then
		    Dim p As Dictionary = Dictionary(w.Value)
		    p.Remove(n)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEntryComment(Path As String, Comment As String)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  d.Value("$c") = ConvertEncoding(Comment, Encodings.UTF8)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEntryExtraData(Path As String, Extra As MemoryBlock)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  d.Value("$e") = Extra
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEntryModificationDate(Path As String, ModDate As Date)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  d.Value("$t") = ModDate
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Sub WriteDirectory(Stream As BinaryStream, Headers() As ZipDirectoryHeader, Names() As String, Comments() As String, Extras() As MemoryBlock, ArchiveComment As String)
		  ArchiveComment = ConvertEncoding(ArchiveComment, Encodings.UTF8)
		  Dim c As Integer = UBound(Headers)
		  Dim footer As ZipDirectoryFooter
		  footer.Signature = ZIP_DIRECTORY_FOOTER_SIGNATURE
		  footer.CommentLength = ArchiveComment.LenB
		  footer.ThisRecordCount = c + 1
		  footer.TotalRecordCount = c + 1
		  footer.Offset = stream.Position
		  
		  For i As Integer = 0 To c
		    WriteDirectoryHeader(Stream, Headers(i), Names(i), Comments(i), Extras(i))
		  Next
		  
		  footer.DirectorySize = Stream.Position - footer.Offset
		  WriteDirectoryFooter(Stream, footer)
		  Stream.Write(ArchiveComment)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Sub WriteDirectoryFooter(Stream As BinaryStream, Footer As ZipDirectoryFooter)
		  Stream.WriteUInt32(Footer.Signature)
		  Stream.WriteUInt16(Footer.ThisDisk)
		  Stream.WriteUInt16(Footer.FirstDisk)
		  Stream.WriteUInt16(Footer.ThisRecordCount)
		  Stream.WriteUInt16(Footer.TotalRecordCount)
		  Stream.WriteUInt32(Footer.DirectorySize)
		  Stream.WriteUInt32(Footer.Offset)
		  Stream.WriteUInt16(Footer.CommentLength)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Sub WriteDirectoryHeader(Stream As BinaryStream, Header As ZipDirectoryHeader, Name As String, Comment As String, Extra As MemoryBlock)
		  If Comment.LenB > MAX_COMMENT_SIZE Then Comment = LeftB(Comment, MAX_COMMENT_SIZE)
		  If Name.LenB > MAX_NAME_SIZE Then Raise New ZipException(ERR_INVALID_NAME)
		  If Extra <> Nil And Extra.Size > MAX_EXTRA_SIZE Then Extra.Size = MAX_EXTRA_SIZE
		  
		  Header.CommentLength = Comment.LenB
		  Header.FilenameLength = Name.LenB
		  If Extra <> Nil Then Header.ExtraLength = Extra.Size Else Header.ExtraLength = 0
		  
		  Stream.WriteUInt32(Header.Signature)
		  Stream.WriteUInt16(Header.Version)
		  Stream.WriteUInt16(Header.VersionNeeded)
		  Stream.WriteUInt16(Header.Flag)
		  Stream.WriteUInt16(Header.Method)
		  Stream.WriteUInt16(Header.ModTime)
		  Stream.WriteUInt16(Header.ModDate)
		  Stream.WriteUInt32(Header.CRC32)
		  Stream.WriteUInt32(Header.CompressedSize)
		  Stream.WriteUInt32(Header.UncompressedSize)
		  Stream.WriteUInt16(Header.FilenameLength)
		  Stream.WriteUInt16(Header.ExtraLength)
		  Stream.WriteUInt16(Header.CommentLength)
		  Stream.WriteUInt16(Header.DiskNumber)
		  Stream.WriteUInt16(Header.InternalAttributes)
		  Stream.WriteUInt32(Header.ExternalAttributes)
		  Stream.WriteUInt32(Header.Offset)
		  Stream.Write(Name)
		  If Extra <> Nil Then Stream.Write(Extra)
		  Stream.Write(Comment)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Sub WriteEntryHeader(Stream As BinaryStream, Name As String, Length As UInt32, Source As Readable, ModDate As Date, CompressionLevel As Integer, ByRef DirectoryHeader As ZipDirectoryHeader, ExtraData As MemoryBlock, Method As UInt32)
		  If Not USE_ZLIB And Not USE_BZIP2 Then CompressionLevel = 0
		  If Length = 0 Or CompressionLevel = 0 Then method = 0
		  
		  DirectoryHeader.Offset = Stream.Position
		  Dim crcoff, compszoff, dataoff As UInt64
		  Stream.WriteUInt32(ZIP_ENTRY_HEADER_SIGNATURE)
		  DirectoryHeader.Signature = ZIP_DIRECTORY_HEADER_SIGNATURE
		  
		  Stream.WriteUInt16(20) ' version
		  DirectoryHeader.Version = 20
		  DirectoryHeader.VersionNeeded = 10
		  
		  If Name.Encoding = Encodings.UTF8 Then
		    DirectoryHeader.Flag = FLAG_NAME_ENCODING
		  End If
		  Stream.WriteUInt16(DirectoryHeader.Flag) ' flag
		  
		  Stream.WriteUInt16(method) ' method
		  DirectoryHeader.Method = method
		  Dim modtim As Pair = ConvertDate(ModDate)
		  Stream.WriteUInt16(modtim.Right) ' modtime
		  Stream.WriteUInt16(modtim.Left) ' moddate
		  DirectoryHeader.ModDate = modtim.Left
		  DirectoryHeader.ModTime = modtim.Right
		  
		  crcoff = Stream.Position
		  Stream.WriteUInt32(0) ' crc32; to be filled later
		  
		  compszoff = Stream.Position
		  Stream.WriteUInt32(0) ' compressed size; to be filled later
		  
		  DirectoryHeader.UncompressedSize = Length
		  Stream.WriteUInt32(Length) ' uncompressed size
		  
		  DirectoryHeader.FilenameLength = Name.LenB
		  Stream.WriteUInt16(Name.LenB) ' name length
		  
		  If ExtraData = Nil Then
		    ExtraData = ""
		  Else
		    If ExtraData.Size > &hFFFF Then Raise New ZipException(ERR_TOO_LARGE)
		  End If
		  DirectoryHeader.ExtraLength = ExtraData.Size
		  Stream.WriteUInt16(ExtraData.Size) ' extra length
		  
		  Stream.Write(Name)
		  Stream.Write(ExtraData) ' extra
		  
		  dataoff = Stream.Position
		  Dim crc As UInt32
		  Dim z As Writeable
		  If Source <> Nil And Length > 0 Then
		    z = GetCompressor(method, Stream, CompressionLevel)
		    If z = Nil Then Raise New ZipException(ERR_UNSUPPORTED_COMPRESSION)
		    Do Until Source.EOF
		      Dim data As MemoryBlock = Source.Read(CHUNK_SIZE)
		      crc = PKZip.CRC32(data, crc)
		      z.Write(data)
		    Loop
		    #If USE_ZLIB Then
		      If z IsA zlib.ZStream Then zlib.ZStream(z).Close
		    #EndIf
		    #If USE_BZIP2 Then
		      If z IsA BZip2.BZ2Stream Then BZip2.BZ2Stream(z).Close
		    #endif
		  End If
		  Dim endoff As UInt64 = Stream.Position
		  Dim compsz As UInt32 = endoff - dataoff
		  Stream.Position = compszoff
		  Stream.WriteUInt32(compsz)
		  DirectoryHeader.CompressedSize = compsz
		  Stream.Position = crcoff
		  Stream.WriteUInt32(crc)
		  DirectoryHeader.CRC32 = crc
		  Stream.Position = endoff
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h0
		ArchiveComment As String
	#tag EndProperty

	#tag Property, Flags = &h0
		CompressionMethod As UInt32 = PKZip.METHOD_DEFLATED
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mEntries As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mLastError As Integer
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
