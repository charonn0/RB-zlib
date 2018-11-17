#tag Class
Protected Class ZipException
Inherits RuntimeException
	#tag Method, Flags = &h1000
		Sub Constructor(ErrorCode As Integer)
		  Me.ErrorNumber = ErrorCode
		  Me.Message = PKZip.FormatError(ErrorCode)
		End Sub
	#tag EndMethod


End Class
#tag EndClass
