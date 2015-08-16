#tag Class
Protected Class zlibException
Inherits RuntimeException
	#tag Method, Flags = &h1000
		Sub Constructor(ErrorCode As Integer)
		  Me.ErrorNumber = ErrorCode
		  If zlib.IsAvailable Then
		    Dim err As MemoryBlock = zlib.zError(ErrorCode)
		    Me.Message = err.CString(0)
		  End If
		End Sub
	#tag EndMethod


End Class
#tag EndClass
