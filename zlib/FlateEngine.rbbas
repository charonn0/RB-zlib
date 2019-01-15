#tag Class
Private Class FlateEngine
	#tag Method, Flags = &h0
		Function Avail_In() As UInt32
		  Select Case Me.Size
		  Case STRUCT_32_1
		    Return zstruct.z_stream_32_1.avail_in
		  Case STRUCT_32_8
		    Return zstruct.z_stream_32_8.avail_in
		  Case STRUCT_64_8
		    Return zstruct.z_stream_64_8.avail_in
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Avail_In(Assigns avail As UInt32)
		  Select Case Me.Size
		  Case STRUCT_32_1
		    zstruct.z_stream_32_1.avail_in = avail
		  Case STRUCT_32_8
		    zstruct.z_stream_32_8.avail_in = avail
		  Case STRUCT_64_8
		    zstruct.z_stream_64_8.avail_in = avail
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Avail_Out() As UInt32
		  Select Case Me.Size
		  Case STRUCT_32_1
		    Return zstruct.z_stream_32_1.avail_out
		  Case STRUCT_32_8
		    Return zstruct.z_stream_32_8.avail_out
		  Case STRUCT_64_8
		    Return zstruct.z_stream_64_8.avail_out
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Avail_Out(Assigns avail As UInt32)
		  Select Case Me.Size
		  Case STRUCT_32_1
		    zstruct.z_stream_32_1.avail_out = avail
		  Case STRUCT_32_8
		    zstruct.z_stream_32_8.avail_out = avail
		  Case STRUCT_64_8
		    zstruct.z_stream_64_8.avail_out = avail
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Checksum() As UInt32
		  Select Case Me.Size
		  Case STRUCT_32_1
		    Return zstruct.z_stream_32_1.adler
		  Case STRUCT_32_8
		    Return zstruct.z_stream_32_8.adler
		  Case STRUCT_64_8
		    Return zstruct.z_stream_64_8.adler
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor()
		  If Not zlib.IsAvailable Then Raise New PlatformNotSupportedException
		  Dim sz As Integer = GetStructSize()
		  mData = New MemoryBlock(sz)
		  zstruct = mData
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function GetStructSize() As Integer
		  Static size As Integer
		  If size = 0 And zlib.IsAvailable Then
		    Dim struct As New MemoryBlock(STRUCT_64_8)
		    If deflateInit_(struct, 6, "1.2.8" + Chr(0), STRUCT_32_1) = 0 Then
		      Call deflateEnd(struct)
		      size = STRUCT_32_1
		    ElseIf deflateInit_(struct, 6, "1.2.8" + Chr(0), STRUCT_32_8) = 0 Then
		      Call deflateEnd(struct)
		      size = STRUCT_32_8
		    ElseIf deflateInit_(struct, 6, "1.2.8" + Chr(0), STRUCT_64_8) = 0 Then
		      Call deflateEnd(struct)
		      size = STRUCT_64_8
		    End If
		  End If
		  
		  Return size
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Msg() As MemoryBlock
		  Dim msg As MemoryBlock
		  Select Case Me.Size
		  Case STRUCT_32_1
		    msg = zstruct.z_stream_32_1.msg
		  Case STRUCT_32_8
		    msg = zstruct.z_stream_32_8.msg
		  Case STRUCT_64_8
		    msg = zstruct.z_stream_64_8.msg
		  End Select
		  If msg <> Nil Then Return msg
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Next_In() As Ptr
		  Select Case Me.Size
		  Case STRUCT_32_1
		    Return zstruct.z_stream_32_1.next_in
		  Case STRUCT_32_8
		    Return zstruct.z_stream_32_8.next_in
		  Case STRUCT_64_8
		    Return zstruct.z_stream_64_8.next_in
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Next_In(Assigns Nxt As Ptr)
		  Select Case Me.Size
		  Case STRUCT_32_1
		    zstruct.z_stream_32_1.next_in = Nxt
		  Case STRUCT_32_8
		    zstruct.z_stream_32_8.next_in = Nxt
		  Case STRUCT_64_8
		    zstruct.z_stream_64_8.next_in = Nxt
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Next_Out() As Ptr
		  Select Case Me.Size
		  Case STRUCT_32_1
		    Return zstruct.z_stream_32_1.next_out
		  Case STRUCT_32_8
		    Return zstruct.z_stream_32_8.next_out
		  Case STRUCT_64_8
		    Return zstruct.z_stream_64_8.next_out
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Next_Out(Assigns Out As Ptr)
		  Select Case Me.Size
		  Case STRUCT_32_1
		    zstruct.z_stream_32_1.next_out = Out
		  Case STRUCT_32_8
		    zstruct.z_stream_32_8.next_out = Out
		  Case STRUCT_64_8
		    zstruct.z_stream_64_8.next_out = Out
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Total_In() As UInt32
		  Select Case Me.Size
		  Case STRUCT_32_1
		    Return zstruct.z_stream_32_1.total_in
		  Case STRUCT_32_8
		    Return zstruct.z_stream_32_8.total_in
		  Case STRUCT_64_8
		    Return zstruct.z_stream_64_8.total_in
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Total_Out() As UInt32
		  Select Case Me.Size
		  Case STRUCT_32_1
		    Return zstruct.z_stream_32_1.total_out
		  Case STRUCT_32_8
		    Return zstruct.z_stream_32_8.total_out
		  Case STRUCT_64_8
		    Return zstruct.z_stream_64_8.total_out
		  End Select
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Select Case Me.Size
			  Case STRUCT_32_1
			    Return zstruct.z_stream_32_1.data_type
			  Case STRUCT_32_8
			    Return zstruct.z_stream_32_8.data_type
			  Case STRUCT_64_8
			    Return zstruct.z_stream_64_8.data_type
			  End Select
			End Get
		#tag EndGetter
		DataType As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Select Case Me.Size
			  Case STRUCT_32_1
			    Return zstruct.z_stream_32_1.internal_state <> Nil
			  Case STRUCT_32_8
			    Return zstruct.z_stream_32_8.internal_state <> Nil
			  Case STRUCT_64_8
			    Return zstruct.z_stream_64_8.internal_state <> Nil
			  End Select
			End Get
		#tag EndGetter
		IsOpen As Boolean
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mData As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mDictionary As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mLastError As Integer
	#tag EndProperty

	#tag ComputedProperty, Flags = &h1
		#tag Getter
			Get
			  return mData.Size
			End Get
		#tag EndGetter
		Protected Size As Integer
	#tag EndComputedProperty

	#tag Property, Flags = &h1
		Protected zstruct As Ptr
	#tag EndProperty


	#tag Constant, Name = STRUCT_32_1, Type = Double, Dynamic = False, Default = \"56", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = STRUCT_32_8, Type = Double, Dynamic = False, Default = \"88", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = STRUCT_64_8, Type = Double, Dynamic = False, Default = \"112", Scope = Protected
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
