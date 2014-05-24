#tag Class
Protected Class Uncommpressor
Implements Readable
	#tag Method, Flags = &h0
		Sub Close()
		  mLastError = zlib.inflate(mstream, Z_FINISH)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(StreamStruct As zlib.z_stream, ReadFrom As Readable)
		  mStream = StreamStruct
		  InStream = ReadFrom
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EOF() As Boolean
		  // Part of the Readable interface.
		  Return InStream.EOF
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  // Part of the Readable interface.
		  ' Reads from a compressed stream
		  Dim zdata As MemoryBlock = InStream.Read(Count)
		  mStream.next_in = zdata
		  mStream.avail_in = zdata.Size
		  
		  Dim odata As New MemoryBlock(Count * 4)
		  mStream.next_out = odata
		  mStream.avail_out = odata.Size
		  mLastError = inflate(mStream, 0)
		  
		  If Me.LastError = Z_OK Or Me.LastError = Z_STREAM_END Then
		    Return DefineEncoding(odata, encoding)
		  Else
		    Dim err As New IOException
		    err.ErrorNumber = Me.LastError
		    err.Message = FormatError(Me.LastError)
		    Raise err
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadError() As Boolean
		  // Part of the Readable interface.
		  Return mLastError <> 0
		End Function
	#tag EndMethod


	#tag Property, Flags = &h1
		Protected InStream As Readable
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mStream As zlib.z_stream
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
