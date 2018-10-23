#tag Class
Private Class bz2Engine
	#tag Method, Flags = &h0
		Function Avail_In() As UInt32
		  Return bzstruct.avail_in
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Avail_Out() As UInt32
		  Return bzstruct.avail_out
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor()
		  If Not BZip2.IsAvailable Then Raise New PlatformNotSupportedException
		  
		  bzstruct.Alloc = Nil
		  bzstruct.Free = Nil
		  bzstruct.Opaque = Nil
		  bzstruct.Avail_In = 0
		  bzstruct.Next_In = Nil
		  bzstruct.Avail_Out = 0
		  bzstruct.Next_Out = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Total_In() As UInt32
		  Return BitOr(ShiftLeft(bzstruct.Total_In_High, 32, 64), bzstruct.Total_In_Low)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Total_Out() As UInt32
		  Return BitOr(ShiftLeft(bzstruct.Total_Out_High, 32, 64), bzstruct.Total_Out_Low)
		End Function
	#tag EndMethod


	#tag Property, Flags = &h1
		Protected bzstruct As bz_stream
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return bzstruct.State <> Nil
			End Get
		#tag EndGetter
		IsOpen As Boolean
	#tag EndComputedProperty

	#tag Property, Flags = &h1
		Protected mDictionary As MemoryBlock
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
			Name="IsOpen"
			Group="Behavior"
			Type="Boolean"
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
