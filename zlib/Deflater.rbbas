#tag Class
Protected Class Deflater
Inherits FlateEngine
	#tag Method, Flags = &h0
		Function CompressBound(DataLength As UInt32) As UInt32
		  If Not IsOpen Then Return 0
		  Return deflateBound(zstruct, DataLength)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(CompressionLevel As Integer)
		  zstruct.zalloc = Nil
		  zstruct.zfree = Nil
		  zstruct.opaque = Nil
		  mLastError = deflateInit_(zstruct, CompressionLevel, zlib.Version, zstruct.Size)
		  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
		  mLevel = CompressionLevel
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(CompressionLevel As Integer, CompressionStrategy As Integer, WindowBits As Integer, MemoryLevel As Integer)
		  zstruct.zalloc = Nil
		  zstruct.zfree = Nil
		  zstruct.opaque = Nil
		  mLastError = deflateInit2_(zstruct, CompressionLevel, Z_DEFLATED, WindowBits, MemoryLevel, CompressionStrategy, zlib.Version, zstruct.Size)
		  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
		  mLevel = CompressionLevel
		  mStrategy = CompressionStrategy
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(CopyStream As zlib.Deflater)
		  mLastError = deflateCopy(zstruct, CopyStream.zstruct)
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
		  Dim instream As New BinaryStream(Data)
		  If Not Me.Deflate(instream, retstream, Flushing) Then Return Nil
		  retstream.Close
		  Return ret
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Deflate(ReadFrom As Readable, WriteTo As Writeable, Flushing As Integer = zlib.Z_NO_FLUSH) As Boolean
		  Dim outbuff As New MemoryBlock(CHUNK_SIZE)
		  Do
		    Dim chunk As MemoryBlock
		    If ReadFrom <> Nil Then chunk = ReadFrom.Read(CHUNK_SIZE) Else chunk = ""
		    zstruct.avail_in = chunk.Size
		    zstruct.next_in = chunk
		    Do
		      zstruct.next_out = outbuff
		      zstruct.avail_out = outbuff.Size
		      mLastError = zlib.deflate(zstruct, Flushing)
		      If mLastError = Z_STREAM_ERROR Then Return False
		      Dim have As UInt32 = CHUNK_SIZE - zstruct.avail_out
		      If have > 0 Then WriteTo.Write(outbuff.StringValue(0, have))
		    Loop Until mLastError <> Z_OK Or zstruct.avail_out <> 0
		  Loop Until ReadFrom = Nil Or ReadFrom.EOF
		  If Flushing = Z_FINISH And mLastError <> Z_STREAM_END Then Raise New zlibException(Z_UNFINISHED_ERROR)
		  Return zstruct.avail_in = 0 And (mLastError = Z_OK Or mLastError = Z_STREAM_END)
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If IsOpen Then mLastError = zlib.deflateEnd(zstruct)
		  zstruct.zfree = Nil
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Pending() As Single
		  If Not IsOpen Then Return 0.0
		  Dim bytes As UInt32
		  Dim bits As Integer
		  mLastError = deflatePending(zstruct, bytes, bits)
		  If mLastError = Z_OK Then Return CDbl(Str(bytes) + "." + Str(bits))
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Prime(Bits As Integer, Value As Integer) As Boolean
		  If Not IsOpen Then Return False
		  mLastError = deflatePrime(zstruct, Bits, Value)
		  Return mLastError = Z_OK
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Reset()
		  If zstruct.zalloc <> Nil Then
		    mLastError = deflateReset(zstruct)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SetHeader(HeaderStruct As zlib.gz_headerp) As Boolean
		  If Not IsOpen Then Return False
		  mLastError = deflateSetHeader(zstruct, HeaderStruct)
		  Return mLastError = Z_OK
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Tune(GoodLength As Integer, MaxLazy As Integer, NiceLength As Integer, MaxChain As Integer) As Boolean
		  If Not IsOpen Then Return False
		  mLastError = deflateTune(zstruct, GoodLength, MaxLazy, NiceLength, MaxChain)
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
			  mLastError = deflateSetDictionary(zstruct, value, value.Size)
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
			  mLastError = deflateParams(zstruct, value, mStrategy)
			  If mLastError = Z_OK Then
			    mLevel = value
			  Else
			    Raise New zlibException(mLastError)
			  End If
			  
			End Set
		#tag EndSetter
		Level As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mStrategy
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If Not IsOpen Then Raise New NilObjectException
			  mLastError = deflateParams(zstruct, mLevel, value)
			  If mLastError = Z_OK Then
			    mStrategy = value
			  Else
			    Raise New zlibException(mLastError)
			  End If
			  
			End Set
		#tag EndSetter
		Strategy As Integer
	#tag EndComputedProperty


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
