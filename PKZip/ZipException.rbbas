#tag Class
Protected Class ZipException
Inherits RuntimeException
	#tag Method, Flags = &h1000
		Sub Constructor(ErrorCode As Integer)
		  Me.ErrorNumber = ErrorCode
		  
		  Select Case ErrorCode
		  Case ERR_END_ARCHIVE
		    Me.Message = "The archive contains no further entries."
		  Case ERR_INVALID_ENTRY
		    Me.Message = "The archive entry is corrupt."
		  Case ERR_NOT_ZIPPED
		    Me.Message = "The archive is not zipped."
		  Case ERR_UNSUPPORTED_COMPRESSION
		    Me.Message = "The archive entry uses a non-standard compression algorithm."
		  Case ERR_CHECKSUM_MISMATCH
		    Me.Message = "The archive entry failed verification."
		  Case ERR_INVALID_NAME
		    Me.Message = "The archive entry has an illegal file name."
		  Case ERR_TOO_LARGE
		    Me.Message = "The file is too large for the zip archive format."
		  Else
		    Me.Message = "Unknown error"
		  End Select
		End Sub
	#tag EndMethod


End Class
#tag EndClass
