#tag Class
Protected Class TarReader
	#tag Method, Flags = &h0
		Sub Constructor(TARStream As Readable)
		  mStream = TARStream
		  If Not ReadHeader() Then Raise New TARException(ERR_MISALIGNED)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Shared Function GetCheckSum(TarHeader As MemoryBlock) As UInt32
		  Dim chksum As UInt32
		  For i as Integer = 0 To 499
		    Try
		      If i = 148 Then
		        i = 156
		        chksum = chksum + UInt32(32 * 8) ' 8 spaces
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

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MoveNext(ExtractTo As Writeable = Nil) As Boolean
		  If Not ReadEntry(ExtractTo) Then Return False
		  Return ReadHeader()
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
		    WriteTo.Write(data)
		  Loop
		  
		  Return mLastError = 0
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ReadHeader() As Boolean
		  mLastError = 0
		  Dim header As MemoryBlock = ReadBlock()
		  If header.StringValue(156, 1) = "L" Then ' long name
		    Dim nmsz As Integer = Val("&o" + header.StringValue(124, 12).Trim)
		    mCurrentName = ReadLongName(nmsz)
		    header = ReadBlock()
		  Else
		    mCurrentName = header.StringValue(0, 100)
		  End If
		  mCurrentMode = header.StringValue(100, 8)
		  mCurrentOwner = header.StringValue(108, 8)
		  mCurrentGroup = header.StringValue(116, 8)
		  mCurrentSize = header.StringValue(124, 12)
		  mCurrentModTime = header.StringValue(136, 12)
		  mCurrentChecksum = header.StringValue(148, 8)
		  mCurrentLinkIndicator = header.StringValue(156, 1)
		  mCurrentLinkName = header.StringValue(157, 100).Trim
		  
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
			  Return Val("&o" + mCurrentChecksum.Trim)
			End Get
		#tag EndGetter
		CurrentChecksum As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Val("&o" + mCurrentSize.Trim)
			End Get
		#tag EndGetter
		CurrentFileSize As UInt64
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		CurrentGroup As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		CurrentMode As Permissions
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		CurrentModificationDate As Date
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return ReplaceAllB(mCurrentName, Chr(0), "")
			End Get
		#tag EndGetter
		CurrentName As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		CurrentOwner As Integer
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mCurrentChecksum As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentGroup As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentLinkIndicator As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentLinkName As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentMode As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentModTime As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentName As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentOwner As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentSize As String
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


	#tag Constant, Name = BLOCK_SIZE, Type = Double, Dynamic = False, Default = \"512", Scope = Private
	#tag EndConstant


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
		#tag EndViewProperty
		#tag ViewProperty
			Name="CurrentOwner"
			Group="Behavior"
			Type="Integer"
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
