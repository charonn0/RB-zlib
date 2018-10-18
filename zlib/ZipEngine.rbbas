#tag Class
Private Class ZipEngine
	#tag Method, Flags = &h1
		Protected Sub Constructor(ZipStream As BinaryStream)
		  mStream = ZipStream
		  ZipStream.LittleEndian = True
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Shared Function ConvertDate(NewDate As Date) As Pair
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

	#tag Method, Flags = &h1
		Protected Shared Function ConvertDate(Dt As UInt16, tm As UInt16) As Date
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

	#tag Method, Flags = &h1
		Protected Shared Sub GetChildren(Root As FolderItem, ByRef Results() As FolderItem)
		  Dim c As Integer = Root.Count
		  For i As Integer = 1 To c
		    Dim item As FolderItem = Root.TrueItem(i)
		    Results.Append(item)
		    If item.Directory Then GetChildren(item, Results)
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Shared Function GetRelativePath(Root As FolderItem, Item As FolderItem) As String
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

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Shared Function SeekSignature(Stream As BinaryStream, Signature As UInt32) As Boolean
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


	#tag Property, Flags = &h1
		Protected mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mStream As BinaryStream
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mZipStream As zlib.ZStream
	#tag EndProperty


	#tag Constant, Name = FLAG_DESCRIPTOR, Type = Double, Dynamic = False, Default = \"8", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = FLAG_ENCRYPTED, Type = Double, Dynamic = False, Default = \"1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = FLAG_NAME_ENCODING, Type = Double, Dynamic = False, Default = \"2048", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = MAX_COMMENT_SIZE, Type = Double, Dynamic = False, Default = \"&hFFFF", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = MAX_EXTRA_SIZE, Type = Double, Dynamic = False, Default = \"&hFFFF", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = MAX_NAME_SIZE, Type = Double, Dynamic = False, Default = \"&hFFFF", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = MIN_ARCHIVE_SIZE, Type = Double, Dynamic = False, Default = \"ZIP_DIRECTORY_FOOTER_SIZE\r", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ZIP_DIRECTORY_FOOTER_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h06054b50", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ZIP_DIRECTORY_FOOTER_SIZE, Type = Double, Dynamic = False, Default = \"22", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ZIP_DIRECTORY_HEADER_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h02014b50", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ZIP_DIRECTORY_HEADER_SIZE, Type = Double, Dynamic = False, Default = \"46", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ZIP_ENTRY_FOOTER_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h08074b50", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ZIP_ENTRY_FOOTER_SIZE, Type = Double, Dynamic = False, Default = \"16", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ZIP_ENTRY_HEADER_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h04034b50", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ZIP_ENTRY_HEADER_SIZE, Type = Double, Dynamic = False, Default = \"30", Scope = Protected
	#tag EndConstant


	#tag Structure, Name = ZipDirectoryFooter, Flags = &h1
		Signature As UInt32
		  ThisDisk As UInt16
		  FirstDisk As UInt16
		  ThisRecordCount As UInt16
		  TotalRecordCount As UInt16
		  DirectorySize As UInt32
		  Offset As UInt32
		CommentLength As UInt16
	#tag EndStructure

	#tag Structure, Name = ZipDirectoryHeader, Flags = &h1
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

	#tag Structure, Name = ZipEntryFooter, Flags = &h1
		Signature As UInt32
		  CRC32 As UInt32
		  CompressedSize As UInt32
		UncompressedSize As UInt32
	#tag EndStructure

	#tag Structure, Name = ZipEntryHeader, Flags = &h1
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
