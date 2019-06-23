#tag Class
Protected Class ZipWriter
	#tag Method, Flags = &h1
		Protected Sub Append(Path As String, Data As Variant, Length As UInt32, ModifyDate As Date = Nil)
		  Path = ConvertEncoding(Path, Encodings.UTF8)
		  If Path.Len > MAX_PATH_SIZE Then Raise New ZipException(ERR_PATH_TOO_LONG)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, True)
		  If d = Nil Then Raise New ZipException(ERR_INVALID_NAME)
		  d.Value(META_STREAM) = Data
		  d.Value(META_LENGTH) = Length
		  If ModifyDate = Nil Then ModifyDate = New Date
		  d.Value(META_MODTIME) = ModifyDate
		  If d.Value(META_DIR) = True Or Length <= 8 Then
		    d.Value(META_LEVEL) = 0
		    d.Value(META_METHOD) = 0
		  Else
		    d.Value(META_LEVEL) = CompressionLevel
		    d.Value(META_METHOD) = CompressionMethod
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AppendDirectory(Entry As FolderItem, RelativeRoot As FolderItem = Nil)
		  ' Adds the directory represented by the Entry parameter to the archive.
		  ' If RelativeRoot is specified then the entry and all subdirectories and
		  ' files within it will be stored as a sub directory (named as Entry.Name)
		  ' of the archive root. If RelativeRoot is not specified then all 
		  ' subdirectories and files within the Entry directory are added to the
		  ' archive root rather than in a subdirectory.
		  
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
		  ' Adds the file represented by the Entry parameter to the archive.
		  ' If RelativeRoot is specified then the entry will be stored using
		  ' the relative path; if the Entry is not contained within RelativeRoot
		  ' then the file is added to the root of the archive. Returns a path
		  ' which can be used with the SetEntry* methods to modify the entry.
		  
		  If Entry.Length > MAX_FILE_SIZE Then Raise New ZipException(ERR_TOO_LARGE)
		  Dim path As String = GetRelativePath(RelativeRoot, Entry)
		  If Entry.Directory Then path = path + "/"
		  Append(path, Entry, Entry.Length, Entry.ModificationDate)
		  Return path
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AppendEntry(Path As String, Data As MemoryBlock, ModifyDate As Date = Nil)
		  ' Adds the raw file data represented by the Data parameter to the archive using
		  ' the specifed Path (or filename). The Path is relative to the root of the archive
		  ' and is delimited by the "/" character. e.g. "dir1/dir2/file.txt". File names without
		  ' a path are placed in the root of the archive.
		  ' If the ModifyDate parameter is not specified then the current date and time are used.
		  
		  Path = ConvertEncoding(Path, Encodings.UTF8)
		  If Path.Len > MAX_PATH_SIZE Then Raise New ZipException(ERR_PATH_TOO_LONG)
		  Dim bs As New BinaryStream(Data)
		  AppendEntry(Path, bs, bs.Length, ModifyDate)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, True)
		  If d = Nil Then Raise New ZipException(ERR_INVALID_NAME)
		  d.Value(META_MEMORY) = Data
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AppendEntry(Path As String, Data As Readable, Length As UInt32, ModifyDate As Date = Nil)
		  ' Adds the raw file data represented by the Data parameter to the archive using
		  ' the specifed Path (or filename). The Path is relative to the root of the archive
		  ' and is delimited by the "/" character. e.g. "dir1/dir2/file.txt". File names without
		  ' a path are placed in the root of the archive.
		  ' The Length parameter specifies how many bytes long the Data is supposed to be. Be aware
		  ' that this value is used only to fill in the archive header--it does not control how
		  ' many bytes will be read from the Data stream. If the Length parameter is wrong then
		  ' archive readers will report the wrong compression ratio and possibly other side effects
		  ' will ensue.
		  ' If the ModifyDate parameter is not specified then the current date and time are used.
		  
		  Append(Path, Data, Length, ModifyDate)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Commit(WriteTo As BinaryStream)
		  ' Writes the zip archive to a file or memory stream.
		  
		  WriteTo.LittleEndian = True
		  Dim paths(), comments() As String
		  Dim lengths(), levels(), methods() As UInt32
		  Dim sources() As Variant
		  Dim modtimes() As Date
		  Dim extras() As MemoryBlock
		  Dim dirstatus() As Boolean
		  CollapseTree(mEntries, paths, lengths, modtimes, sources, comments, extras, dirstatus, levels, methods)
		  
		  Dim directory() As ZipDirectoryHeader
		  
		  Dim c As Integer = UBound(paths)
		  If c >= 65535 And ArchiveComment = "" Then ArchiveComment = "Warning: This archive contains more than 65,535 entries."
		  For i As Integer = 0 To c
		    Dim path As String = paths(i)
		    Dim source As Readable
		    Dim closeable As Boolean
		    Select Case sources(i)
		    Case IsA Readable
		      source = sources(i)
		    Case IsA FolderItem
		      Dim f As FolderItem = sources(i)
		      If Not f.Directory Then
		        source = BinaryStream.Open(f)
		        closeable = True
		      End If
		    End Select
		    path = ConvertEncoding(path, Encodings.UTF8)
		    If dirstatus(i) And Right(path, 1) <> "/" Then path = path + "/"
		    Dim dirheader As ZipDirectoryHeader
		    WriteEntryHeader(WriteTo, path, lengths(i), source, modtimes(i), dirheader, extras(i), levels(i), methods(i))
		    directory.Append(dirheader)
		    If closeable Then
		      BinaryStream(source).Close
		    ElseIf source IsA BinaryStream Then
		      BinaryStream(source).Position = 0 ' be kind, rewind
		    End If
		  Next
		  
		  WriteDirectory(WriteTo, directory, paths, comments, extras, ArchiveComment)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Commit(WriteTo As FolderItem, Overwrite As Boolean = False)
		  ' Writes the zip archive to the file specified by WriteTo. 
		  ' If Overwrite is True then WriteTo will be overwritten if it exists.
		  
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
		    CompressionMethod = METHOD_DEFLATED
		  #ElseIf USE_BZIP2 Then
		    CompressionLevel = BZip2.BZ_DEFAULT_COMPRESSION
		    CompressionMethod = METHOD_BZIP2
		  #Else
		    CompressionLevel = 0
		    CompressionMethod = 0
		  #EndIf
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DeleteEntry(Path As String)
		  ' Removes the archive entry specified by the Path.
		  ' If the entry represents a directory then all entries
		  ' within that directory are removed as well.
		  ' If Path is "/" then *all* entries are removed.
		  
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  Dim n As String = d.Lookup(META_PATH, "$INVALID")
		  Select Case n
		  Case "$INVALID"
		    ' not found
		  Case "$ROOT"
		    ' delete all
		    Dim nms() As String
		    For Each name As String In d.Keys
		      If Left(name, 1) <> "$" Then nms.Append(name)
		    Next
		    For Each name AS String In nms
		      d.Remove(name)
		    Next
		  Else
		    Dim w As WeakRef = d.Lookup(META_PARENT, Nil)
		    If w.Value IsA Dictionary Then
		      Dim p As Dictionary = Dictionary(w.Value)
		      p.Remove(n)
		    End If
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEntryComment(Path As String, Comment As String)
		  ' Sets the comment for the entry. Set it to the empty string
		  ' to remove a previous comment.
		  
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  d.Value(META_COMMENT) = ConvertEncoding(Comment, Encodings.UTF8)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEntryCompressionLevel(Path As String, CompressionLevel As Integer)
		  ' Sets the compression level for the entry, overriding ZipWriter.CompressionLevel.
		  ' CompressionLevel must be between 0 and 9, inclusive.
		  
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
		  ' Sets the compression method for the entry, overriding ZipWriter.CompressionMethod.
		  ' Possible compression methods are:
		  '   * METHOD_NONE (0) (store)
		  '   * METHOD_DEFLATED (8) (zlib required)
		  '   * METHOD_BZIP2 (12) (bzip2 required; https://github.com/charonn0/RB-bzip2 )
		  '
		  ' Directories and zero-length files always use METHOD_NONE.
		  '
		  ' See also PKZip.GetCompressor if you want to add another compression method.
		  
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  Select Case CompressionMethod
		  Case METHOD_NONE
		    d.Value(META_METHOD) = CompressionMethod
		    
		  Case METHOD_DEFLATED
		    #If USE_ZLIB Then
		      d.Value(META_METHOD) = CompressionMethod
		    #Else
		      Raise New ZipException(ERR_UNSUPPORTED_COMPRESSION)
		    #endif
		    
		  Case METHOD_BZIP2
		    #If USE_BZIP2 Then
		      d.Value(META_METHOD) = CompressionMethod
		    #Else
		      Raise New ZipException(ERR_UNSUPPORTED_COMPRESSION)
		    #endif
		    
		  Else
		    Raise New ZipException(ERR_UNSUPPORTED_COMPRESSION)
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEntryExtraData(Path As String, Extra As MemoryBlock)
		  ' Sets the platform-specific "extra" data for the entry.
		  ' Set it to Nil to remove the previous Extra data.
		  
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  d.Value(META_EXTRA) = Extra
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEntryModificationDate(Path As String, ModDate As Date)
		  ' Sets the "last modified" date for the entry.
		  ' Set it to Nil to use the current date and time.
		  
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  If ModDate = Nil Then ModDate = New Date
		  d.Value(META_MODTIME) = ModDate
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Sub WriteDirectory(Stream As BinaryStream, Headers() As ZipDirectoryHeader, Names() As String, Comments() As String, Extras() As MemoryBlock, ArchiveComment As String)
		  ArchiveComment = ConvertEncoding(ArchiveComment, Encodings.UTF8)
		  If ArchiveComment.LenB > MAX_COMMENT_SIZE Then Raise New ZipException(ERR_TOO_LARGE)
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
		Private Shared Sub WriteEntryFooter(Stream As BinaryStream, CRC As UInt32, CompressedSize As UInt32, UncompressedSize As UInt32)
		  Stream.WriteUInt32(ZIP_ENTRY_FOOTER_SIGNATURE)
		  Stream.WriteUInt32(CRC)
		  Stream.WriteUInt32(CompressedSize)
		  Stream.WriteUInt32(UncompressedSize)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Sub WriteEntryHeader(Stream As BinaryStream, Name As String, Length As UInt32, Source As Readable, ModDate As Date, ByRef DirectoryHeader As ZipDirectoryHeader, ExtraData As MemoryBlock, Level As UInt32, Method As UInt32)
		  If Not USE_ZLIB And Not USE_BZIP2 Then Level = 0
		  If Length = 0 Or Level = 0 Then method = 0
		  
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
		  #If Not OUTPUT_SEEKABLE Then
		    If Length > 0 Then DirectoryHeader.Flag = DirectoryHeader.Flag Or FLAG_DESCRIPTOR
		  #endif
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
		  ElseIf ExtraData.Size > MAX_EXTRA_SIZE Then
		    Raise New ZipException(ERR_TOO_LARGE)
		  End If
		  DirectoryHeader.ExtraLength = ExtraData.Size
		  Stream.WriteUInt16(ExtraData.Size) ' extra length
		  
		  Stream.Write(Name) ' name
		  Stream.Write(ExtraData) ' extra
		  
		  dataoff = Stream.Position
		  Dim crc As UInt32
		  If Source <> Nil And Length > 0 Then
		    Dim z As Writeable = GetCompressor(Method, Stream, Level)
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
		  If Length > 0 Then
		    Dim endoff As UInt64 = Stream.Position
		    Dim compsz As UInt32 = endoff - dataoff
		    DirectoryHeader.CompressedSize = compsz
		    DirectoryHeader.CRC32 = crc
		    #If OUTPUT_SEEKABLE Then
		      Stream.Position = compszoff
		      Stream.WriteUInt32(compsz)
		      Stream.Position = crcoff
		      Stream.WriteUInt32(crc)
		      Stream.Position = endoff
		    #Else
		      WriteEntryFooter(Stream, crc, compsz, Length)
		    #EndIf
		  End If
		End Sub
	#tag EndMethod


	#tag Note, Name = Limitations
		The zip file format limits archives to 4GB, both overall and for individual compressed files. 
		File names (including the path), file comments, and file extra data fields are limited to 65535
		bytes each.
		
		The number of files in a single archive is technically limited to 65535, however this class does
		not enforce the limit. Most zip readers (including the ZipReader class) ignore this limit and
		can handle archives with any number of files.
		
	#tag EndNote


	#tag Property, Flags = &h0
		ArchiveComment As String
	#tag EndProperty

	#tag Property, Flags = &h0
		CompressionLevel As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		CompressionMethod As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mEntries As Dictionary
	#tag EndProperty


	#tag Constant, Name = OUTPUT_SEEKABLE, Type = Boolean, Dynamic = False, Default = \"True", Scope = Protected
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="ArchiveComment"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="CompressionLevel"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="CompressionMethod"
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
