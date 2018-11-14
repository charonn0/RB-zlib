#tag Class
Protected Class TarReader
	#tag Method, Flags = &h0
		Sub Close()
		  If mStream <> Nil Then mStream = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(TARStream As Readable)
		  ' Constructs a TARStream from any Readable object.
		  mStream = TARStream
		  If Not ReadHeader() Then Raise New TARException(ERR_MISALIGNED)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MoveNext(ExtractTo As Writeable = Nil) As Boolean
		  ' Extracts the current entry into ExtractTo, and queues the next extry.
		  
		  Return ReadEntry(ExtractTo) And ReadHeader()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function Read(Count As Integer) As MemoryBlock
		  Dim data As MemoryBlock = mStream.Read(Count)
		  mStreamPosition = mStreamPosition + data.Size
		  Return data
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ReadBlock() As MemoryBlock
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
		  mCurrentChecksum = header.HeaderChecksum
		  'mCurrentLinkIndicator = header.HeaderLinkIndicator
		  mCurrentLinkName = header.HeaderLinkName
		  
		  If CurrentName = "" Then mLastError = ERR_INVALID_NAME
		  If mStream.EOF Then mLastError = ERR_END_ARCHIVE
		  Return mLastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ReadLongName(NameLength As Integer) As String
		  mLastError = 0
		  Dim name As New MemoryBlock(0)
		  Do Until name.Size >= NameLength
		    name = name + ReadBlock()
		  Loop
		  
		  Dim diff As Integer = name.Size - NameLength
		  Return name.LeftB(name.LenB - diff)
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mCurrentChecksum
			End Get
		#tag EndGetter
		CurrentChecksum As UInt32
	#tag EndComputedProperty

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
		#tag Setter
			Set
			  mCurrentType = value
			End Set
		#tag EndSetter
		CurrentType As String
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mCurrentChecksum As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentGroup As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentLinkIndicator As Boolean
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
		Private mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mStream As Readable
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mStreamPosition As UInt64
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
