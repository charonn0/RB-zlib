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

	#tag Method, Flags = &h1
		Protected Function FormatError(ErrorCode As Integer, Optional Encoding As TextEncoding) As String
		  If Encoding = Nil Then Encoding = Encodings.UTF8
		  Select Case ErrorCode
		  Case ERR_END_ARCHIVE
		    Return DefineEncoding("The archive contains no further entries.", Encoding)
		  Case ERR_INVALID_ENTRY
		    Return DefineEncoding("The archive entry is corrupt.", Encoding)
		  Case ERR_CHECKSUM_MISMATCH
		    Return DefineEncoding("The archive entry failed verification.", Encoding)
		  Case ERR_INVALID_NAME
		    Return DefineEncoding("The archive entry has an illegal file name.", Encoding)
		  Case ERR_MISALIGNED
		    Return DefineEncoding("The archive is corrupt.", Encoding)
		  Else
		    Return DefineEncoding("Unknown error.", Encoding)
		  End Select
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
		        chksum = chksum + (32 * 8) ' 8 spaces
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
		Private Function HeaderChecksum(Extends mb As MemoryBlock) As UInt32
		  Return Val("&o" + mb.StringValue(148, 8))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HeaderChecksum(Extends mb As MemoryBlock, Assigns NewChecksum As UInt32)
		  mb.StringValue(148, 8) = OctPad(NewChecksum, 8)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HeaderFilesize(Extends mb As MemoryBlock) As UInt32
		  Return Val("&o" + mb.StringValue(124, 12))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HeaderFilesize(Extends mb As MemoryBlock, Assigns NewSize As UInt32)
		  mb.StringValue(124, 12) = OctPad(NewSize, 12)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HeaderGroup(Extends mb As MemoryBlock) As UInt32
		  Return Val("&o" + mb.StringValue(116, 8))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HeaderGroup(Extends mb As MemoryBlock, Assigns NewGroup As UInt32)
		  mb.StringValue(116, 8) = OctPad(NewGroup, 8)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HeaderLinkIndicator(Extends mb As MemoryBlock) As String
		  Return mb.StringValue(156, 1)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HeaderLinkIndicator(Extends mb As MemoryBlock, Assigns NewLinkIndicator As String)
		  mb.StringValue(156, 1) = LeftB(NewLinkIndicator, 1)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HeaderLinkName(Extends mb As MemoryBlock) As String
		  Return ReplaceAllB(mb.StringValue(157, 100), Chr(0), "")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HeaderLinkName(Extends mb As MemoryBlock, Assigns NewLinkName As String)
		  mb.StringValue(157, 100) = LeftB(NewLinkName, 100)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HeaderModDate(Extends mb As MemoryBlock) As Date
		  Dim count As Integer = Val("&o" + mb.StringValue(136, 12))
		  Dim time As New Date(1970, 1, 1, 0, 0, 0, 0.0) 'UNIX epoch
		  time.TotalSeconds = time.TotalSeconds + count
		  Return time
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HeaderModDate(Extends mb As MemoryBlock, Assigns NewDate As Date)
		  Const epoch = 2082844800 ' Unix epoch expressed as Date.TotalSeconds
		  mb.StringValue(136, 12) = OctPad(NewDate.TotalSeconds - epoch, 12)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HeaderMode(Extends mb As MemoryBlock) As Permissions
		  Dim mask As Integer = Val("&o" + mb.StringValue(100, 8))
		  Return New Permissions(mask)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HeaderMode(Extends mb As MemoryBlock, Assigns NewMode As Permissions)
		  mb.StringValue(100, 8) = PermissionsToMode(NewMode)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HeaderName(Extends mb As MemoryBlock) As String
		  Return ReplaceAllB(mb.StringValue(0, 100), Chr(0), "")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HeaderName(Extends mb As MemoryBlock, Assigns NewName As String)
		  mb.StringValue(0, 100) = LeftB(NewName, 100)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HeaderOwner(Extends mb As MemoryBlock) As UInt32
		  Return Val("&o" + mb.StringValue(108, 8))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HeaderOwner(Extends mb As MemoryBlock, Assigns NewOwner As UInt32)
		  mb.StringValue(108, 8) = OctPad(NewOwner, 8)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HeaderSignature(Extends mb As MemoryBlock) As String
		  Return mb.StringValue(257, 6).Trim
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HeaderSignature(Extends mb As MemoryBlock, Assigns NewSig As String)
		  mb.StringValue(257, 6) = LeftB(NewSig, 5) + Chr(0)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HeaderType(Extends mb As MemoryBlock) As String
		  Return mb.StringValue(156, 1)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HeaderType(Extends mb As MemoryBlock, Assigns NewType As String)
		  mb.StringValue(156, 1) = Left(NewType, 1)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsTarred(Extends TargetFile As FolderItem) As Boolean
		  //Returns True if the TargetFile is likely a tape archive
		  
		  If Not TargetFile.Exists Then Return False
		  If TargetFile.Directory Then Return False
		  Dim bs As Readable
		  Dim IsTAR As Boolean
		  Try
		    #If USE_ZLIB Then
		      If TargetFile.IsGZipped Then bs = zlib.ZStream.Open(TargetFile, zlib.GZIP_ENCODING)
		    #endif
		    #If USE_BZIP Then
		      If bs = Nil And TargetFile.IsBZipped Then bs = BZip2.BZ2Stream.Open(TargetFile)
		    #endif
		    If bs = Nil Then bs = BinaryStream.Open(TargetFile)
		    IsTAR = bs.IsTarred
		    
		  Catch
		    IsTAR = False
		  Finally
		    If bs <> Nil Then
		      If bs IsA BinaryStream Then BinaryStream(bs).Close
		      #If USE_ZLIB Then
		        If bs IsA zlib.ZStream Then zlib.ZStream(bs).Close
		      #endif
		      #If USE_BZIP Then
		        If bs IsA BZip2.BZ2Stream Then BZip2.BZ2Stream(bs).Close
		      #endif
		      
		    End If
		  End Try
		  Return IsTAR
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsTarred(Extends Target As MemoryBlock) As Boolean
		  //CReturns True if the Target is likely a tape archive
		  
		  If Target.Size = -1 Then Return False
		  Dim bs As Readable
		  Dim IsTAR As Boolean
		  Try
		    #If USE_ZLIB Then
		      If Target.IsGZipped Then bs = New zlib.ZStream(Target)
		    #endif
		    #If USE_BZIP Then
		      If bs = Nil And Target.IsBZipped Then bs = New BZip2.BZ2Stream(Target)
		    #endif
		    If bs = Nil Then bs = New BinaryStream(Target)
		    IsTAR = bs.IsTarred()
		  Catch
		    IsTAR = False
		  Finally
		    If bs IsA BinaryStream Then BinaryStream(bs).Close
		    #If USE_ZLIB Then
		      If bs IsA zlib.ZStream Then zlib.ZStream(bs).Close
		    #endif
		    #If USE_BZIP Then
		      If bs IsA BZip2.BZ2Stream Then BZip2.BZ2Stream(bs).Close
		    #endif
		    
		  End Try
		  Return IsTAR
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function IsTarred(Extends Target As Readable) As Boolean
		  //Returns True if the Target is likely a tape archive
		  
		  Dim header As MemoryBlock = Target.Read(BLOCK_SIZE)
		  Return header.HeaderChecksum = GetChecksum(header)
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
		Private Function OctPad(Value As Integer, Width As Integer) As String
		  Const zeros = "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
		  Return Right(zeros + Oct(Value), Width)
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
		  
		  Return OctPad(mask, 8)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ReadTar(TarFile As FolderItem, ExtractTo As FolderItem, Overwrite As Boolean = False) As FolderItem()
		  ' Extracts a TAR file to the ExtractTo directory
		  Dim ts As Readable
		  #If USE_ZLIB Then
		    If TarFile.IsGZipped Then ts = zlib.ZStream.Open(TarFile, zlib.GZIP_ENCODING)
		  #endif
		  #If USE_BZIP Then
		    If ts = Nil And TarFile.IsBZipped Then ts = BZip2.BZ2Stream.Open(TarFile)
		  #endif
		  If ts = Nil Then ts = BinaryStream.Open(TarFile)
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
		  #If USE_ZLIB Then
		    If ts IsA zlib.ZStream Then zlib.ZStream(ts).Close
		  #endif
		  #If USE_BZIP Then
		    If ts IsA BZip2.BZ2Stream Then BZip2.BZ2Stream(ts).Close
		  #endif
		  
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
		Protected Function WriteTar(ToArchive() As FolderItem, OutputFile As FolderItem, Optional RelativeRoot As FolderItem, Overwrite As Boolean = False, CompressionLevel As Integer = 0) As Boolean
		  ' Creates/appends a TAR file with the ToArchive FolderItems
		  Dim tar As New TARWriter
		  For i As Integer = 0 To UBound(ToArchive)
		    Call tar.AppendEntry(ToArchive(i), RelativeRoot)
		  Next
		  Dim t As Writeable
		  If CompressionLevel > 0 And CompressionLevel < 10 Then
		    If NthField(OutputFile.Name, ".", CountFields(OutputFile.Name, ".")) = "bz2" Then
		      #If USE_BZIP Then
		        t = BZip2.BZ2Stream.Create(OutputFile, CompressionLevel)
		      #endif
		    Else
		      #If USE_ZLIB Then
		        t = zlib.ZStream.Create(OutputFile, CompressionLevel, zlib.Z_DEFAULT_STRATEGY, Overwrite, zlib.GZIP_ENCODING)
		      #endif
		    End If
		  End If
		  If t = Nil Then t = BinaryStream.Create(OutputFile, Overwrite)
		  tar.Commit(t)
		  If t IsA BinaryStream Then BinaryStream(t).Close
		  #If USE_ZLIB Then
		    If t IsA zlib.ZStream Then zlib.ZStream(t).Close
		  #endif
		  #If USE_BZIP Then
		    If t IsA BZip2.BZ2Stream Then BZip2.BZ2Stream(t).Close
		  #endif
		  
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function WriteTar(RootDirectory As FolderItem, OutputFile As FolderItem, Overwrite As Boolean = False, CompressionLevel As Integer = 0) As Boolean
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

	#tag Constant, Name = LONGNAMETYPE, Type = String, Dynamic = False, Default = \"L", Scope = Private
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

	#tag Constant, Name = USE_BZIP, Type = Boolean, Dynamic = False, Default = \"False", Scope = Private
	#tag EndConstant

	#tag Constant, Name = USE_ZLIB, Type = Boolean, Dynamic = False, Default = \"True", Scope = Private
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
