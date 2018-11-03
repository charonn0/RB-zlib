#tag Module
Protected Module USTAR
	#tag Method, Flags = &h21
		Private Sub CollapseTree(Root As Dictionary, ByRef Paths() As String, ByRef Lengths() As UInt32, ByRef ModTimes() As Date, ByRef Sources() As Readable, ByRef DirectoryStatus() As Boolean, ByRef Modes() As Permissions)
		  For Each key As Variant In Root.Keys
		    If Root.Value(key) IsA Dictionary Then
		      Dim item As Dictionary = Root.Value(key)
		      If item.Lookup("$d", False) Then CollapseTree(item, Paths, Lengths, ModTimes, Sources, DirectoryStatus, Modes)
		      Paths.Append(GetTreeParentPath(item))
		      Lengths.Append(item.Lookup("$s", 0))
		      ModTimes.Append(item.Value("$t"))
		      Sources.Append(item.Value("$r"))
		      DirectoryStatus.Append(item.Value("$d"))
		      Modes.Append(item.Value("$m"))
		    End If
		  Next
		End Sub
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
		Private Function GetCheckSum(TarHeader As MemoryBlock) As UInt32
		  If TarHeader.Size <> BLOCK_SIZE Then Return 0
		  Dim chksum As UInt32
		  For i as Integer = 0 To 499
		    Try
		      If i = 148 Then
		        i = 156
		        chksum = chksum + UInt32(32 * 8) ' 8 spaces
		      End If
		      Dim b As UInt8 = TarHeader.UInt8Value(i)
		      chksum = chksum + b
		    Catch Err As OutOfBoundsException
		      Exit For
		    End Try
		  Next
		  Return chksum
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
		Private Function PermissionsToMode(p As Permissions) As String
		  Dim mask As Integer
		  If p.GroupExecute Then mask = mask Or TGEXEC
		  If p.GroupRead Then mask = mask Or TGREAD
		  If p.GroupWrite Then mask = mask Or TGWRITE
		  
		  If p.OwnerExecute Then mask = mask Or TUEXEC
		  If p.OwnerRead Then mask = mask Or TUREAD
		  If p.OwnerWrite Then mask = mask Or TUWRITE
		  
		  If p.OthersExecute Then mask = mask Or TOEXEC
		  If p.OthersRead Then mask = mask Or TOREAD
		  If p.OthersWrite Then mask = mask Or TOWRITE
		  
		  Return Oct(mask)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ReadTar(TarFile As FolderItem, ExtractTo As FolderItem, Overwrite As Boolean = False) As FolderItem()
		  ' Extracts a TAR file to the ExtractTo directory
		  Dim ts As Readable
		  If TarFile.IsGZipped Then
		    ts = zlib.ZStream.Open(TarFile, zlib.GZIP_ENCODING)
		  ElseIf TarFile.IsBZipped Then
		    ts = BZip2.BZ2Stream.Open(TarFile)
		  Else
		    ts = BinaryStream.Open(TarFile)
		  End If
		  Dim tar As New TarReader(ts)
		  If Not ExtractTo.Exists Then ExtractTo.CreateAsFolder()
		  Dim bs As BinaryStream
		  Dim fs() As FolderItem
		  Do
		    If bs <> Nil Then bs.Close
		    bs = Nil
		    Dim g As FolderItem = CreateTree(ExtractTo, tar.CurrentName)
		    If Not g.Directory Then bs = BinaryStream.Create(g, Overwrite)
		    fs.Append(g)
		  Loop Until Not tar.MoveNext(bs)
		  If bs <> Nil Then bs.Close
		  If ts IsA BinaryStream Then BinaryStream(ts).Close
		  If ts IsA zlib.ZStream Then zlib.ZStream(ts).Close
		  If ts IsA BZip2.BZ2Stream Then BZip2.BZ2Stream(ts).Close
		  Return fs
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
		      child = New Dictionary("$n":name, "$d":false, "$p":New WeakRef(parent))
		    End If
		    parent.Value(name) = child
		    parent = child
		  End If
		  Return parent
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function WriteTar(ToArchive() As FolderItem, OutputFile As FolderItem, Optional RelativeRoot As FolderItem, Overwrite As Boolean = False, CompressionLevel As Integer) As Boolean
		  ' Creates/appends a TAR file with the ToArchive FolderItems
		  Dim tar As New TARWriter
		  For i As Integer = 0 To UBound(ToArchive)
		    Call tar.AppendEntry(ToArchive(i), RelativeRoot)
		  Next
		  Dim t As Writeable
		  Dim b As Boolean
		  If CompressionLevel > 0 And CompressionLevel < 10 Then
		    t = zlib.ZStream.Create(OutputFile, CompressionLevel, zlib.Z_DEFAULT_STRATEGY, Overwrite, zlib.GZIP_ENCODING)
		  Else
		    t = BinaryStream.Create(OutputFile, False)
		    b = True
		  End If
		  tar.Commit(t)
		  If b Then BinaryStream(t).Close Else zlib.ZStream(t).Close
		  Return True
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function WriteTar(RootDirectory As FolderItem, OutputFile As FolderItem, Overwrite As Boolean = False, CompressionLevel As Integer) As Boolean
		  ' Creates/appends a TAR file with the ToArchive FolderItems
		  Dim items() As FolderItem
		  GetChildren(RootDirectory, items)
		  Return WriteTar(items, OutputFile, RootDirectory, Overwrite, CompressionLevel)
		  
		  
		End Function
	#tag EndMethod


	#tag Constant, Name = BLKTYPE, Type = String, Dynamic = False, Default = \"4", Scope = Private
	#tag EndConstant

	#tag Constant, Name = BLOCK_SIZE, Type = Double, Dynamic = False, Default = \"512", Scope = Private
	#tag EndConstant

	#tag Constant, Name = CHRTYPE, Type = String, Dynamic = False, Default = \"3", Scope = Private
	#tag EndConstant

	#tag Constant, Name = DIRTYPE, Type = String, Dynamic = False, Default = \"5", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ERR_CHECKSUM_MISMATCH, Type = Double, Dynamic = False, Default = \"-304", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_END_ARCHIVE, Type = Double, Dynamic = False, Default = \"-302", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_INVALID_ENTRY, Type = Double, Dynamic = False, Default = \"-301", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_INVALID_NAME, Type = Double, Dynamic = False, Default = \"-305", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_MISALIGNED, Type = Double, Dynamic = False, Default = \"-300", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = FIFOTYPE, Type = String, Dynamic = False, Default = \"6", Scope = Private
	#tag EndConstant

	#tag Constant, Name = LNKTYPE, Type = String, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = REGTYPE, Type = String, Dynamic = False, Default = \"0", Scope = Private
	#tag EndConstant

	#tag Constant, Name = SYMTYPE, Type = String, Dynamic = False, Default = \"2", Scope = Private
	#tag EndConstant

	#tag Constant, Name = TGEXEC, Type = Double, Dynamic = False, Default = \"&o00010", Scope = Private
	#tag EndConstant

	#tag Constant, Name = TGREAD, Type = Double, Dynamic = False, Default = \"&o00040", Scope = Private
	#tag EndConstant

	#tag Constant, Name = TGWRITE, Type = Double, Dynamic = False, Default = \"&o00020", Scope = Private
	#tag EndConstant

	#tag Constant, Name = TOEXEC, Type = Double, Dynamic = False, Default = \"&o00001", Scope = Private
	#tag EndConstant

	#tag Constant, Name = TOREAD, Type = Double, Dynamic = False, Default = \"&o00004", Scope = Private
	#tag EndConstant

	#tag Constant, Name = TOWRITE, Type = Double, Dynamic = False, Default = \"&o00002", Scope = Private
	#tag EndConstant

	#tag Constant, Name = TSGID, Type = Double, Dynamic = False, Default = \"&o02000", Scope = Private
	#tag EndConstant

	#tag Constant, Name = TSUID, Type = Double, Dynamic = False, Default = \"&o04000", Scope = Private
	#tag EndConstant

	#tag Constant, Name = TSVTX, Type = Double, Dynamic = False, Default = \"&o01000", Scope = Private
	#tag EndConstant

	#tag Constant, Name = TUEXEC, Type = Double, Dynamic = False, Default = \"&o00100", Scope = Private
	#tag EndConstant

	#tag Constant, Name = TUREAD, Type = Double, Dynamic = False, Default = \"&o00400", Scope = Private
	#tag EndConstant

	#tag Constant, Name = TUWRITE, Type = Double, Dynamic = False, Default = \"&o00200", Scope = Private
	#tag EndConstant

	#tag Constant, Name = XGLTYPE, Type = String, Dynamic = False, Default = \"g", Scope = Private
	#tag EndConstant

	#tag Constant, Name = XHDTYPE, Type = String, Dynamic = False, Default = \"x", Scope = Private
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
End Module
#tag EndModule
