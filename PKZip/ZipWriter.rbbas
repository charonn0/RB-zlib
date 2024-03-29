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
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.AppendDirectory
		  
		  Dim s As String
		  s = AppendDirectory(Entry, RelativeRoot)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function AppendDirectory(Entry As FolderItem, RelativeRoot As FolderItem = Nil) As String
		  ' Adds the directory represented by the Entry parameter to the archive.
		  ' If RelativeRoot is specified then the entry and all subdirectories and
		  ' files within it will be stored as a sub directory (named as Entry.Name)
		  ' of the archive root. If RelativeRoot is not specified then all 
		  ' subdirectories and files within the Entry directory are added to the
		  ' archive root rather than in a subdirectory.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.AppendDirectory
		  
		  If Not Entry.Directory Then Return AppendEntry(Entry, RelativeRoot)
		  
		  Dim rooted As Boolean
		  If RelativeRoot = Nil Then
		    RelativeRoot = Entry
		    rooted = True
		  End If
		  Dim entries() As FolderItem
		  GetChildren(Entry, entries)
		  Dim c As Integer = UBound(entries)
		  For i As Integer = 0 To c
		    Call AppendEntry(entries(i), RelativeRoot)
		  Next
		  If c > -1 And Not rooted Then Return GetRelativePath(RelativeRoot, Entry)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function AppendEntry(Entry As FolderItem, Optional RelativeRoot As FolderItem) As String
		  ' Adds the file represented by the Entry parameter to the archive. If RelativeRoot is
		  ' specified then the entry will be stored using the relative path; if the Entry is not
		  ' contained within RelativeRoot then the file is added to the root of the archive.
		  ' Returns a path which can be used with the SetEntry* methods to modify the entry.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.AppendEntry
		  
		  If Entry.Length > MAX_FILE_SIZE Then Raise New ZipException(ERR_TOO_LARGE)
		  Dim path As String = GetRelativePath(RelativeRoot, Entry)
		  If Entry.Directory Then path = path + "/"
		  Append(path, Entry, Entry.Length, Entry.ModificationDate)
		  Return path
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AppendEntry(Path As String, Data As MemoryBlock, ModifyDate As Date = Nil)
		  ' Adds the raw file data represented by the Data parameter to the archive using the specifed
		  ' Path (or filename). The Path is relative to the root of the archive and is delimited by the
		  ' "/" character. e.g. "dir1/dir2/file.txt". File names without a path are placed in the root
		  ' of the archive. If the ModifyDate parameter is not specified then the current date and time
		  ' are used.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.AppendEntry
		  
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
		  ' Adds the raw file data represented by the Data parameter to the archive using the specifed
		  ' Path (or filename). The Path is relative to the root of the archive and is delimited by the
		  ' "/" character. e.g. "dir1/dir2/file.txt". File names without a path are placed in the root
		  ' of the archive. The Length parameter specifies how many bytes long the Data is supposed to
		  ' be. Be aware that this value is used only to fill in the archive header--it does not control
		  ' how many bytes will be read from the Data stream. If the Length parameter is wrong then archive
		  ' readers will report the wrong compression ratio and possibly other side effects will ensue.
		  ' If the ModifyDate parameter is not specified then the current date and time are used.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.AppendEntry
		  
		  Append(Path, Data, Length, ModifyDate)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Sub CollapseTree(Root As Dictionary, ByRef Paths() As String, ByRef Lengths() As UInt32, ByRef ModTimes() As Date, ByRef Sources() As Variant, ByRef Comments() As String, ByRef Extras() As MemoryBlock, ByRef DirectoryStatus() As Boolean, ByRef Levels() As UInt32, ByRef Methods() As UInt32)
		  ' This method takes the zip archive modelled by the Root parameter and uses it to populate the other parameters.
		  
		  For Each key As Variant In Root.Keys
		    If Root.Value(key) IsA Dictionary Then
		      Dim item As Dictionary = Root.Value(key)
		      If item.Lookup(META_DIR, False) Then CollapseTree(item, Paths, Lengths, ModTimes, Sources, Comments, Extras, DirectoryStatus, Levels, Methods)
		      Paths.Append(GetTreeParentPath(item))
		      Lengths.Append(item.Lookup(META_LENGTH, 0))
		      ModTimes.Append(item.Value(META_MODTIME))
		      Sources.Append(item.Value(META_STREAM))
		      DirectoryStatus.Append(item.Value(META_DIR))
		      Extras.Append(item.Lookup(META_EXTRA, Nil))
		      Comments.Append(item.Lookup(META_COMMENT, ""))
		      Levels.Append(item.Lookup(META_LEVEL, 6))
		      If USE_ZLIB Then
		        Methods.Append(item.Lookup(META_METHOD, METHOD_DEFLATED))
		      ElseIf USE_BZIP2 Then
		        Methods.Append(item.Lookup(META_METHOD, METHOD_BZIP2))
		      Else
		        Methods.Append(item.Lookup(META_METHOD, METHOD_NONE))
		      End If
		    End If
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Commit(WriteTo As BinaryStream)
		  ' Writes the Zip archive to the WriteTo stream.
		  ' Note: If you passed a Readable object to the AppendEntry() method then you must remember
		  ' to rewind the stream if you intend to call Commit more than once (unless it was a BinaryStream,
		  ' which will be rewound automatically.)
		  ' 
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.Commit
		  
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
		  ' Writes the Zip archive to the file specified by WriteTo. If Overwrite is True then WriteTo
		  ' will be overwritten if it exists. Note: If you passed a Readable object to the AppendEntry()
		  ' method then you must remember to rewind the stream if you intend to call Commit more than
		  ' once (unless it was a BinaryStream, which will be rewound automatically.)
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.Commit
		  
		  If WriteTo = Nil Or WriteTo.Directory Then Return
		  Dim bs As BinaryStream = BinaryStream.Create(WriteTo, Overwrite)
		  Commit(bs)
		  bs.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  ' Constructs the unnamed root directory in the archive's directory model.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.Constructor
		  
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

	#tag Method, Flags = &h0
		Sub DeleteEntry(Path As String)
		  ' Removes the archive entry specified by the Path. If the entry represents a directory then
		  ' all entries within that directory are removed as well. If Path is "/" then *all* entries
		  ' are removed.
		  ' 
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.DeleteEntry
		  
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

	#tag Method, Flags = &h21
		Private Shared Function GetTreeParentPath(Child As Dictionary) As String
		  Dim s() As String
		  If Child.Value(META_DIR) = True Then
		    s.Append("")
		  End If
		  Do Until Child = Nil Or Child.Value(META_PATH) = "$ROOT"
		    s.Insert(0, Child.Value(META_PATH))
		    Dim w As WeakRef = Child.Value(META_PARENT)
		    If w = Nil Or w.Value = Nil Then
		      Child = Nil
		    Else
		      Child = Dictionary(w.Value)
		    End If
		  Loop
		  
		  Return Join(s, "/")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEntryComment(Path As String, Comment As String)
		  ' Sets the comment for the entry. Set it to the empty string to remove a previous comment.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.SetEntryComment
		  
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  d.Value(META_COMMENT) = ConvertEncoding(Comment, Encodings.UTF8)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEntryCompressionLevel(Path As String, CompressionLevel As Integer)
		  ' Sets the compression level for the entry, overriding ZipWriter.CompressionLevel.
		  ' CompressionLevel must be between 0 and 9, inclusive.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.SetEntryCompressionLevel
		  
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
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.SetEntryCompressionMethod
		  
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
		Sub SetEntryContent(Path As String, Content As FolderItem)
		  ' Sets the contents for the entry, overwriting the previous content. The
		  ' path of the entry in the archive does not change, only the contents.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.SetEntryContent
		  
		  If Content.Length > MAX_FILE_SIZE Then Raise New ZipException(ERR_TOO_LARGE)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  d.Value(META_STREAM) = Content
		  d.Value(META_LENGTH) = Content.Length
		  If d.HasKey(META_MEMORY) Then d.Remove(META_MEMORY)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEntryContent(Path As String, Content As MemoryBlock)
		  ' Sets the contents for the entry, overwriting the previous content.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.SetEntryContent
		  
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  Dim bs As New BinaryStream(Content)
		  d.Value(META_STREAM) = bs
		  d.Value(META_LENGTH) = bs.Length
		  d.Value(META_MEMORY) = Content
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEntryContent(Path As String, Content As Readable, Length As UInt32)
		  ' Sets the contents for the entry, overwriting the previous content.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.SetEntryContent
		  
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  d.Value(META_STREAM) = Content
		  d.Value(META_LENGTH) = Length
		  If d.HasKey(META_MEMORY) Then d.Remove(META_MEMORY)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEntryExtraData(Path As String, Extra As MemoryBlock)
		  ' Sets the platform-specific "extra" data for the entry. Set this to Nil to remove the
		  ' previous Extra data.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.SetEntryExtraData
		  
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  d.Value(META_EXTRA) = Extra
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEntryModificationDate(Path As String, ModDate As Date)
		  ' Sets the "last modified" date for the entry. Set this to Nil to use the current date and time.
		  ' The zip date format has a year range of 1980-2099, a resolution of 2 seconds, and no time zone.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.SetEntryModificationDate
		  
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  If ModDate = Nil Then ModDate = New Date
		  d.Value(META_MODTIME) = ModDate
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function TraverseTree(Root As Dictionary, Path As String, CreateChildren As Boolean) As Dictionary
		  ' Given the root of a nested Dictionary and a file path, this method traverses from the root to the
		  ' item referred to by the path and returns a reference to the item as a Dictionary. If CreateChildren is
		  ' true then missing elements in the path are created, otherwise this method returns Nil to indicate
		  ' the path is not found.
		  
		  If Path.Trim = "" Then Return Nil
		  
		  Dim s() As String = Split(Path, "/")
		  Dim bound As Integer = UBound(s)
		  Dim parent As Dictionary = Root
		  For i As Integer = 0 To bound - 1
		    Dim name As String = NormalizeFilename(s(i))
		    If name = "" Then Continue
		    Dim child As Dictionary = parent.Lookup(name, Nil)
		    If child = Nil Then
		      If Not CreateChildren Then Return Nil
		      child = New Dictionary(META_PATH:name, META_DIR:True, META_PARENT:New WeakRef(parent), META_MODTIME:New Date, META_STREAM:Nil)
		    Else
		      child.Value(META_DIR) = True
		    End If
		    parent.Value(name) = child
		    parent = child
		  Next
		  
		  Dim name As String = NormalizeFilename(s(bound))
		  If name <> "" Then
		    Dim child As Dictionary = parent.Lookup(name, Nil)
		    If child = Nil Then
		      If Not CreateChildren Then Return Nil
		      child = New Dictionary(META_PATH:name, META_DIR:false, META_PARENT:New WeakRef(parent), META_MODTIME:New Date, META_STREAM:Nil)
		    End If
		    parent.Value(name) = child
		    parent = child
		  End If
		  Return parent
		End Function
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
		  ' This method writes a single file/directory entry to the output BinaryStream and populates
		  ' the DirectoryHeader parameter with the same info.
		  
		  If Not USE_ZLIB And Not USE_BZIP2 Then Level = 0
		  If Length = 0 Or Level = 0 Then method = 0
		  
		  DirectoryHeader.Offset = Stream.Position ' offset in the output at which the entry begins
		  Stream.WriteUInt32(ZIP_ENTRY_HEADER_SIGNATURE)
		  DirectoryHeader.Signature = ZIP_DIRECTORY_HEADER_SIGNATURE
		  
		  Stream.WriteUInt16(10) ' version needed to extract
		  DirectoryHeader.Version = 20 ' version made by
		  DirectoryHeader.VersionNeeded = 10
		  
		  ' Zip file names default to DosLatin. If FLAG_NAME_ENCODING is set then UTF8 is used instead.
		  If Name.Encoding = Encodings.UTF8 Then
		    DirectoryHeader.Flag = DirectoryHeader.Flag Or FLAG_NAME_ENCODING
		  End If
		  #If Not OUTPUT_SEEKABLE Then
		    ' If FLAG_DESRIPTOR is set then the crc and compressed size are given in a footer
		    ' instead of the header.
		    If Length > 0 Then DirectoryHeader.Flag = DirectoryHeader.Flag Or FLAG_DESCRIPTOR
		  #endif
		  Stream.WriteUInt16(DirectoryHeader.Flag) ' flags
		  
		  Stream.WriteUInt16(method) ' the compression method used on this entry
		  DirectoryHeader.Method = method
		  
		  Dim modtim As Pair = ConvertDate(ModDate)
		  Stream.WriteUInt16(modtim.Right) ' the last modified time of this entry in DOS format
		  Stream.WriteUInt16(modtim.Left) ' the last modified date of this entry in DOS format
		  DirectoryHeader.ModTime = modtim.Right
		  DirectoryHeader.ModDate = modtim.Left
		  
		  ' the crc and compressed size fields will be filled after the file data has been
		  ' compressed. This requires seeking backwards in the output stream. Alternatively,
		  ' the crc and compressed size can be given in an optional footer following the compressed
		  ' data. Set OUTPUT_SEEKABLE to False to have the ZipWriter use the footer instead of 
		  ' seeking backwards.
		  Dim crcoffset As UInt64 = Stream.Position
		  Stream.WriteUInt32(0) ' crc32; to be filled later
		  Stream.WriteUInt32(0) ' compressed size; to be filled later
		  
		  DirectoryHeader.UncompressedSize = Length
		  Stream.WriteUInt32(Length) ' uncompressed size
		  
		  DirectoryHeader.FilenameLength = Name.LenB
		  Stream.WriteUInt16(Name.LenB) ' name length
		  
		  ' Up to 16KB of arbitrary data can be included in the entry header
		  If ExtraData = Nil Then
		    ExtraData = ""
		  ElseIf ExtraData.Size > MAX_EXTRA_SIZE Then
		    Raise New ZipException(ERR_TOO_LARGE)
		  End If
		  DirectoryHeader.ExtraLength = ExtraData.Size
		  Stream.WriteUInt16(ExtraData.Size) ' extra length
		  
		  Stream.Write(Name) ' name
		  Stream.Write(ExtraData) ' extra
		  
		  Dim filedataoffset As UInt64 = Stream.Position ' end of header/start of data position
		  If Source <> Nil And Length > 0 Then
		    Dim z As Writeable = GetCompressor(Method, Stream, Level)
		    If z = Nil Then Raise New ZipException(ERR_UNSUPPORTED_COMPRESSION)
		    Do Until Source.EOF
		      Dim data As MemoryBlock = Source.Read(CHUNK_SIZE)
		      DirectoryHeader.CRC32 = PKZip.CRC32(data, DirectoryHeader.CRC32)
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
		    DirectoryHeader.CompressedSize = endoff - filedataoffset
		    #If OUTPUT_SEEKABLE Then
		      ' seek backwards to fill in the crc and compressed size fields in the header
		      Stream.Position = crcoffset
		      Stream.WriteUInt32(DirectoryHeader.CRC32)
		      Stream.WriteUInt32(DirectoryHeader.CompressedSize)
		      Stream.Position = endoff
		    #Else
		      ' write the crc and compressed size fields in a footer.
		      WriteEntryFooter(Stream, DirectoryHeader.CRC32, DirectoryHeader.CompressedSize, Length)
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
		#tag Note
			Sets the archive comment. Comments must not exceed 64KB in length.
			
			See:
			https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.ArchiveComment
		#tag EndNote
		ArchiveComment As String
	#tag EndProperty

	#tag Property, Flags = &h0
		#tag Note
			Sets the default compression level to use when writing the archive.
			
			See:
			https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.CompressionLevel
		#tag EndNote
		CompressionLevel As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		#tag Note
			Sets the default compression method to use when writing the archive. Supported methods are:
			
			  * METHOD_NONE (0) (store)
			  * METHOD_DEFLATED (8) (zlib required)
			  * METHOD_BZIP2 (12) (bzip2 required; https://github.com/charonn0/RB-bzip2 )
			
			Directories and zero-length files always use METHOD_NONE. See also PKZip.GetCompressor if you
			want to add another compression method.
			
			See:
			https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter.CompressionMethod
		#tag EndNote
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
