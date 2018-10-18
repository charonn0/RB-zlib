#tag Module
Protected Module PKZip
	#tag Method, Flags = &h21
		Private Sub CollapseTree(Root As Dictionary, ByRef Paths() As String, ByRef Lengths() As UInt32, ByRef ModTimes() As Date, ByRef Sources() As Readable, ByRef Comments() As String, ByRef Extras() As MemoryBlock, ByRef DirectoryStatus() As Boolean)
		  For Each key As Variant In Root.Keys
		    If Root.Value(key) IsA Dictionary Then
		      Dim item As Dictionary = Root.Value(key)
		      If item.Lookup("$d", False) Then CollapseTree(item, Paths, Lengths, ModTimes, Sources, Comments, Extras, DirectoryStatus)
		      Paths.Append(GetTreeParentPath(item))
		      Lengths.Append(item.Lookup("$s", 0))
		      ModTimes.Append(item.Value("$t"))
		      Sources.Append(item.Value("$r"))
		      DirectoryStatus.Append(item.Value("$d"))
		      Extras.Append(Nil)
		      Comments.Append(item.Lookup("$c", ""))
		    End If
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ConvertDate(NewDate As Date) As Pair
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
		Private Function ConvertDate(Dt As UInt16, tm As UInt16) As Date
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

	#tag Method, Flags = &h21
		Private Function CreateTree(Root As FolderItem, Path As String) As FolderItem
		  ' Returns a FolderItem corresponding to Root+Path, creating subdirectories as needed
		  
		  If Root = Nil Or Not Root.Directory Then Return Nil
		  Dim s() As String = Split(Path, "/")
		  Dim bound As Integer = UBound(s)
		  
		  For i As Integer = 0 To bound - 1
		    Dim name As String = NormalizeFilename(s(i))
		    If name = "" Then Continue
		    root = root.TrueChild(name)
		    If Root.Exists Then
		      If Not Root.Directory Then
		        Dim err As New IOException
		        err.Message = "'" + name + "' is not a directory!"
		        Raise err
		      End If
		    Else
		      root.CreateAsFolder
		    End If
		  Next
		  
		  Dim name As String = NormalizeFilename(s(bound))
		  If name <> "" Then Root = Root.Child(name)
		  
		  Return Root
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function FindEntryFooter(Stream As BinaryStream, ByRef Footer As ZipEntryFooter) As Boolean
		  If Not SeekSignature(Stream, ZIP_ENTRY_FOOTER_SIGNATURE) Then Return False
		  If Not ReadEntryFooter(Stream, Footer) Then Return False
		  Return footer.CompressedSize > 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub GetChildren(Root As FolderItem, ByRef Results() As FolderItem)
		  Dim c As Integer = Root.Count
		  For i As Integer = 1 To c
		    Dim item As FolderItem = Root.TrueItem(i)
		    Results.Append(item)
		    If item.Directory Then GetChildren(item, Results)
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function GetRelativePath(Root As FolderItem, Item As FolderItem) As String
		  If Root = Nil Then Return Item.Name
		  Dim s() As String
		  Do Until Item.AbsolutePath = Root.AbsolutePath
		    s.Insert(0, Item.Name)
		    Item = Item.Parent
		  Loop Until Item = Nil
		  If Item = Nil Then Return s.Pop ' not relative
		  Return Join(s, "/")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function GetTreeParentPath(Child As Dictionary) As String
		  Dim s() As String
		  If Child.Value("$d") = True Then 
		    s.Append("")
		  End If
		  Do Until Child = Nil Or Child.Value("$n") = "$ROOT"
		    s.Insert(0, Child.Value("$n"))
		    Dim w As WeakRef = Child.Value("$p")
		    If w = Nil Or w.Value = Nil Then
		      Child = Nil
		    Else
		      Child = Dictionary(w.Value)
		    End If
		  Loop
		  
		  Return Join(s, "/")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function NormalizeFilename(Name As String) As String
		  ' This method takes a file name from an archive and transforms it (if necessary) to abide by
		  ' the rules of the target system.
		  
		  #If TargetWin32 Then
		    Static reservednames() As String = Array("con", "prn", "aux", "nul", "com1", "com2", "com3", "com4", "com5", "com6", "com7", "com8", "com9", _
		    "lpt1", "lpt2", "lpt3", "lpt4", "lpt5", "lpt6", "lpt7", "lpt8", "lpt9")
		    Static reservedchars() As String = Array("<", ">", ":", """", "/", "\", "|", "?", "*")
		  #ElseIf TargetLinux Then
		    Static reservednames() As String = Array(".", "..")
		    Static reservedchars() As String = Array("/", Chr(0))
		  #ElseIf TargetMacOS Then
		    Static reservednames() As String ' none
		    Static reservedchars() As String = Array(":", Chr(0))
		  #endif
		  
		  For Each char As String In Name.Split("")
		    If reservedchars.IndexOf(char) > -1 Then name = ReplaceAll(name, char, "_")
		  Next
		  
		  If reservednames.IndexOf(name) > -1 Then name = "_" + name
		  #If TargetWin32 Then
		    ' Windows doesn't like it even if the reserved name is used with an extension, e.g. 'aux.c' is illegal.
		    If reservednames.IndexOf(NthField(name, ".", 1)) > -1 Then name = "_" + name
		  #endif
		  
		  Return name
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ReadDirectoryFooter(Stream As BinaryStream, ByRef Footer As ZipDirectoryFooter) As Boolean
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
		Private Function ReadDirectoryHeader(Stream As BinaryStream, ByRef Header As ZipDirectoryHeader) As Boolean
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
		Private Function ReadEntryFooter(Stream As BinaryStream, ByRef Footer As ZipEntryFooter) As Boolean
		  Footer.Signature = Stream.ReadUInt32
		  Footer.CRC32 = Stream.ReadUInt32
		  Footer.CompressedSize = Stream.ReadUInt32
		  Footer.UncompressedSize = Stream.ReadUInt32
		  
		  Return Footer.Signature = ZIP_ENTRY_FOOTER_SIGNATURE
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ReadEntryHeader(Stream As BinaryStream, ByRef Header As ZipEntryHeader) As Boolean
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

	#tag Method, Flags = &h1
		Protected Function ReadZip(ZipFile As FolderItem, ExtractTo As FolderItem, Overwrite As Boolean = False, VerifyCRC As Boolean = True) As FolderItem()
		  ' Extracts a ZIP file to the ExtractTo directory
		  
		  Dim zip As New ZipReader(BinaryStream.Open(ZipFile))
		  zip.ValidateChecksums = VerifyCRC
		  Dim ret() As FolderItem
		  If Not ExtractTo.Exists Then ExtractTo.CreateAsFolder()
		  
		  Do Until zip.LastError <> 0
		    Dim f As FolderItem = CreateTree(ExtractTo, zip.CurrentName)
		    If f = Nil Then Raise New ZipException(ERR_INVALID_NAME)
		    Dim outstream As BinaryStream
		    If Not f.Directory Then outstream = BinaryStream.Create(f, Overwrite)
		    Call zip.MoveNext(outstream)
		    If outstream <> Nil Then outstream.Close
		    ret.Append(f)
		  Loop
		  If zip.LastError <> ERR_END_ARCHIVE Then Raise New ZipException(zip.LastError)
		  zip.Close
		  Return ret
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SeekSignature(Stream As BinaryStream, Signature As UInt32) As Boolean
		  Dim pos As UInt64 = Stream.Position
		  Dim ok As Boolean
		  Dim sig As New MemoryBlock(4)
		  sig.LittleEndian = True
		  sig.UInt32Value(0) = Signature
		  
		  Do Until Stream.EOF
		    Dim data As String = Stream.Read(CHUNK_SIZE)
		    Dim offset As Integer = InStrB(data, sig)
		    If offset > 0 Then
		      Stream.Position = Stream.Position - (data.LenB - offset + 1)
		      ok = True
		      Exit Do
		    ElseIf Stream.Length - Stream.Position >= 4 Then
		      Stream.Position = Stream.Position - 3
		    End If
		  Loop
		  If Not ok Then Stream.Position = pos
		  Return ok
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function TraverseTree(Root As Dictionary, Path As String, CreateChildren As Boolean) As Dictionary
		  Dim s() As String = Split(Path, "/")
		  Dim bound As Integer = UBound(s)
		  Dim parent As Dictionary = Root
		  For i As Integer = 0 To bound - 1
		    Dim name As String = NormalizeFilename(s(i))
		    If name = "" Then Continue
		    Dim child As Dictionary = parent.Lookup(name, Nil)
		    If child = Nil Then
		      If Not CreateChildren Then Return Nil
		      child = New Dictionary
		      child.Value("$n") = name
		      child.Value("$d") = True
		      child.Value("$p") = New WeakRef(parent)
		      'child.Value("$a") = parent.Value("$a") + name + "/"
		    Else
		      child.Value("$d") = True
		    End If
		    parent.Value(name) = child
		    parent = child
		  Next
		  
		  Dim name As String = NormalizeFilename(s(bound))
		  If name <> "" Then 
		    Dim child As Dictionary = parent.Lookup(name, Nil)
		    If child = Nil Then
		      If Not CreateChildren Then Return Nil
		      child = New Dictionary("$n":name, "$d":false, "$p":New WeakRef(parent))', "$a":parent.Value("$a") + name)
		    End If
		    parent.Value(name) = child
		    parent = child
		  End If
		  Return parent
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub WriteDirectory(Stream As BinaryStream, Headers() As ZipDirectoryHeader, Names() As String, Comments() As String, Extras() As MemoryBlock, ArchiveComment As String)
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
		Private Sub WriteDirectoryFooter(Stream As BinaryStream, Footer As ZipDirectoryFooter)
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
		Private Sub WriteDirectoryHeader(Stream As BinaryStream, Header As ZipDirectoryHeader, Name As String, Comment As String, Extra As MemoryBlock)
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
		Private Sub WriteEntryHeader(Stream As BinaryStream, Name As String, Length As UInt32, Source As Readable, ModDate As Date, CompressionLevel As Integer, ByRef DirectoryHeader As ZipDirectoryHeader)
		  If Not USE_ZLIB Then CompressionLevel = 0
		  DirectoryHeader.Offset = Stream.Position
		  Dim crcoff, compszoff, dataoff As UInt64
		  Stream.WriteUInt32(ZIP_ENTRY_HEADER_SIGNATURE)
		  DirectoryHeader.Signature = ZIP_DIRECTORY_HEADER_SIGNATURE
		  
		  Stream.WriteUInt16(20) ' version
		  DirectoryHeader.Version = 20
		  DirectoryHeader.VersionNeeded = 10
		  
		  If Name.Encoding = Encodings.UTF8 Then
		    DirectoryHeader.Flag = 2048
		  End If
		  Stream.WriteUInt16(DirectoryHeader.Flag) ' flag
		  
		  If Length = 0 Or CompressionLevel = 0 Then
		    Stream.WriteUInt16(0) ' method=none
		    DirectoryHeader.Method = 0
		  Else
		    Stream.WriteUInt16(METHOD_DEFLATED) ' method=deflate
		    DirectoryHeader.Method = METHOD_DEFLATED
		  End If
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
		  
		  DirectoryHeader.ExtraLength = 0
		  Stream.WriteUInt16(0) ' extra length
		  
		  Stream.Write(name)
		  //Stream.Write("") ' extra
		  
		  dataoff = Stream.Position
		  Dim crc As UInt32
		  If Source <> Nil And Length > 0 Then
		    Dim z As Writeable
		    If CompressionLevel <> 0 Then
		      #If USE_ZLIB Then
		        z = zlib.ZStream.Create(Stream, CompressionLevel, zlib.Z_DEFAULT_STRATEGY, zlib.RAW_ENCODING)
		      #else
		        Raise New ZipException(ERR_UNSUPPORTED_COMPRESSION)
		      #endif
		    Else
		      z = Stream
		    End If
		    Do Until Source.EOF
		      Dim data As MemoryBlock = Source.Read(CHUNK_SIZE)
		      crc = zlib.CRC32(data, crc)
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


	#tag Constant, Name = CHUNK_SIZE, Type = Double, Dynamic = False, Default = \"131072", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ERR_CHECKSUM_MISMATCH, Type = Double, Dynamic = False, Default = \"-204", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_END_ARCHIVE, Type = Double, Dynamic = False, Default = \"-202", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_INVALID_ENTRY, Type = Double, Dynamic = False, Default = \"-201", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_INVALID_NAME, Type = Double, Dynamic = False, Default = \"-205", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_NOT_ZIPPED, Type = Double, Dynamic = False, Default = \"-200", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_TOO_LARGE, Type = Double, Dynamic = False, Default = \"-206", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_UNSUPPORTED_COMPRESSION, Type = Double, Dynamic = False, Default = \"-203", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = FLAG_DESCRIPTOR, Type = Double, Dynamic = False, Default = \"8", Scope = Private
	#tag EndConstant

	#tag Constant, Name = FLAG_ENCRYPTED, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = FLAG_NAME_ENCODING, Type = Double, Dynamic = False, Default = \"2048", Scope = Private
	#tag EndConstant

	#tag Constant, Name = MAX_COMMENT_SIZE, Type = Double, Dynamic = False, Default = \"&hFFFF", Scope = Private
	#tag EndConstant

	#tag Constant, Name = MAX_EXTRA_SIZE, Type = Double, Dynamic = False, Default = \"&hFFFF", Scope = Private
	#tag EndConstant

	#tag Constant, Name = MAX_NAME_SIZE, Type = Double, Dynamic = False, Default = \"&hFFFF", Scope = Private
	#tag EndConstant

	#tag Constant, Name = METHOD_DEFLATED, Type = Double, Dynamic = False, Default = \"8", Scope = Private
	#tag EndConstant

	#tag Constant, Name = MIN_ARCHIVE_SIZE, Type = Double, Dynamic = False, Default = \"ZIP_DIRECTORY_FOOTER_SIZE\r", Scope = Private
	#tag EndConstant

	#tag Constant, Name = USE_ZLIB, Type = Boolean, Dynamic = False, Default = \"True", Scope = Private
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
		  CompressedSize As UInt32
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


End Module
#tag EndModule
