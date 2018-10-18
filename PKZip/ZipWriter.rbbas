#tag Class
Protected Class ZipWriter
	#tag Method, Flags = &h0
		Function AppendEntry(Entry As FolderItem, Optional RelativeRoot As FolderItem) As String
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
		  Dim paths() As String
		  Dim lengths() As UInt32
		  Dim sources() As Readable
		  Dim modtimes() As Date
		  Dim comments() As String
		  Dim extras() As MemoryBlock
		  Dim dirstatus() As Boolean
		  CollapseTree(mEntries, paths, lengths, modtimes, sources, comments, extras, dirstatus)
		  
		  Dim directory() As ZipDirectoryHeader
		  
		  Dim c As Integer = UBound(paths)
		  For i As Integer = 0 To c
		    Dim length As UInt32 = lengths(i)
		    If Length > &hFFFFFFFF Then Raise New ZipException(ERR_TOO_LARGE)
		    Dim path As String = paths(i)
		    path = ConvertEncoding(path, Encodings.UTF8)
		    Dim source As Readable = sources(i)
		    Dim modtime As Date = modtimes(i)
		    If dirstatus(i) And Right(path, 1) <> "/" Then path = path + "/"
		    Dim dirheader As ZipDirectoryHeader
		    WriteEntryHeader(WriteTo, path, length, source, modtime, CompressionLevel, dirheader)
		    directory.Append(dirheader)
		  Next
		  
		  WriteDirectory(WriteTo, directory, paths, comments, extras, ArchiveComment)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  mEntries = New Dictionary("$n":"$ROOT", "$p":Nil, "$d":True)', "$a":"")
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
		  d.Value("$c") = Comment
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h0
		ArchiveComment As String
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
