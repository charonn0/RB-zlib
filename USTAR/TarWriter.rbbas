#tag Class
Protected Class TarWriter
	#tag Method, Flags = &h1
		Protected Sub Append(Path As String, Data As Variant, Length As UInt32, ModifyDate As Date = Nil, Mode As Permissions = Nil)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, True)
		  If d = Nil Then Raise New TARException(ERR_INVALID_NAME)
		  d.Value(META_STREAM) = Data
		  d.Value(META_LENGTH) = Length
		  If ModifyDate = Nil Then ModifyDate = New Date
		  d.Value(META_MODTIME) = ModifyDate
		  If Mode = Nil Then Mode = New Permissions(&o644)
		  d.Value(META_MODE) = Mode
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AppendDirectory(Entry As FolderItem, RelativeRoot As FolderItem = Nil)
		  ' Adds the directory represented by the Entry parameter to the archive. If RelativeRoot
		  ' is specified then the entry and all subdirectories and files within it will be stored
		  ' as a sub directory (named as Entry.Name) of the archive root. If RelativeRoot is not
		  ' specified then all subdirectories and files within the Entry directory are added to the
		  ' archive root rather than in a subdirectory.
		  '
		  ' https://github.com/charonn0/RB-zlib/wiki/USTAR.TarWriter.AppendDirectory
		  
		  If Not Entry.Directory Then
		    Call AppendEntry(Entry, RelativeRoot)
		    Return
		  End If
		  
		  If RelativeRoot = Nil Then RelativeRoot = Entry
		  Dim entries() As FolderItem = Array(Entry)
		  GetChildren(Entry, entries)
		  Dim c As Integer = UBound(entries)
		  For i As Integer = 0 To c
		    Call AppendEntry(entries(i), RelativeRoot)
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function AppendEntry(Entry As FolderItem, Optional RelativeRoot As FolderItem) As String
		  ' Adds the file represented by the Entry parameter to the archive. If RelativeRoot is
		  ' specified then the entry will be stored using the relative path; if the Entry is not
		  ' contained within RelativeRoot then the file is added to the root of the archive. Returns
		  ' a path which can be used with the SetEntry* methods to modify the entry.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/USTAR.TarWriter.AppendEntry
		  
		  Dim path As String = GetRelativePath(RelativeRoot, Entry)
		  If Entry.Directory Then path = path + "/"
		  Dim p As New Permissions(Entry.Permissions)
		  Append(path, Entry, Entry.Length, Entry.ModificationDate, p)
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
		  ' https://github.com/charonn0/RB-zlib/wiki/USTAR.TarWriter.AppendEntry
		  
		  Dim bs As New BinaryStream(Data)
		  AppendEntry(Path, bs, bs.Length, ModifyDate)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Raise New TarException(ERR_INVALID_NAME)
		  d.Value(META_MEMORY) = Data
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AppendEntry(Path As String, Data As Readable, Length As UInt32, ModifyDate As Date = Nil, Mode As Permissions = Nil)
		  ' Adds the raw file data represented by the Data parameter to the archive using the specifed
		  ' Path (or filename). The Path is relative to the root of the archive and is delimited by the
		  ' "/" character. e.g. "dir1/dir2/file.txt". File names without a path are placed in the root
		  ' of the archive.
		  ' The Length parameter specifies how many bytes long the Data is supposed to be. Be aware that
		  ' this value is used only to fill in the archive header--it does not control how many bytes will
		  ' be read from the Data stream. If the Length parameter is wrong then archive readers will report
		  ' the wrong compression ratio and possibly other side effects will ensue.
		  ' If the ModifyDate parameter is not specified then the current date and time are used.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/USTAR.TarWriter.AppendEntry
		  
		  Dim d As Dictionary = TraverseTree(mEntries, Path, True)
		  If d = Nil Then Raise New TARException(ERR_INVALID_NAME)
		  d.Value(META_STREAM) = Data
		  d.Value(META_LENGTH) = Length
		  If ModifyDate = Nil Then ModifyDate = New Date
		  d.Value(META_MODTIME) = ModifyDate
		  d.Value(META_MODE) = Mode
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Commit(WriteTo As FolderItem, Overwrite As Boolean = False)
		  ' Writes the zip archive to the file specified by WriteTo. If Overwrite is True then WriteTo
		  ' will be overwritten if it exists.
		  ' 
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/USTAR.TarWriter.Commit
		  
		  If WriteTo = Nil Or WriteTo.Directory Then Return
		  Dim bs As BinaryStream = BinaryStream.Create(WriteTo, Overwrite)
		  Commit(bs)
		  bs.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Commit(WriteTo As Writeable)
		  ' Writes the TAR archive to the WriteTo stream. Pass an instance of ZStream (typically configured
		  ' to use GZip encoding) to compress the archive.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/USTAR.TarWriter.Commit
		  
		  Dim paths() As String
		  Dim lengths() As UInt32
		  Dim sources() As Variant
		  Dim modtimes() As Date
		  Dim dirstatus() As Boolean
		  Dim modes() As Permissions
		  CollapseTree(mEntries, paths, lengths, modtimes, sources, dirstatus, modes)
		  
		  Dim c As Integer = UBound(paths)
		  For i As Integer = 0 To c
		    Dim length As UInt32 = lengths(i)
		    Dim path As String = paths(i)
		    path = ConvertEncoding(path, Encodings.UTF8)
		    Dim source As Readable
		    If sources(i) IsA Readable Then
		      source = sources(i)
		    ElseIf sources(i) IsA FolderItem Then
		      Dim f As FolderItem = sources(i)
		      If Not f.Directory Then source = BinaryStream.Open(f)
		    End If
		    Dim modtime As Date = modtimes(i)
		    Dim mode As Permissions = modes(i)
		    If dirstatus(i) And Right(path, 1) <> "/" Then path = path + "/"
		    WriteEntry(WriteTo, path, source, length, 0, 0, mode, modtime)
		  Next
		  
		  Dim eof As New MemoryBlock(BLOCK_SIZE * 2)
		  WriteBlocks(WriteTo, eof)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  ' Constructs the unnamed root directory in the archive's directory model.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/USTAR.TarWriter.Constructor
		  
		  mEntries = New Dictionary(META_PATH:"$ROOT", META_PARENT:Nil, META_DIR:True)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DeleteEntry(Path As String)
		  ' Removes the archive entry specified by the Path. If the entry represents a directory then
		  ' all entries within that directory are removed as well. If Path is "/" then *all* entries
		  ' are removed.
		  ' 
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/USTAR.TarWriter.DeleteEntry
		  
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
		Sub SetEntryMode(Path As String, Mode As Permissions)
		  ' Sets the Unix-style permissions for the entry.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/USTAR.TarWriter.SetEntryMode
		  
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  d.Value(META_MODE) = Mode
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetEntryModificationDate(Path As String, ModDate As Date)
		  ' Sets the "last modified" date for the entry. Set this to Nil to use the current date and time.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/USTAR.TarWriter.SetEntryModificationDate
		  
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  d.Value(META_MODTIME) = ModDate
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Sub WriteBlocks(WriteTo As Writeable, Data As MemoryBlock)
		  Dim bs As New BinaryStream(Data)
		  WriteBlocks(WriteTo, bs)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Sub WriteBlocks(WriteTo As Writeable, ReadFrom As Readable)
		  Do Until ReadFrom.EOF
		    Dim block As MemoryBlock = ReadFrom.Read(BLOCK_SIZE)
		    If block.Size < BLOCK_SIZE Then block.Size = BLOCK_SIZE
		    If block.Size > BLOCK_SIZE Then Raise New TARException(ERR_MISALIGNED)
		    WriteTo.Write(block)
		  Loop
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Shared Sub WriteEntry(WriteTo As Writeable, Path As String, Data As Readable, DataLength As UInt64, Owner As Integer, Group As Integer, Mode As Permissions, ModTime As Date)
		  Dim header As MemoryBlock
		  If Path.LenB > 100 Then
		    ' the long-name header indicates the the name is encoded in one or more
		    ' blocks following the current block, followed by the file data.
		    header = New MemoryBlock(BLOCK_SIZE)
		    header.HeaderType = LONGNAMETYPE
		    header.HeaderSignature = "USTAR"
		    header.HeaderFilesize = Path.LenB
		    header.HeaderName = "././@LongLink"
		    header.HeaderChecksum = GetChecksum(header)
		    WriteBlocks(WriteTo, header)
		    WriteBlocks(WriteTo, Path)
		  End If
		  header = New MemoryBlock(BLOCK_SIZE)
		  header.HeaderSignature = "USTAR"
		  If Data = Nil Then
		    header.HeaderType = DIRTYPE
		  Else
		    header.HeaderType = REGTYPE
		  End If
		  header.HeaderName = LeftB(Path, 100)
		  header.HeaderMode = Mode
		  header.HeaderOwner = Owner
		  header.HeaderGroup = Group
		  header.HeaderFilesize = DataLength
		  header.HeaderModDate = ModTime
		  'header.StringValue(157, 100) = LinkName
		  header.HeaderChecksum = GetChecksum(header)
		  
		  WriteBlocks(WriteTo, header)
		  If Data <> Nil Then WriteBlocks(WriteTo, Data)
		End Sub
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the most recent error code.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/USTAR.TarWriter.LastError
			  
			  Return mLastError
			End Get
		#tag EndGetter
		LastError As Int32
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mEntries As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Int32
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
