#tag Class
Protected Class Compressor
Implements Writeable
	#tag Method, Flags = &h0
		Sub Close()
		  Dim mb As New MemoryBlock(1024)
		  If Not Me.Deflate(Z_FINISH, Nil, mb) And Me.LastError <> Z_OK And Me.LastError <> Z_STREAM_END Then
		    Dim err As New IOException
		    err.ErrorNumber = Me.LastError
		    err.Message = FormatError(Me.LastError)
		    Raise err
		  End If
		  If mStream.avail_out > 0 Then Outstream.Write(mb.StringValue(0, mStream.avail_out))
		  
		  If Outstream IsA BinaryStream Then BinaryStream(Outstream).Close
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(StreamStruct As zlib.z_stream, WriteTo As Writeable)
		  mStream = StreamStruct
		  Outstream = WriteTo
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Create(OutputFile As FolderItem, OverWrite As Boolean = False, Compression As Integer = zlib.Z_DEFAULT_COMPRESSION) As zlib.Compressor
		  ' Creates an empty compressed stream
		  Dim strm As z_stream
		  Dim err As Integer = deflateInit_(strm, Compression, Version, strm.Size)
		  If err = Z_OK Then
		    Dim w As Writeable = BinaryStream.Create(OutputFile, OverWrite)
		    Return New zlib.Compressor(strm, w)
		  Else
		    Raise New RuntimeException
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Deflate(Flush As Integer, DataIn As MemoryBlock, ByRef DataOut As MemoryBlock) As Boolean
		  Dim p1 As New MemoryBlock(4)
		  p1.Ptr(0) = DataOut
		  Dim p2 As New MemoryBlock(4)
		  p2.Ptr(0) = DataIn
		  If DataIn <> Nil Then
		    mStream.avail_in = DataIn.Size
		    mStream.next_in = p2
		  Else
		    mStream.avail_in = 0
		    mStream.next_in = Nil
		  End If
		  mStream.avail_out = DataOut.Size
		  mStream.next_out = p1
		  Do
		    mLastError = zlib.deflate(mStream, Flush) ' do the thing
		    If Me.LastError <> Z_OK Then Exit Do
		    'mStream.next_out = Nil
		    'mStream.avail_out = 0
		  Loop Until mStream.avail_in <= 0
		  DataOut = mStream.next_out
		  Return Me.LastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Flush()
		  // Part of the Writeable interface.
		  Dim mb As New MemoryBlock(1024)
		  If Not Me.Deflate(Z_PARTIAL_FLUSH, Nil, mb) And Me.LastError <> Z_OK And Me.LastError <> Z_STREAM_END Then
		    Dim err As New IOException
		    err.ErrorNumber = Me.LastError
		    err.Message = FormatError(Me.LastError)
		    Raise err
		  End If
		  If mStream.avail_out > 0 Then Outstream.Write(mb.StringValue(0, mStream.avail_out))
		  Outstream.Flush
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(text As String)
		  // Part of the Writeable interface.
		  'writes to a compressed stream
		  Dim out As New MemoryBlock(text.LenB)
		  If Not Me.Deflate(Z_NO_FLUSH, Text, out) And Me.LastError <> Z_OK And Me.LastError <> Z_STREAM_END Then
		    Dim err As New IOException
		    err.ErrorNumber = Me.LastError
		    err.Message = FormatError(Me.LastError)
		    Raise err
		  End If
		  If mStream.avail_out > 0 Then
		    Outstream.Write(out.StringValue(0, mStream.avail_out))
		  End If
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function WriteError() As Boolean
		  // Part of the Writeable interface.
		  Return mLastError <> 0 Or Outstream.WriteError
		End Function
	#tag EndMethod


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
