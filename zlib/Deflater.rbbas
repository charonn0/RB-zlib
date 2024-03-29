#tag Class
Protected Class Deflater
Inherits FlateEngine
	#tag Method, Flags = &h0
		Function CompressBound(DataLength As UInt32) As UInt32
		  ' Computes the upper bound of the compressed size after deflation of DataLength
		  ' bytes given the current state and options of the compressor. This allows you
		  ' to determine the maximum number of bytes that the algorithm *might* produce in
		  ' a worst-case scenario.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Deflater.CompressBound
		  
		  If Not IsOpen Then Return 0
		  Return deflateBound(zstruct, DataLength)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, CompressionStrategy As Integer = zlib.Z_DEFAULT_STRATEGY, Encoding As Integer = zlib.DEFLATE_ENCODING, MemoryLevel As Integer = zlib.DEFAULT_MEM_LVL)
		  ' Construct a new Deflater instance using the specified compression options.
		  ' If the deflate engine could not be initialized an exception will be raised.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Deflater.Constructor
		  
		  // Calling the overridden superclass constructor.
		  // Constructor() -- From zlib.FlateEngine
		  Super.Constructor()
		  
		  If CompressionStrategy <> Z_DEFAULT_STRATEGY Or Encoding <> DEFLATE_ENCODING Or MemoryLevel <> DEFAULT_MEM_LVL Then
		    ' Open the compressed stream using custom options
		    mLastError = deflateInit2_(zstruct, CompressionLevel, Z_DEFLATED, Encoding, MemoryLevel, CompressionStrategy, "1.2.8" + Chr(0), Me.Size)
		    
		  Else
		    ' process zlib-wrapped deflate data
		    mLastError = deflateInit_(zstruct, CompressionLevel, "1.2.8" + Chr(0), Me.Size)
		    
		  End If
		  
		  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
		  mLevel = CompressionLevel
		  mStrategy = CompressionStrategy
		  mEncoding = Encoding
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(CopyStream As zlib.Deflater)
		  ' Constructs a Deflater instance by duplicating the internal compression state
		  ' of the CopyStream
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Deflater.Constructor
		  
		  // Calling the overridden superclass constructor.
		  // Constructor() -- From zlib.FlateEngine
		  Super.Constructor()
		  
		  mLastError = deflateCopy(zstruct, CopyStream.zstruct)
		  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
		  mLevel = CopyStream.Level
		  mStrategy = CopyStream.Strategy
		  mDictionary = CopyStream.mDictionary
		  mEncoding = CopyStream.Encoding
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Deflate(Data As MemoryBlock, Flushing As Integer = zlib.Z_NO_FLUSH) As MemoryBlock
		  ' Processes the uncompressed bytes in the Data parameter into the compressor and
		  ' returns any compressed output. Depending on the state of the compressor and the
		  ' Flushing parameter, compressed output might not be emitted until a subsequent
		  ' call to this method.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Deflater.Deflate
		  
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
		Function Deflate(ReadFrom As Readable, WriteTo As Writeable, Flushing As Integer = zlib.Z_NO_FLUSH, ReadCount As Integer = -1) As Boolean
		  ' Reads uncompressed bytes from ReadFrom and writes all compressed output to
		  ' WriteTo. If ReadCount is specified then exactly ReadCount uncompressed bytes
		  ' are read; otherwise uncompressed bytes will continue to be read until
		  ' ReadFrom.EOF. If ReadFrom represents more than CHUNK_SIZE uncompressed bytes
		  ' then they will be read in chunks of CHUNK_SIZE.
		  ' The size of the output is variable, typically smaller than the input, and will
		  ' be written to WriteTo in chunks no greater than CHUNK_SIZE. Consult the zlib
		  ' documentation before changing CHUNK_SIZE.
		  ' If this method returns True then all uncompressed bytes were processed and the
		  ' compressor is ready for more input. Depending on the state of the compressor and
		  ' the Flushing parameter, compressed output might not be written until a subsequent
		  ' call to this method.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Deflater.Deflate
		  
		  If Not IsOpen Then Return False
		  
		  Dim outbuff As New MemoryBlock(CHUNK_SIZE)
		  Dim count As Integer
		  ' The outer loop reads uncompressed bytes from ReadFrom until EOF, using them as input
		  ' The inner loop provides more output space, calls deflate, and writes any output to WriteTo
		  Do
		    Dim chunk As MemoryBlock
		    Dim sz As Integer
		    If ReadCount > -1 Then sz = Min(ReadCount - count, CHUNK_SIZE) Else sz = CHUNK_SIZE
		    If ReadFrom <> Nil And sz > 0 Then chunk = ReadFrom.Read(sz) Else chunk = ""
		    
		    Me.avail_in = chunk.Size
		    Me.next_in = chunk
		    count = count + chunk.Size
		    
		    Do
		      ' provide more output space
		      If outbuff.Size <> CHUNK_SIZE Then outbuff.Size = CHUNK_SIZE
		      Me.next_out = outbuff
		      Me.avail_out = outbuff.Size
		      mLastError = deflate_(zstruct, Flushing)
		      If mLastError = Z_STREAM_ERROR Then Return False ' the stream state is inconsistent!!!
		      ' consume any output
		      Dim have As UInt32 = CHUNK_SIZE - Me.avail_out
		      If have > 0 Then
		        If have <> outbuff.Size Then outbuff.Size = have
		        WriteTo.Write(outbuff)
		      End If
		      ' keep going until zlib doesn't use all the output space or an error
		    Loop Until mLastError <> Z_OK Or Me.avail_out <> 0
		    
		  Loop Until (ReadCount > -1 And count >= ReadCount) Or ReadFrom = Nil Or ReadFrom.EOF
		  
		  If Flushing = Z_FINISH And mLastError <> Z_STREAM_END Then Raise New zlibException(mLastError)
		  Return Me.avail_in = 0 And (mLastError = Z_OK Or mLastError = Z_STREAM_END)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If IsOpen Then mLastError = deflateEnd(zstruct)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Prime(Bits As Integer, Value As Integer) As Boolean
		  ' Inserts bits in the deflate output stream. The intent is that this function
		  ' is used to start off the deflate output with the bits leftover from a previous
		  ' deflate stream when appending to it. As such, this function can only be used
		  ' for raw deflate, and must be used before the first deflate() call (or after
		  ' Reset). Bits must be less than or equal to 16, and that many of the least
		  ' significant bits of value will be inserted in the output.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Deflater.Prime
		  
		  If Not IsOpen Then Return False
		  mLastError = deflatePrime(zstruct, Bits, Value)
		  Return mLastError = Z_OK
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Reset()
		  ' Reinitializes the compressor but does not free and reallocate all the internal
		  ' compression state. The stream will keep the same compression level and any other
		  ' attributes that may have been set.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Deflater.Reset
		  
		  If IsOpen Then mLastError = deflateReset(zstruct)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SetHeader(HeaderStruct As zlib.gz_headerp) As Boolean
		  ' Provides gzip header information for when a gzip stream is requested. This
		  ' method may be called after the Constructor() or a call to Reset(), but before
		  ' the first call to Deflate()
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Deflater.SetHeader
		  
		  If Not IsOpen Then Return False
		  mLastError = deflateSetHeader(zstruct, HeaderStruct)
		  Return mLastError = Z_OK
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Tune(GoodLength As Integer, MaxLazy As Integer, NiceLength As Integer, MaxChain As Integer) As Boolean
		  ' Fine tune deflate's internal compression parameters. This should only be used
		  ' by someone who understands the algorithm used by zlib's deflate for searching
		  ' for the best matching string, and even then only by the most fanatic optimizer
		  ' trying to squeeze out the last compressed bit for their specific input data.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Deflater.Tune
		  
		  If Not IsOpen Then Return False
		  mLastError = deflateTune(zstruct, GoodLength, MaxLazy, NiceLength, MaxChain)
		  Return mLastError = Z_OK
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets the previously set compression dictionary.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Deflater.Dictionary
			  
			  Return mDictionary
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Sets the compression dictionary from the given byte sequence without producing
			  ' any compressed output. This must be set immediately after the Constructor() or
			  ' a call to Reset(), but before the first call to Deflate(). The compressor and
			  ' decompressor must use exactly the same dictionary (see Inflater.Dictionary).
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Deflater.Dictionary
			  
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
			  ' Gets the compression encoding (gzip, deflate, etc.) for the stream. 
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Deflater.Encoding
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib#stream-encoding
			  
			  Return mEncoding
			End Get
		#tag EndGetter
		Encoding As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Dynamically update the compression level. If the compression level is changed,
			  ' the input available so far is compressed with the old level (and may be flushed);
			  ' the new level will take effect only at the next call to deflate().
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Deflater.Level
			  
			  Return mLevel
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Dynamically update the compression level. If the compression level is changed,
			  ' the input available so far is compressed with the old level (and may be flushed);
			  ' the new level will take effect only at the next call to deflate().
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Deflater.Level
			  
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

	#tag Property, Flags = &h1
		Protected mEncoding As Integer
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mLevel As Integer = Z_DEFAULT_COMPRESSION
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mStrategy As Integer = Z_DEFAULT_STRATEGY
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the number of bytes and bits of output that have been generated, but
			  ' not yet provided in the available output. The bytes not provided would be due
			  ' to the available output space being consumed. The number of bits of output not
			  ' provided are between 0 and 7, where they await more bits to join them in order
			  ' to fill out a full byte.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Deflater
			  
			  If Not IsOpen Then Return 0.0
			  Dim bytes As UInt32
			  Dim bits As Integer
			  mLastError = deflatePending(zstruct, bytes, bits)
			  If mLastError = Z_OK Then Return bytes + (bits / 10)
			  
			End Get
		#tag EndGetter
		Pending As Single
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Dynamically update the compression strategy. The new strategy will take effect
			  ' only at the next call to Deflate().
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Deflater.Strategy
			  
			  Return mStrategy
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Dynamically update the compression strategy. The new strategy will take effect
			  ' only at the next call to Deflate().
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Deflater.Strategy
			  
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
