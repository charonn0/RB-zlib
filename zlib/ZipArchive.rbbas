#tag Class
Protected Class ZipArchive
	#tag Method, Flags = &h0
		Sub Close()
		  If mArchiveStream <> Nil Then
		    mArchiveStream.Close
		    mArchiveStream = Nil
		    mIndex = -1
		    mDirectoryHeaderOffset = 0
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(ArchiveStream As BinaryStream)
		  mArchiveStream = ArchiveStream
		  mArchiveStream.LittleEndian = True
		  If mArchiveStream.Length < 22 Or Not Me.Reset(0) Then Raise New zlibException(ERR_NOT_ZIPPED)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CurrentExtra() As MemoryBlock
		  If mIndex > -1 Then Return mCurrentExtra
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CurrentIndex() As Integer
		  Return mIndex
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CurrentModificationDate() As Date
		  If mIndex = -1 Then Return Nil
		  
		  Dim h, m, s, dom, mon, year As Integer
		  Dim dt, tm As UInt16
		  tm = mCurrentFile.ModTime
		  dt = mCurrentFile.ModDate
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
		Function CurrentName() As String
		  If mIndex > -1 Then Return mCurrentName
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CurrentSize() As Integer
		  If mIndex > -1 Then Return mCurrentFile.CompressedSize Else Return -1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CurrentUncompressedSize() As Integer
		  If mIndex > -1 Then Return mCurrentFile.UncompressedSize Else Return -1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  Me.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MoveNext(ExtractTo As FolderItem, Overwrite As Boolean) As Boolean
		  ExtractTo = CreateTree(ExtractTo, mCurrentName)
		  Dim bs As BinaryStream
		  If Not ExtractTo.Directory Then bs = BinaryStream.Create(ExtractTo, Overwrite)
		  Return Me.MoveNext(bs)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MoveNext(ExtractTo As Writeable) As Boolean
		  If mDirectoryHeaderOffset = 0 Then Raise New IOException
		  ' extract the current item
		  If ExtractTo <> Nil Then
		    If mCurrentFile.UncompressedSize = 0 Then ' Directory
		      Return True
		    ElseIf mCurrentFile.Method = 0 Then ' not compressed
		      ExtractTo.Write(mArchiveStream.Read(mCurrentFile.CompressedSize))
		    ElseIf mCurrentFile.Method = &h08 Then ' deflated
		      Dim data As MemoryBlock = mArchiveStream.Read(mCurrentFile.CompressedSize)
		      Dim z As New ZStream(data)
		      ExtractTo.Write(z.ReadAll)
		    Else
		      mLastError = ERR_NOT_ZIPPED
		      Return False
		    End If
		  Else
		    mArchiveStream.Position = mArchiveStream.Position + mCurrentFile.CompressedSize
		  End If
		  
		  ' read the next entry header
		  If mArchiveStream.Position >= mDirectoryHeaderOffset Then
		    mLastError = ERR_END_ARCHIVE
		    Return False
		  End If
		  mIndex = mIndex + 1
		  mCurrentFile.StringValue(True) = mArchiveStream.Read(mCurrentFile.Size)
		  If mCurrentFile.Signature <> FILE_SIGNATURE Then
		    mLastError = ERR_INVALID_ENTRY
		    Return False
		  Else
		    mCurrentName = mArchiveStream.Read(mCurrentFile.FilenameLength)
		    mCurrentExtra = mArchiveStream.Read(mCurrentFile.ExtraLength)
		    Dim sig As UInt32 = mArchiveStream.ReadUInt32
		    If sig = FILE_FOOTER_SIGNATURE Or (mCurrentFile.CompressedSize = 0 And mCurrentFile.Method <> 0) Then
		      If sig <> FILE_FOOTER_SIGNATURE Then mArchiveStream.Position = mArchiveStream.Position - 4
		      Dim footer As ZipFileFooter
		      footer.StringValue(True) = mArchiveStream.Read(footer.Size)
		      mCurrentFile.CompressedSize = footer.ComressedSize
		      mCurrentFile.UncompressedSize = footer.UncompressedSize
		      Return True
		    Else
		      mArchiveStream.Position = mArchiveStream.Position - 4
		      Return True
		    End If
		  End If
		  Break
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Reset(Index As Integer = 0) As Boolean
		  mArchiveStream.Position = mArchiveStream.Length - 4
		  mDirectoryHeaderOffset = 0
		  Do Until mDirectoryHeaderOffset > 0
		    If mArchiveStream.ReadUInt32 = DIRECTORY_FOOTER_HEADER Then
		      mArchiveStream.Position = mArchiveStream.Position - 4
		      mDirectoryFooter.StringValue(True) = mArchiveStream.Read(mDirectoryFooter.Size)
		      mArchiveStream.Position = mDirectoryFooter.Offset
		      mDirectoryHeaderOffset = mArchiveStream.Position
		      mDirectoryHeader.StringValue(True) = mArchiveStream.Read(mDirectoryHeader.Size)
		      mArchiveName = mArchiveStream.Read(mDirectoryHeader.FilenameLength)
		      mExtraData = mArchiveStream.Read(mDirectoryHeader.ExtraLength)
		      mArchiveComment = mArchiveStream.Read(mDirectoryHeader.CommentLength)
		    Else
		      mArchiveStream.Position = mArchiveStream.Position - 5
		    End If
		  Loop Until mArchiveStream.Position < 22
		  
		  mIndex = -1
		  If mDirectoryHeaderOffset = 0 Then
		    mLastError = ERR_NOT_ZIPPED
		    Return False
		  End If
		  mArchiveStream.Position = mDirectoryHeader.Offset
		  Do
		    If Not Me.MoveNext(Nil) Then Return False
		    mIndex = mIndex + 1
		  Loop Until mIndex >= Index
		  Return True
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
		Private mCurrentExtra As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentFile As ZipFileHeader
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentName As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDirectoryFooter As ZipDirectoryFooter
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDirectoryHeader As ZipDirectoryHeader
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDirectoryHeaderOffset As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mExtraData As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mIndex As Integer = -1
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSpanOffset As UInt32 = 0
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
