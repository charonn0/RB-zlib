#tag Class
Protected Class ZipWriter
	#tag Method, Flags = &h0
		Sub AppendDirectory(Entry As FolderItem, RelativeRoot As FolderItem = Nil)
		  If Not Entry.Directory Then 
		    Call AppendEntry(Entry, RelativeRoot)
		    Return
		  End If
		  
		  If RelativeRoot = Nil Then RelativeRoot = Entry
		  Dim entries() As FolderItem
		  GetChildren(Entry, entries)
		  Dim c As Integer = UBound(entries)
		  For i As Integer = 0 To c
		    Call AppendEntry(entries(i), RelativeRoot)
		  Next
		End Sub
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
		Sub AppendEntry(Path As String, Data As MemoryBlock, ModifyDate As Date = Nil)
		  Dim bs As New BinaryStream(Data)
		  AppendEntry(Path, bs, bs.Length, ModifyDate)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, True)
		  If d = Nil Then Raise New ZipException(ERR_INVALID_NAME)
		  d.Value(META_MEMORY) = Data
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AppendEntry(Path As String, Data As Readable, Length As UInt32, ModifyDate As Date = Nil)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, True)
		  If d = Nil Then Raise New ZipException(ERR_INVALID_NAME)
		  d.Value(META_STREAM) = Data
		  d.Value(META_LENGTH) = Length
		  If ModifyDate = Nil Then ModifyDate = New Date
		  d.Value(META_MODTIME) = ModifyDate
		  If d.Value(META_DIR) = True Then
		    d.Value(META_LEVEL) = 0
		  Else
		    d.Value(META_LEVEL) = CompressionLevel
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Commit(WriteTo As BinaryStream)
		  WriteTo.LittleEndian = True
		  Dim paths(), comments() As String
		  Dim lengths(), levels(), methods() As UInt32
		  Dim sources() As Readable
		  Dim modtimes() As Date
		  Dim extras() As MemoryBlock
		  Dim dirstatus() As Boolean
		  CollapseTree(mEntries, paths, lengths, modtimes, sources, comments, extras, dirstatus, levels, methods)
		  
		  Dim directory() As ZipDirectoryHeader
		  
		  Dim c As Integer = UBound(paths)
		  For i As Integer = 0 To c
		    Dim path As String = paths(i)
		    Dim source As Readable = sources(i)
		    path = ConvertEncoding(path, Encodings.UTF8)
		    If dirstatus(i) And Right(path, 1) <> "/" Then path = path + "/"
		    Dim dirheader As ZipDirectoryHeader
		    WriteEntryHeader(WriteTo, path, lengths(i), source, modtimes(i), dirheader, extras(i), levels(i), methods(i))
		    directory.Append(dirheader)
		    If source IsA BinaryStream Then BinaryStream(source).Position = 0 ' be kind, rewind
		  Next
		  
		  WriteDirectory(WriteTo, directory, paths, comments, extras, ArchiveComment)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Commit(WriteTo As FolderItem, Overwrite As Boolean = False)
		  If WriteTo = Nil Or WriteTo.Directory Then Return
		  Dim bs As BinaryStream = BinaryStream.Create(WriteTo, Overwrite)
		  Commit(bs)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  mEntries = New Dictionary(META_PATH:"$ROOT", META_PARENT:Nil, META_DIR:True)
		  #If USE_ZLIB Then
		    CompressionLevel = zlib.Z_DEFAULT_COMPRESSION
		  #Else
		    CompressionLevel = 0
		  #EndIf
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DeleteEntry(Path As String)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  Dim n As String = d.Lookup(META_PATH, "$INVALID")
		  If n = "$INVALID" Then Return
		  Dim w As WeakRef = d.Lookup(META_PARENT, Nil)
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
		 Shared Function Open(ZipStream As BinaryStream) As PKZip.ZipWriter
		  ZipStream.LittleEndian = True
		  If Not FindDirectoryFooter(ZipStream) Then Return Nil
		  Dim eod As UInt64 = ZipStream.Position
		  Dim footer As ZipDirectoryFooter
		  If Not ReadDirectoryFooter(ZipStream, footer) Then Return Nil
		  ZipStream.Position = footer.Offset
		  Dim entries As New Dictionary(META_PATH:"$ROOT", META_PARENT:Nil, META_DIR:True)
		  entries.Value(META_STREAM) = ZipStream
		  Do Until ZipStream.Position >= eod
		    Dim header As ZipDirectoryHeader
		    If Not ReadDirectoryHeader(ZipStream, header) Then Exit Do
		    Dim name As String = ZipStream.Read(header.FilenameLength)
		    Dim extra As MemoryBlock = ZipStream.Read(header.ExtraLength)
		    Dim comment As MemoryBlock = ZipStream.Read(header.CommentLength)
		    Dim d As Dictionary = TraverseTree(entries, name, True)
		    If d = Nil Then Continue
		    d.Value(META_COMMENT) = comment
		    d.Value(META_EXTRA) = extra
		    d.Value(META_LENGTH) = header.CompressedSize
		    d.Value(META_MODTIME) = ConvertDate(header.ModDate, header.ModTime)
		    Dim offset As UInt64 = header.Offset + extra.Size + name.LenB + ZIP_ENTRY_HEADER_SIZE
		    d.Value(META_OFFSET) = offset
		    d.Value(META_METHOD) = header.Method
		    d.Value(META_LEVEL) = 0
		    If header.CompressedSize > 0 Then
		      Dim m As New MappedStream(ZipStream, offset, header.CompressedSize)
		      m.Tag = header.CRC32
		      d.Value(META_STREAM) = m
		    End If
		  Loop
		  
		  Dim z As New ZipWriter
		  z.mEntries = entries
		  Return z
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEntryComment(Path As String, Comment As String)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  d.Value(META_COMMENT) = ConvertEncoding(Comment, Encodings.UTF8)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEntryCompressionLevel(Path As String, CompressionLevel As Integer)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  If d.HasKey(META_LEVEL) Then d.Remove(META_LEVEL)
		  If CompressionLevel >= 0 And CompressionLevel <= 9 Then
		    d.Value(META_LEVEL) = CompressionLevel
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEntryCompressionMethod(Path As String, CompressionMethod As Integer)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  If d.HasKey(META_METHOD) Then d.Remove(META_METHOD)
		  Select Case CompressionMethod
		  Case METHOD_DEFLATED
		    #If USE_ZLIB Then
		      d.Value(META_METHOD) = CompressionMethod
		    #endif
		  Case 0
		    d.Value(META_METHOD) = CompressionMethod
		  Else
		    Raise New ZipException(ERR_UNSUPPORTED_COMPRESSION)
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEntryExtraData(Path As String, Extra As MemoryBlock)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  d.Value(META_EXTRA) = Extra
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEntryModificationDate(Path As String, ModDate As Date)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  d.Value(META_MODTIME) = ModDate
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
		Private Shared Sub WriteEntryHeader(Stream As BinaryStream, Name As String, Length As UInt32, Source As Readable, ModDate As Date, ByRef DirectoryHeader As ZipDirectoryHeader, ExtraData As MemoryBlock, Level As UInt32, Method As UInt32)
		  If Not USE_ZLIB Then Level = 0
		  If Length = 0 Or Level = 0 And Not Source IsA MappedStream Then method = 0
		  
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
		  
		  Stream.WriteUInt16(method) ' method=none
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
		  If Source <> Nil And Length > 0 Then
		    Dim z As Writeable = GetCompressor(Method, Stream, Level)
		    If z = Nil Then Raise New ZipException(ERR_UNSUPPORTED_COMPRESSION)
		    If Source IsA MappedStream Then crc = MappedStream(Source).Tag
		    Do Until Source.EOF
		      Dim data As MemoryBlock = Source.Read(CHUNK_SIZE)
		      If Not Source IsA MappedStream Then crc = PKZip.CRC32(data, crc)
		      z.Write(data)
		    Loop
		    #If USE_ZLIB Then
		      If z IsA zlib.ZStream Then zlib.ZStream(z).Close
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
		CompressionLevel As Integer
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
