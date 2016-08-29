#tag Class
Protected Class ZipArchive
	#tag Method, Flags = &h0
		Sub Constructor(ArchiveStream As BinaryStream)
		  mArchiveStream = ArchiveStream
		  mArchiveStream.LittleEndian = True
		  If mArchiveStream.Length < 22 Then Raise New zlibException(ERR_NOT_ZIPPED)
		  
		  mArchiveStream.Position = mArchiveStream.Length - 4
		  Do Until mZipDirectoryHeaderOffset > 0
		    If mArchiveStream.ReadUInt32 = DIRECTORY_FOOTER_HEADER Then
		      mArchiveStream.Position = mArchiveStream.Position - 4
		      mZipDirectoryHeaderOffset = mArchiveStream.Position
		      mDirectoryFooter.StringValue(True) = mArchiveStream.Read(mDirectoryFooter.Size)
		      mArchiveStream.Position = mDirectoryFooter.Offset
		      mZipDirectoryHeader.StringValue(True) = mArchiveStream.Read(mZipDirectoryHeader.Size)
		      mArchiveName = mArchiveStream.Read(mZipDirectoryHeader.FilenameLength)
		      mExtraData = mArchiveStream.Read(mZipDirectoryHeader.ExtraLength)
		      mArchiveComment = mArchiveStream.Read(mZipDirectoryHeader.CommentLength)
		    Else
		      mArchiveStream.Position = mArchiveStream.Position - 5
		    End If
		  Loop Until mArchiveStream.Position < 22
		  
		  If mZipDirectoryHeaderOffset = 0 Then Raise New zlibException(ERR_NOT_ZIPPED)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Count() As UInt32
		  Dim header As ZipFileHeader
		  Dim name, extra As String
		  Dim i, offset As UInt32
		  Do Until Not GetEntryHeader(i, header, name, extra, offset)
		    i = i + 1
		  Loop
		  Return i
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetEntry(Index As Integer) As zlib.ZStream
		  Dim header As FileHeader
		  Dim name, extra As String
		  Dim offset As UInt32
		  If Not GetEntryHeader(Index, header, name, extra, offset) Then Return Nil
		  If header.Method <> &h08 Then
		    mLastError = ERR_UNSUPPORTED_COMPRESSION
		    Return Nil
		  End If
		  mArchiveStream.Position = offset
		  Dim mb As MemoryBlock = mArchiveStream.Read(header.CompressedSize)
		  Return New zlib.ZStream(mb)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GetEntryHeader(Index As Integer, ByRef Header As FileHeader, ByRef FileName As String, ByRef Extra As String, ByRef DataOffset As UInt32) As Boolean
		  If mDirectoryHeaderOffset = 0 Then Raise New IOException
		  mArchiveStream.Position = mDirectoryHeader.Offset
		  Dim i As Integer
		  Do Until mArchiveStream.Position >= mZipDirectoryHeaderOffset
		    header.StringValue(True) = mArchiveStream.Read(header.Size)
		    If header.Signature <> FILE_SIGNATURE Then
		      mLastError = ERR_INVALID_ENTRY
		      Return False
		    Else
		      FileName = mArchiveStream.Read(header.FilenameLength)
		      Extra = mArchiveStream.Read(header.ExtraLength)
		      DataOffset = mArchiveStream.Position
		      Dim sig As UInt32 = mArchiveStream.ReadUInt32
		      If sig = FILE_FOOTER_SIGNATURE Or (header.CompressedSize = 0 And header.Method <> 0) Then
		        If sig <> FILE_FOOTER_SIGNATURE Then mArchiveStream.Position = mArchiveStream.Position - 4
		        Dim footer As FileFooter
		        footer.StringValue(True) = mArchiveStream.Read(FileFooter.Size)
		        header.CompressedSize = footer.ComressedSize
		        header.UncompressedSize = footer.UncompressedSize
		      Else
		        mArchiveStream.Position = mArchiveStream.Position - 4
		      End If
		      mArchiveStream.Position = DataOffset + header.CompressedSize
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
		  Dim offset As UInt32
		  If Not GetEntryHeader(Index, header, name, extra, offset) Then Return Nil
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
		  Dim offset As UInt32
		  If Not GetEntryHeader(Index, header, name, extra, offset) Then Return ""
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
		Private mDirectoryFooter As ZipDirectoryFooter
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

	#tag Property, Flags = &h21
		Private mZipDirectoryHeader As ZipDirectoryHeader
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mZipDirectoryHeaderOffset As UInt32
	#tag EndProperty


	#tag Constant, Name = DIRECTORY_FOOTER_HEADER, Type = Double, Dynamic = False, Default = \"&h06054b50", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = DIRECTORY_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h02014b50", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_END_ARCHIVE, Type = Double, Dynamic = False, Default = \"-202", Scope = Public
	#tag EndConstant

	#tag Constant, Name = ERR_INVALID_ENTRY, Type = Double, Dynamic = False, Default = \"-201", Scope = Public
	#tag EndConstant

	#tag Constant, Name = ERR_NOT_ZIPPED, Type = Double, Dynamic = False, Default = \"-200", Scope = Public
	#tag EndConstant

	#tag Constant, Name = ERR_UNSUPPORTED_COMPRESSION, Type = Double, Dynamic = False, Default = \"-203", Scope = Public
	#tag EndConstant

	#tag Constant, Name = FILE_FOOTER_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h08074b50", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = FILE_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h04034b50", Scope = Protected
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
End Class
#tag EndClass
