#tag Class
Protected Class Deflater
Inherits FlateEngine
	#tag Method, Flags = &h0
		Function CompressBound(DataLength As UInt32) As UInt32
		  ' Computes the upper bound of the compressed size after deflation of DataLength bytes
		  If Not IsOpen Then Return 0
		  Return deflateBound(zstruct, DataLength)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, CompressionStrategy As Integer = zlib.Z_DEFAULT_STRATEGY, WindowBits As Integer = zlib.DEFLATE_ENCODING, MemoryLevel As Integer = zlib.DEFAULT_MEM_LVL)
		  ' Construct a new Deflater instance using the specified compression options. 
		  ' If the deflate engine could not be initialized an exception will be raised.
		  
		  If Not zlib.IsAvailable Then Raise New PlatformNotSupportedException
		  
		  zstruct.zalloc = Nil
		  zstruct.zfree = Nil
		  zstruct.opaque = Nil
		  
		  If CompressionStrategy <> Z_DEFAULT_STRATEGY Or WindowBits <> DEFLATE_ENCODING Or MemoryLevel <> DEFAULT_MEM_LVL Then
		    ' Open the compressed stream using custom options
		    mLastError = deflateInit2_(zstruct, CompressionLevel, Z_DEFLATED, WindowBits, MemoryLevel, CompressionStrategy, zlib.Version, zstruct.Size)
		    
		  Else
		    ' process zlib-wrapped deflate data
		    mLastError = deflateInit_(zstruct, CompressionLevel, zlib.Version, zstruct.Size)
		    
		  End If
		  
		  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
		  mLevel = CompressionLevel
		  mStrategy = CompressionStrategy
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(CopyStream As zlib.Deflater)
		  ' Constructs a Deflater instance by duplicating the internal compression state of the CopyStream
		  
		  If Not zlib.IsAvailable Then Raise New PlatformNotSupportedException
		  
		  mLastError = deflateCopy(zstruct, CopyStream.zstruct)
		  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
		  mLevel = CopyStream.Level
		  mStrategy = CopyStream.Strategy
		  mDictionary = CopyStream.mDictionary
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Deflate(Data As MemoryBlock, Flushing As Integer = zlib.Z_NO_FLUSH) As MemoryBlock
		  ' Compresses Data and returns it as a new MemoryBlock, or Nil on error.
		  ' Check LastError for details if there was an error.
		  
		  If Not IsOpen Then Return Nil
		  
		  Dim ret As New MemoryBlock(0)
		  Dim retstream As New BinaryStream(ret)
		  Dim instream As New BinaryStream(Data)
		  If Not Me.Deflate(instream, retstream, Flushing) Then Return Nil
		  retstream.Close
		  Return ret
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Deflate(ReadFrom As Readable, WriteTo As Writeable, Flushing As Integer = zlib.Z_NO_FLUSH, ReadCount As Integer = - 1) As Boolean
		  ' Reads uncompressed bytes from ReadFrom and writes all compressed output to WriteTo. If
		  ' ReadCount is specified then exactly ReadCount uncompressed bytes are read; otherwise
		  ' uncompressed bytes will continue to be read until ReadFrom.EOF. If ReadFrom represents 
		  ' more than CHUNK_SIZE uncompressed bytes then they will be read in chunks of CHUNK_SIZE.
		  ' The size of the output is variable, typically smaller than the input, and will be written 
		  ' to WriteTo in chunks no greater than CHUNK_SIZE. Consult the zlib documentation before 
		  ' changing CHUNK_SIZE. If this method returns True then all uncompressed bytes were 
		  ' processed and the compressor is ready for more input. Depending on the state of the 
		  ' compressor and the Flushing parameter, compressed output might not be written until a 
		  ' subsequent call to this method.
		  
		  If Not IsOpen Then Return False
		  
		  Dim outbuff As New MemoryBlock(CHUNK_SIZE)
		  Dim count As Integer
		  ' The outer loop reads uncompressed bytes from ReadFrom until EOF, using them as input
		  ' The inner loop provides more output space, calls deflate, and writes any output to WriteTo
		  Do
		    Dim chunk As MemoryBlock
		    If ReadFrom <> Nil Then chunk = ReadFrom.Read(CHUNK_SIZE) Else chunk = ""
		    zstruct.avail_in = chunk.Size
		    zstruct.next_in = chunk
		    count = count + chunk.Size
		    
		    Do
		      ' provide more output space
		      zstruct.next_out = outbuff
		      zstruct.avail_out = outbuff.Size
		      mLastError = zlib.deflate(zstruct, Flushing)
		      If mLastError = Z_STREAM_ERROR Then Return False ' the stream state is inconsistent!!!
		      ' consume any output
		      Dim have As UInt32 = CHUNK_SIZE - zstruct.avail_out
		      If have > 0 Then WriteTo.Write(outbuff.StringValue(0, have))
		      ' keep going until zlib doesn't use all the output space or an error
		    Loop Until mLastError <> Z_OK Or zstruct.avail_out <> 0
		    
		  Loop Until (ReadCount > -1 And count >= ReadCount) Or ReadFrom = Nil Or ReadFrom.EOF
		  
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
		  ' Returns the number of bytes and bits of output that have been generated, but not yet provided 
		  ' in the available output. The bytes not provided would be due to the available output space 
		  ' being consumed. The number of bits of output not provided are between 0 and 7, where they await 
		  ' more bits to join them in order to fill out a full byte.
		  
		  If Not IsOpen Then Return 0.0
		  Dim bytes As UInt32
		  Dim bits As Integer
		  mLastError = deflatePending(zstruct, bytes, bits)
		  If mLastError = Z_OK Then Return CDbl(Str(bytes) + "." + Str(bits))
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Prime(Bits As Integer, Value As Integer) As Boolean
		  ' Inserts bits in the deflate output stream. The intent is that this function is used to start off the deflate 
		  ' output with the bits leftover from a previous deflate stream when appending to it. As such, this function can
		  ' only be used for raw deflate, and must be used before the first deflate() call (or after Reset). Bits must be
		  ' less than or equal to 16, and that many of the least significant bits of value will be inserted in the output.
		  
		  If Not IsOpen Then Return False
		  mLastError = deflatePrime(zstruct, Bits, Value)
		  Return mLastError = Z_OK
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Reset()
		  ' Reinitializes the compressor but does not free and reallocate all the internal compression state. 
		  ' The stream will keep the same compression level and any other attributes that may have been set by
		  ' the constructor.
		  
		  If IsOpen Then mLastError = deflateReset(zstruct)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SetHeader(HeaderStruct As zlib.gz_headerp) As Boolean
		  ' Provides gzip header information for when a gzip stream is requested. This method may be called after the constructor
		  ' or a call to Reset(), but before the first call to deflate()
		  
		  If Not IsOpen Then Return False
		  mLastError = deflateSetHeader(zstruct, HeaderStruct)
		  Return mLastError = Z_OK
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Tune(GoodLength As Integer, MaxLazy As Integer, NiceLength As Integer, MaxChain As Integer) As Boolean
		  ' Fine tune deflate's internal compression parameters. This should only be used by someone who understands the 
		  ' algorithm used by zlib's deflate for searching for the best matching string, and even then only by the most 
		  ' fanatic optimizer trying to squeeze out the last compressed bit for their specific input data. 
		  
		  If Not IsOpen Then Return False
		  mLastError = deflateTune(zstruct, GoodLength, MaxLazy, NiceLength, MaxChain)
		  Return mLastError = Z_OK
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets the previously set compression dictionary
			  
			  Return mDictionary
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Sets the compression dictionary from the given byte sequence without producing any compressed output. Must be 
			  ' set immediately after the constructor or a call to Reset(), but before the first call to deflate. The compressor 
			  ' and decompressor must use exactly the same dictionary (see Inflater.Dictionary).
			  
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
			  ' Dynamically update the compression level. If the compression level is changed, the input available so
			  ' far is compressed with the old level (and may be flushed); the new level will take effect only at the 
			  ' next call to deflate().
			  
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
			  ' Dynamically update the compression strategy. The new strategy will take effect only at the next call to deflate().
			  
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
