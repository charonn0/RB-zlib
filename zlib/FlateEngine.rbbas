#tag Class
Private Class FlateEngine
	#tag Method, Flags = &h0
		Function Avail_In() As UInt32
		  #If Target32Bit Then
		    Return zstruct.avail_in
		  #Else
		    Return zstruct64.avail_in
		  #Endif
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Avail_In(Assigns avail As UInt32)
		  #If Target32Bit Then
		    zstruct.avail_in = avail
		  #Else
		    zstruct64.avail_in = avail
		  #Endif
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Avail_Out() As UInt32
		  #If Target32Bit Then
		    Return zstruct.avail_out
		  #Else
		    Return zstruct64.avail_out
		  #Endif
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Avail_Out(Assigns avail As UInt32)
		  #If Target32Bit Then
		    zstruct.avail_out = avail
		  #Else
		    zstruct64.avail_out = avail
		  #Endif
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Checksum() As UInt32
		  #If Target32Bit Then
		    If IsOpen Then Return zstruct.adler
		  #Else
		    If IsOpen Then Return zstruct64.adler
		  #Endif
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor()
		  If Not zlib.IsAvailable Then Raise New PlatformNotSupportedException
		  #If Target32Bit Then
		    zstruct.zalloc = Nil
		    zstruct.zfree = Nil
		    zstruct.opaque = Nil
		    zstruct.avail_in = 0
		    zstruct.next_in = Nil
		    zstruct.avail_out = 0
		    zstruct.next_out = Nil
		  #Else
		    zstruct64.zalloc = Nil
		    zstruct64.zfree = Nil
		    zstruct64.opaque = Nil
		    zstruct64.avail_in = 0
		    zstruct64.next_in = Nil
		    zstruct64.avail_out = 0
		    zstruct64.next_out = Nil
		  #Endif
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Msg() As MemoryBlock
		  #If Target32Bit Then
		    If zstruct.msg <> Nil Then Return zstruct.msg
		  #Else
		    If zstruct64.msg <> Nil Then Return zstruct64.msg
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Next_In() As Ptr
		  #If Target32Bit Then
		    Return zstruct.next_in
		  #Else
		    Return zstruct64.next_in
		  #Endif
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Next_In(Assigns Nxt As Ptr)
		  #If Target32Bit Then
		    zstruct.next_in = Nxt
		  #Else
		    zstruct64.next_in = Nxt
		  #Endif
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Next_Out() As Ptr
		  #If Target32Bit Then
		    Return zstruct.next_out
		  #Else
		    Return zstruct64.next_out
		  #Endif
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Next_Out(Assigns Out As Ptr)
		  #If Target32Bit Then
		    zstruct.next_out = out
		  #Else
		    zstruct64.next_out = out
		  #Endif
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Total_In() As UInt32
		  #If Target32Bit Then
		    Return zstruct.total_in
		  #Else
		    Return zstruct64.total_in
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Total_Out() As UInt32
		  #If Target32Bit Then
		    Return zstruct.total_out
		  #Else
		    Return zstruct64.total_out
		  #Endif
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  #If Target32Bit Then
			    Return zstruct.internal_state <> Nil
			  #Else
			    Return zstruct64.internal_state <> Nil
			  #Endif
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

	#tag Property, Flags = &h1
		Protected zstruct As z_stream
	#tag EndProperty

	#tag Property, Flags = &h1, CompatibilityFlags =  (TargetConsole and (Target64Bit)) or  (TargetWeb and (Target64Bit)) or  (TargetDesktop and (Target64Bit)) or  (TargetIOS and (Target64Bit))
		Protected zstruct64 As z_stream64
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
