#tag Class
Private Class FlateEngine
	#tag Method, Flags = &h0
		Function Avail_In() As UInt32
		  Return zstream.avail_in
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Avail_Out() As UInt32
		  Return zstream.avail_out
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Checksum() As UInt32
		  If IsOpen Then Return zstream.adler
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function IsOpen() As Boolean
		  Return zstream.zfree <> Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Total_In() As UInt32
		  Return zstream.total_in
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Total_Out() As UInt32
		  Return zstream.total_out
		End Function
	#tag EndMethod


	#tag Property, Flags = &h1
		Protected mDictionary As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mLevel As Integer = Z_DEFAULT_COMPRESSION
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mStrategy As Integer = Z_DEFAULT_STRATEGY
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected zstream As z_stream
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
