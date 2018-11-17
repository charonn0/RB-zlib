#tag Class
Protected Class TARException
Inherits RuntimeException
	#tag Method, Flags = &h1000
		Sub Constructor(ErrorCode As Integer)
		  Me.ErrorNumber = ErrorCode
		  
		  Select Case ErrorCode
		  Case ERR_END_ARCHIVE
		    Me.Message = "The archive contains no further entries."
		  Case ERR_INVALID_ENTRY
		    Me.Message = "The archive entry is corrupt."
		  Case ERR_MISALIGNED
		    Me.Message = "The archive is corrupt."
		  Case ERR_CHECKSUM_MISMATCH
		    Me.Message = "The archive entry failed verification."
		  Case ERR_INVALID_NAME
		    Me.Message = "The archive entry has an illegal file name."
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
