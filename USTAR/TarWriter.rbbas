#tag Class
Protected Class TarWriter
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
		  Dim path As String = GetRelativePath(RelativeRoot, Entry)
		  Dim bs As BinaryStream
		  If Not Entry.Directory Then
		    bs = BinaryStream.Open(Entry)
		  Else
		    path = path + "/"
		  End If
		  Dim p As New Permissions(Entry.Permissions)
		  AppendEntry(path, bs, Entry.Length, Entry.ModificationDate, p)
		  Return path
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AppendEntry(Path As String, Data As Readable, Length As UInt32, ModifyDate As Date = Nil, Mode As Permissions = Nil)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, True)
		  If d = Nil Then Raise New TARException(ERR_INVALID_NAME)
		  d.Value("$r") = Data
		  d.Value("$s") = Length
		  If ModifyDate = Nil Then ModifyDate = New Date
		  d.Value("$t") = ModifyDate
		  d.Value("$m") = Mode
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
		Sub Commit(WriteTo As Writeable)
		  Dim paths() As String
		  Dim lengths() As UInt32
		  Dim sources() As Readable
		  Dim modtimes() As Date
		  Dim dirstatus() As Boolean
		  Dim modes() As Permissions
		  CollapseTree(mEntries, paths, lengths, modtimes, sources, dirstatus, modes)
		  
		  Dim c As Integer = UBound(paths)
		  For i As Integer = 0 To c
		    Dim length As UInt32 = lengths(i)
		    Dim path As String = paths(i)
		    path = ConvertEncoding(path, Encodings.UTF8)
		    Dim source As Readable = sources(i)
		    Dim modtime As Date = modtimes(i)
		    Dim mode As Permissions = modes(i)
		    If dirstatus(i) And Right(path, 1) <> "/" Then path = path + "/"
		    WriteEntry(WriteTo, path, source, length, 0, 0, mode, modtime)
		  Next
		  
		  Dim eof As New MemoryBlock(BLOCK_SIZE)
		  WriteBlocks(WriteTo, eof)
		  
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
		Sub SetEntryModificationDate(Path As String, ModDate As Date)
		  Dim d As Dictionary = TraverseTree(mEntries, Path, False)
		  If d = Nil Then Return
		  d.Value("$t") = ModDate
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Sub WriteBlocks(WriteTo As Writeable, Data As MemoryBlock)
		  Dim bs As New BinaryStream(Data)
		  
		  Do Until bs.EOF
		    Dim block As MemoryBlock = bs.Read(BLOCK_SIZE)
		    If block.Size < BLOCK_SIZE Then block.Size = BLOCK_SIZE
		    If block.Size > BLOCK_SIZE Then Raise New TARException(ERR_MISALIGNED)
		    WriteTo.Write(block)
		  Loop
		  
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
		  Dim header As New MemoryBlock(BLOCK_SIZE)
		  If Path.Len > 100 Then
		    header.StringValue(156, 1) = "L" ' long name
		    header.StringValue(124, 12) = Oct(DataLength)
		    header.StringValue(0, 100) = "././@LongLink"
		    WriteBlocks(WriteTo, header)
		    WriteBlocks(WriteTo, Path)
		    header = New MemoryBlock(BLOCK_SIZE)
		    header.StringValue(0, 100) = Left(Path, 100)
		  Else
		    header.StringValue(0, 100) = Path
		  End If
		  header.StringValue(100, 8) = PermissionsToMode(Mode)
		  header.StringValue(108, 8) = Oct(Owner)
		  header.StringValue(116, 8) = Oct(Group)
		  header.StringValue(124, 12) = Oct(DataLength)
		  'header.StringValue(136, 12) = ModTime
		  
		  
		  header.StringValue(156, 1) = "0"
		  'header.StringValue(157, 100) = LinkName
		  header.StringValue(148, 8) = Oct(GetChecksum(header))
		  
		  WriteBlocks(WriteTo, header)
		  If Data <> Nil Then WriteBlocks(WriteTo, Data)
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mEntries As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Integer
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
