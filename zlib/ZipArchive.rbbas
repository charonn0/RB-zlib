#tag Class
Protected Class ZipArchive
	#tag Method, Flags = &h0
		Sub Constructor(ArchiveStream As BinaryStream)
		  mArchiveStream = ArchiveStream
		  mArchiveStream.LittleEndian = True
		  If mArchiveStream.Length < 22 Then Raise New zlibException(ERR_NOT_ZIPPED)
		  
		  mArchiveStream.Position = mArchiveStream.Length - 4
		  Do Until mDirectoryOffset > 0
		    If mArchiveStream.ReadUInt32 = DIRECTORY_FOOTER_HEADER Then
		      mArchiveStream.Position = mArchiveStream.Position - 4
		      mDirectoryOffset = mArchiveStream.Position
		      mDirectoryFooter.StringValue(True) = mArchiveStream.Read(mDirectoryFooter.Size)
		      mArchiveStream.Position = mDirectoryFooter.Offset
		      mDirectoryHeader.StringValue(True) = mArchiveStream.Read(mDirectoryHeader.Size)
		      mArchiveName = mArchiveStream.Read(mDirectoryHeader.FilenameLength)
		      mExtraData = mArchiveStream.Read(mDirectoryHeader.ExtraLength)
		      mArchiveComment = mArchiveStream.Read(mDirectoryHeader.CommentLength)
		      'mDirectoryOffset = mDirectoryHeader.Offset
		    Else
		      mArchiveStream.Position = mArchiveStream.Position - 5
		    End If
		  Loop Until mArchiveStream.Position < 22
		  
		  If mDirectoryOffset = 0 Then Raise New zlibException(ERR_NOT_ZIPPED)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Count() As UInt32
		  Dim header As FileHeader
		  Dim name, extra As String
		  Dim i As UInt32
		  Do Until Not GetEntryHeader(i, header, name, extra)
		    i = i + 1
		  Loop
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetEntry(Index As Integer) As zlib.ZStream
		  Dim header As FileHeader
		  Dim name, extra As String
		  If Not GetEntryHeader(Index, header, name, extra) Then Return Nil
		  If header.Method <> &h08 Then
		    mLastError = ERR_UNSUPPORTED_COMPRESSION
		    Return Nil
		  End If
		  Dim mb As MemoryBlock = mArchiveStream.Read(header.CompressedSize)
		  Return New zlib.ZStream(mb)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GetEntryHeader(Index As Integer, ByRef Header As FileHeader, ByRef FileName As String, ByRef Extra As String) As Boolean
		  If mDirectoryOffset = 0 Then Raise New IOException
		  mArchiveStream.Position = mDirectoryHeader.Offset
		  Dim i As Integer
		  Do Until mArchiveStream.Position >= mDirectoryOffset
		    header.StringValue(True) = mArchiveStream.Read(header.Size)
		    If header.Signature <> FILE_SIGNATURE Then 
		      mLastError = ERR_INVALID_ENTRY
		      Return False
		    Else
		      FileName = mArchiveStream.Read(header.FilenameLength)
		      Extra = mArchiveStream.Read(header.ExtraLength)
		      If i = Index Then Return True
		    End If
		    i = i + 1
		  Loop
		  mLastError = ERR_END_ARCHIVE
		  Return False
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetEntryModificationDate(Index As Integer) As Date
		  Dim header As FileHeader
		  Dim name, extra As String
		  If Not GetEntryHeader(Index, header, name, extra) Then Return Nil
		  Dim h, m, s, dom, mon, year As Integer
		  Dim dt, tm As UInt16
		  tm = header.ModTime
		  dt = header.ModDate
		  h = ShiftRight(tm, 11)
		  m = ShiftRight(tm, 5) And &h3F
		  s = (tm And &h1F) * 2
		  dom = dt And &h1F
		  mon = ShiftRight(dt, 5) And &h0F
		  year = (ShiftRight(dt, 9) And &h7F) + 1980
		  
		  Return New Date(year, mon, dom, h, m, s)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetEntryName(Index As Integer) As String
		  Dim header As FileHeader
		  Dim name, extra As String
		  If Not GetEntryHeader(Index, header, name, extra) Then Return ""
		  Return name
		End Function
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mArchiveComment As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mArchiveName As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mArchiveStream As BinaryStream
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDirectoryFooter As DirectoryFooter
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDirectoryHeader As DirectoryHeader
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDirectoryOffset As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mExtraData As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSpanOffset As UInt32 = 0
	#tag EndProperty


	#tag Constant, Name = DIRECTORY_FOOTER_HEADER, Type = Double, Dynamic = False, Default = \"&h504B0506", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = DIRECTORY_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h504B0102", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_END_ARCHIVE, Type = Double, Dynamic = False, Default = \"-202", Scope = Public
	#tag EndConstant

	#tag Constant, Name = ERR_INVALID_ENTRY, Type = Double, Dynamic = False, Default = \"-201", Scope = Public
	#tag EndConstant

	#tag Constant, Name = ERR_NOT_ZIPPED, Type = Double, Dynamic = False, Default = \"-200", Scope = Public
	#tag EndConstant

	#tag Constant, Name = ERR_UNSUPPORTED_COMPRESSION, Type = Double, Dynamic = False, Default = \"-203", Scope = Public
	#tag EndConstant

	#tag Constant, Name = FILE_FOOTER_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h504B0708", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = FILE_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h04034B50", Scope = Protected
	#tag EndConstant


	#tag Structure, Name = DirectoryFooter, Flags = &h1
		Signature As UInt32
		  ThisDisk As UInt16
		  FirstDisk As UInt16
		  ThisRecordCount As UInt16
		  TotalRecordCount As UInt16
		  DirectorySize As UInt32
		  Offset As UInt32
		CommentLength As UInt16
	#tag EndStructure

	#tag Structure, Name = DirectoryHeader, Flags = &h1
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

	#tag Structure, Name = FileFooter, Flags = &h1
		Signature As Int32
		  CRC32 As UInt32
		  ComressedSize As UInt32
		UncompressedSize As UInt32
	#tag EndStructure

	#tag Structure, Name = FileHeader, Flags = &h1
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
