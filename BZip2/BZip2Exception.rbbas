#tag Class
Protected Class BZip2Exception
Inherits RuntimeException
	#tag Method, Flags = &h1000
		Sub Constructor(ErrorCode As Integer)
		  Me.ErrorNumber = ErrorCode
		  
		  Select Case ErrorCode
		  Case BZ_CONFIG_ERROR
		    Me.Message = "The BZip2 library was not compiled for the currect CPU architecture."
		  Case BZ_SEQUENCE_ERROR
		    Me.Message = "An invalid sequence of BZip2 commands was used."
		  Case BZ_PARAM_ERROR
		    Me.Message = "A parameter to a BZip2 function is invalid or out of range."
		  Case BZ_MEM_ERROR
		    Me.Message = "There is insufficient available memory to perform the requested operation."
		  Case BZ_DATA_ERROR
		    Me.Message = "The decompression buffer contains invalid or incomplete BZip2 data."
		  Case BZ_DATA_ERROR_MAGIC
		    Me.Message = "The data do not appear to be a BZip2 stream."
		  Case BZ_IO_ERROR
		    Me.Message = "Error while reading or writing a file."
		  Case BZ_UNEXPECTED_EOF
		    Me.Message = "The decompression stream ended unexpectedly."
		  Case BZ_OUTBUFF_FULL
		    Me.Message = "The output buffer can contain no further data."
		  Else
		    Me.Message = "Unknown error"
		  End Select
		End Sub
	#tag EndMethod


	#tag ViewBehavior
		#tag ViewProperty
			Name="ErrorNumber"
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
			InheritedFrom="RuntimeException"
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
			Name="Message"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
			InheritedFrom="RuntimeException"
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
