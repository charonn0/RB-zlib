#tag Class
Protected Class zlibException
Inherits RuntimeException
	#tag Method, Flags = &h1000
		Sub Constructor(ErrorCode As Integer)
		  Me.ErrorNumber = ErrorCode
		  
		  Select Case ErrorCode
		    
		    ' archive-related errors (non-zlib)
		  Case ERR_END_ARCHIVE
		    Me.Message = "The archive contains no additional entries."
		  Case ERR_INVALID_ENTRY
		    Me.Message = "The archive entry is corrupt."
		  Case ERR_NOT_ZIPPED
		    Me.Message = "The archive is not zipped."
		  Case ERR_UNSUPPORTED_COMPRESSION
		    Me.Message = "The archive entry uses a non-standard compression algorithm."
		    
		    'zlib's built-in error messages suck; these are much better
		  Case Z_BUF_ERROR
		    Me.Message = "The requested operation requires a larger output buffer."
		  Case Z_DATA_ERROR
		    Me.Message = "The input buffer contains invalid or incomplete deflate data."
		  Case Z_MEM_ERROR
		    Me.Message = "There is insufficient available memory to perform the requested operation."
		  Case Z_STREAM_ERROR
		    Me.Message = "The stream state is inconsistent or invalid."
		  Case Z_VERSION_ERROR
		    Me.Message = "The zlib library is a different version than what was expected."
		  Case Z_NEED_DICT
		    Me.Message = "The stream is compressed with a custom dictionary." ' not an error per se, but a special condition
		  Case Z_STREAM_END
		    Me.Message = "The stream has ended." ' not an error per se, but a special condition
		  Case Z_ERRNO
		    Me.Message = "A system error occurred during the operation. Consult the system last error value for details."
		  Else
		    If zlib.IsAvailable Then
		      Dim err As MemoryBlock = zError(ErrorCode)
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
