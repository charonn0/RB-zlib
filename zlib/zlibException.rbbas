#tag Class
Protected Class zlibException
Inherits RuntimeException
	#tag Method, Flags = &h1000
		Sub Constructor(ErrorCode As Integer)
		  Me.ErrorNumber = ErrorCode
		  
		  Select Case ErrorCode
		  Case zlib.ERR_END_ARCHIVE
		    Me.Message = "The archive contains no additional entries."
		  Case zlib.ERR_INVALID_ENTRY
		    Me.Message = "The archive entry is corrupt."
		  Case zlib.ERR_NOT_ZIPPED
		    Me.Message = "The archive is not zipped."
		  Case zlib.ERR_UNSUPPORTED_COMPRESSION
		    Me.Message = "The archive entry uses a non-standard compression algorithm."
		  Else
		    If zlib.IsAvailable Then
		      Dim err As MemoryBlock = zlib.zError(ErrorCode)
		      Try
		        #pragma BreakOnExceptions Off
		        Me.Message = err.CString(0)
		      Catch
		        Me.Message = "Unknown error"
		      End Try
		    End If
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
