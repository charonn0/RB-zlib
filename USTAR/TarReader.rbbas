#tag Class
Protected Class TarReader
	#tag Method, Flags = &h0
		Sub Close()
		  ' Releases all resources. The TarReader may not be used after calling this method.
		  
		  If mStream <> Nil Then mStream = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(TarStream As FolderItem)
		  ' Construct a TarReader from the TarStream file.
		  
		  #If USE_ZLIB Then
		    If TarStream.IsGZipped Then
		      Me.Constructor(zlib.ZStream.Open(TarStream))
		      Return
		    Else
		  #endif
		  
		  Me.Constructor(BinaryStream.Open(TarStream))
		  
		  #If USE_ZLIB Then
		    End If
		  #endif
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(TarData As MemoryBlock)
		  ' Construct a TarReader from the TarData.
		  
		  mData = TarData
		  Me.Constructor(New BinaryStream(mData))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(TARStream As Readable)
		  ' Constructs a TARStream from any Readable object.
		  mStream = TARStream
		  If Not ReadHeader() Then Raise New TARException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Int32
		  ' The most recent error while reading the archive. Check this value if MoveNext() returns False.
		  
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MoveNext(ExtractTo As Writeable) As Boolean
		  ' Extract the current item and then read the metadata of the next item, if any.
		  ' If ExtractTo is Nil then the current item is skipped.
		  ' Returns True if the current item was extracted and the next item is ready. Check LastError
		  ' for details if this method returns False; in particulur the error ERR_END_ARCHIVE
		  ' means that extraction was successful but there are no further entries.
		  
		  Return ReadEntry(ExtractTo) And ReadHeader()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function Read(Count As Integer) As MemoryBlock
		  ' Reads from the stream while keeping track of the position in the uncompressed stream
		  
		  Dim data As MemoryBlock = mStream.Read(Count)
		  mStreamPosition = mStreamPosition + data.Size
		  Return data
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ReadBlock() As MemoryBlock
		  ' TAR files consist of a sequence of equally-sized blocks. This method reads
		  ' one  block from the stream and ensures that the stream.position is a multiple 
		  ' of the block size.
		  
		  If mStreamPosition Mod BLOCK_SIZE <> 0 Then
		    mLastError = ERR_MISALIGNED
		    Return Nil
		  End If
		  
		  Dim data As MemoryBlock = Me.Read(BLOCK_SIZE)
		  If data.Size < BLOCK_SIZE Then data.Size = BLOCK_SIZE
		  If data.Size > BLOCK_SIZE Then
		    mLastError = ERR_INVALID_ENTRY
		    Return Nil
		  End If
		  
		  Return data
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ReadEntry(WriteTo As Writeable) As Boolean
		  ' Decompress the current item into the WriteTo parameter.
		  ' Returns True on success; check LastError if it returns False.
		  
		  Dim total As UInt64
		  Do Until total = CurrentFileSize
		    Dim data As MemoryBlock = ReadBlock()
		    If total + data.Size > CurrentFileSize Then
		      Dim diff As UInt64 = total + data.Size - CurrentFileSize
		      data.Size = data.Size - diff
		    End If
		    total = total + data.Size
		    If WriteTo <> Nil Then WriteTo.Write(data)
		  Loop
		  
		  Return mLastError = 0
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ReadHeader() As Boolean
		  ' Read the next entry's header into the CurrentName, CurrentFileSize, etc. properties.
		  ' Returns True on success; check LastError if it returns False.
		  
		  mLastError = 0
		  Dim header As MemoryBlock = ReadBlock()
		  mCurrentType = header.HeaderType
		  Select Case mCurrentType
		  Case LONGNAMETYPE ' long name
		    mCurrentName = ReadLongName(header.HeaderFilesize)
		    header = ReadBlock()
		    mCurrentType = header.HeaderType
		  Case XGLTYPE, XHDTYPE ' PAX header, skip
		    mCurrentSize = header.HeaderFilesize
		    Return ReadEntry(Nil) And ReadHeader()
		  Else
		    mCurrentName = header.HeaderName
		    mCurrentType = header.HeaderType
		  End Select
		  mCurrentMode = header.HeaderMode
		  mCurrentOwner = header.HeaderOwner
		  mCurrentGroup = header.HeaderGroup
		  mCurrentSize = header.HeaderFilesize
		  mCurrentModTime = header.HeaderModDate
		  mCurrentLinkName = header.HeaderLinkName
		  
		  If CurrentName = "" Then mLastError = ERR_INVALID_NAME
		  If mStream.EOF Or header.HeaderChecksum = 0 Then
		    mLastError = ERR_END_ARCHIVE
		  ElseIf ValidateChecksums And header.HeaderChecksum <> GetChecksum(header) Then
		    mLastError = ERR_CHECKSUM_MISMATCH
		  End If
		  
		  Return mLastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ReadLongName(NameLength As Integer) As String
		  ' Reads the long file name encoded in one or more data blocks.
		  
		  mLastError = 0
		  Dim name As New MemoryBlock(0)
		  Do Until name.Size >= NameLength
		    name = name + ReadBlock()
		  Loop
		  
		  Dim diff As Integer = name.Size - NameLength
		  Return name.LeftB(name.Size - diff)
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mCurrentSize
			End Get
		#tag EndGetter
		CurrentFileSize As UInt64
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mCurrentGroup
			End Get
		#tag EndGetter
		CurrentGroup As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mCurrentMode
			End Get
		#tag EndGetter
		CurrentMode As Permissions
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mCurrentModTime
			End Get
		#tag EndGetter
		CurrentModificationDate As Date
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mCurrentName
			End Get
		#tag EndGetter
		CurrentName As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mCurrentOwner
			End Get
		#tag EndGetter
		CurrentOwner As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mCurrentType
			End Get
		#tag EndGetter
		CurrentType As String
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mCurrentGroup As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentLinkName As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentMode As Permissions
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentModTime As Date
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentName As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentOwner As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentSize As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentType As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mData As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Int32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mStream As Readable
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mStreamPosition As UInt64
	#tag EndProperty

	#tag Property, Flags = &h0
		ValidateChecksums As Boolean = True
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="CurrentGroup"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="CurrentName"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="CurrentOwner"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="CurrentType"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
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
