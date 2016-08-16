#tag Class
Protected Class Deflater
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
		Function CompressBound(DataLength As UInt32) As UInt32
		  If Not IsOpen Then Return 0
		  Return deflateBound(zstream, DataLength)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(CompressionLevel As Integer)
		  Const MAX_MEM_LEVEL = 8
		  zstream.zalloc = Nil
		  zstream.zfree = Nil
		  zstream.opaque = Nil
		  mLastError = deflateInit_(zstream, CompressionLevel, zlib.Version, zstream.Size)
		  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
		  mLevel = CompressionLevel
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(CompressionLevel As Integer, CompressionStrategy As Integer, WindowBits As Integer, MemoryLevel As Integer)
		  zstream.zalloc = Nil
		  zstream.zfree = Nil
		  zstream.opaque = Nil
		  mLastError = deflateInit2_(zstream, CompressionLevel, Z_DEFLATED, WindowBits, MemoryLevel, CompressionStrategy, zlib.Version, zstream.Size)
		  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
		  mLevel = CompressionLevel
		  mStrategy = CompressionStrategy
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(CopyStream As zlib.Deflater)
		  mLastError = deflateCopy(zstream, CopyStream.zstream)
		  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
		  mLevel = CopyStream.Level
		  mStrategy = CopyStream.Strategy
		  mDictionary = CopyStream.mDictionary
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Deflate(Data As MemoryBlock, Flushing As Integer = zlib.Z_NO_FLUSH) As MemoryBlock
		  Dim ret As New MemoryBlock(0)
		  Dim retstream As New BinaryStream(ret)
		  If Not Me.Deflate(Data, retstream, Flushing) Then Return Nil
		  retstream.Close
		  Return ret
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Deflate(Data As MemoryBlock, WriteTo As Writeable, Flushing As Integer = zlib.Z_NO_FLUSH) As Boolean
		  Dim outbuff As New MemoryBlock(CHUNK_SIZE)
		  Dim instream As New BinaryStream(Data)
		  Do
		    Dim chunk As MemoryBlock = instream.Read(CHUNK_SIZE)
		    zstream.avail_in = chunk.Size
		    zstream.next_in = chunk
		    Do
		      zstream.next_out = outbuff
		      zstream.avail_out = outbuff.Size
		      mLastError = zlib.deflate(zstream, Flushing)
		      If mLastError = Z_STREAM_ERROR Then Return False
		      Dim have As UInt32 = CHUNK_SIZE - zstream.avail_out
		      If have > 0 Then WriteTo.Write(outbuff.StringValue(0, have))
		    Loop Until mLastError <> Z_OK Or zstream.avail_out <> 0
		  Loop Until instream.EOF
		  Return True
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If IsOpen Then mLastError = zlib.deflateEnd(zstream)
		  zstream.zfree = Nil
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function IsOpen() As Boolean
		  Return zstream.zfree <> Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Pending() As Single
		  If Not IsOpen Then Return 0.0
		  Dim bytes As UInt32
		  Dim bits As Integer
		  mLastError = deflatePending(zstream, bytes, bits)
		  If mLastError = Z_OK Then Return CDbl(Str(bytes) + "." + Str(bits))
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Prime(Bits As Integer, Value As Integer) As Boolean
		  If Not IsOpen Then Return False
		  mLastError = deflatePrime(zstream, Bits, Value)
		  Return mLastError = Z_OK
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Reset()
		  If zstream.zalloc <> Nil Then
		    mLastError = deflateReset(zstream)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SetHeader(HeaderStruct As zlib.gz_headerp) As Boolean
		  If Not IsOpen Then Return False
		  mLastError = deflateSetHeader(zstream, HeaderStruct)
		  Return mLastError = Z_OK
		  
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

	#tag Method, Flags = &h0
		Function Tune(GoodLength As Integer, MaxLazy As Integer, NiceLength As Integer, MaxChain As Integer) As Boolean
		  If Not IsOpen Then Return False
		  mLastError = deflateTune(zstream, GoodLength, MaxLazy, NiceLength, MaxChain)
		  Return mLastError = Z_OK
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mDictionary
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If value = Nil Or Not IsOpen Then Return
			  mLastError = deflateSetDictionary(zstream, value, value.Size)
			  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
			  mDictionary = value
			End Set
		#tag EndSetter
		Dictionary As MemoryBlock
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mLevel
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If Not IsOpen Then Raise New NilObjectException
			  mLastError = deflateParams(zstream, value, mStrategy)
			  If mLastError = Z_OK Then
			    mLevel = value
			  Else
			    Raise New zlibException(mLastError)
			  End If
			  
			End Set
		#tag EndSetter
		Level As Integer
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mDictionary As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLevel As Integer = Z_DEFAULT_COMPRESSION
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mStrategy As Integer = Z_DEFAULT_STRATEGY
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mStrategy
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If Not IsOpen Then Raise New NilObjectException
			  mLastError = deflateParams(zstream, mLevel, value)
			  If mLastError = Z_OK Then
			    mStrategy = value
			  Else
			    Raise New zlibException(mLastError)
			  End If
			  
			End Set
		#tag EndSetter
		Strategy As Integer
	#tag EndComputedProperty

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
			Name="Level"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Strategy"
			Group="Behavior"
			Type="Integer"
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
