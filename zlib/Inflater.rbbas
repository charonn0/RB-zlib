#tag Class
Protected Class Inflater
	#tag Method, Flags = &h0
		Function Avail_In() As UInt32
		  Return zstream.avail_in
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Avail_Out() As UInt32
		  Return zstream.avail_out
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Checksum() As UInt32
		  If IsOpen Then Return zstream.adler
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(WindowBits As Integer = 0)
		  zstream.zalloc = Nil
		  zstream.zfree = Nil
		  zstream.opaque = Nil
		  zstream.avail_in = 0
		  zstream.next_in = Nil
		  If WindowBits = 0 Then
		    mLastError = inflateInit_(zstream, zlib.Version, zstream.Size)
		  Else
		    mLastError = inflateInit2_(zstream, WindowBits, zlib.Version, zstream.Size)
		  End If
		  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(CopyStream As zlib.Inflater)
		  mLastError = inflateCopy(zstream, CopyStream.zstream)
		  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
		  mDictionary = CopyStream.mDictionary
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If IsOpen Then mLastError = zlib.inflateEnd(zstream)
		  zstream.zfree = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Inflate(Data As MemoryBlock) As MemoryBlock
		  Dim ret As New MemoryBlock(0)
		  Dim retstream As New BinaryStream(ret)
		  If Not Me.Inflate(Data, retstream) Then Return Nil
		  retstream.Close
		  Return ret
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Inflate(Data As MemoryBlock, WriteTo As Writeable) As Boolean
		  Dim outbuff As New MemoryBlock(CHUNK_SIZE)
		  Dim instream As New BinaryStream(Data)
		  Do
		    Dim chunk As MemoryBlock = instream.Read(CHUNK_SIZE)
		    zstream.avail_in = chunk.Size
		    zstream.next_in = chunk
		    Do
		      zstream.next_out = outbuff
		      zstream.avail_out = outbuff.Size
		      mLastError = zlib.inflate(zstream, Z_NO_FLUSH)
		      If mLastError <> Z_OK And mLastError <> Z_STREAM_END And mLastError <> Z_BUF_ERROR Then Return False
		      Dim have As UInt32 = CHUNK_SIZE - zstream.avail_out
		      If have > 0 Then WriteTo.Write(outbuff.StringValue(0, have))
		    Loop Until mLastError <> Z_OK Or zstream.avail_out <> 0
		  Loop Until instream.EOF
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsOpen() As Boolean
		  Return zstream.zfree <> Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Reset(WindowBits As Integer = 0)
		  If Not IsOpen Then Return
		  If WindowBits = 0 Then
		    mLastError = inflateReset(zstream)
		  Else
		    mLastError = inflateReset2(zstream, WindowBits)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SyncToFlush() As Boolean
		  // locates the next point in the stream that is likely a Z_FULL_FLUSH point, where new inflation can begin
		  
		  If Not IsOpen Then Return False
		  mLastError = inflateSync(zstream)
		  Return mLastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Total_In() As UInt32
		  Return zstream.total_in
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Total_Out() As UInt32
		  Return zstream.total_out
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If Not IsOpen Then Return Nil
			  Dim sz As UInt32 = 32768
			  Dim mb As New MemoryBlock(sz)
			  mLastError = inflateGetDictionary(zstream, mb, sz)
			  If mLastError <> Z_OK Then Return Nil
			  Return mb.StringValue(0, sz)
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If value = Nil Or Not IsOpen Then Return
			  mLastError = inflateSetDictionary(zstream, value, value.Size)
			  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
			End Set
		#tag EndSetter
		Dictionary As MemoryBlock
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mDictionary As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected zstream As z_stream
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
