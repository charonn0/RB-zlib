#tag Class
Class zlibStream
Implements Readable, Writeable
	#tag Method, Flags = &h0
		Sub Close()
		  If Outstream <> Nil Then 
		    Outstream.Flush
		    mLastError = deflate(mstream, Z_FINISH)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(StreamStruct As zlib.z_stream, ReadFrom As Readable)
		   mStream = StreamStruct
		  InStream = ReadFrom
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(StreamStruct As zlib.z_stream, WriteTo As Writeable)
		   mStream = StreamStruct
		  Outstream = WriteTo
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Create(TargetFile As FolderItem, Compression As Integer = zlib.Z_DEFAULT_COMPRESSION) As zlibStream
		  ' Creates an empty compressed stream
		  Dim strm As z_stream
		  Dim err As Integer = deflateInit_(strm, Compression, Version, strm.Size)
		  If err = Z_OK Then
		    Dim w As Writeable = BinaryStream.Create(Targetfile, True)
		    Return New zlibStream(strm, w)
		  Else
		    Raise New RuntimeException
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Destructor()
		  Me.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EOF() As Boolean
		  // Part of the Readable interface.
		  Return InStream.EOF
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Flush()
		  // Part of the Writeable interface.
		  If Outstream <>  Nil Then mLastError = deflate(mstream, Z_FULL_FLUSH)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(ZippedFile As FolderItem) As zlibStream
		  Dim strm As z_stream
		  Dim err As Integer = inflateInit_(strm, Version, strm.Size)
		  If err = Z_OK Then
		    Dim r As Readable = BinaryStream.Open(ZippedFile)
		    Return New zlibStream(strm, r)
		  Else
		    Raise New RuntimeException
		  End If
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
		    Return odata
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

	#tag Method, Flags = &h0
		Sub Write(text As String)
		  // Part of the Writeable interface.
		  'writes to a compressed stream
		  Dim out As New MemoryBlock(text.LenB)
		  Dim txt As MemoryBlock = text
		  mStream.avail_out = out.Size
		  mStream.next_out = out
		  mStream.next_in = txt
		  mStream.avail_in = out.Size
		  
		  mLastError = deflate(mStream, 0)
		  
		  If Me.LastError <> Z_OK And Me.LastError <> Z_STREAM_END Then
		    Dim err As New IOException
		    err.ErrorNumber = Me.LastError
		    err.Message = FormatError(Me.LastError)
		    Raise err
		  End If
		  Outstream.Write(out)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function WriteError() As Boolean
		  // Part of the Writeable interface.
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

	#tag Property, Flags = &h1
		Protected Outstream As Writeable
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
