#tag Class
Protected Class Inflater
Inherits FlateEngine
	#tag Method, Flags = &h0
		Sub Constructor(Encoding As Integer = zlib.DEFLATE_ENCODING)
		  ' Construct a new Inflater instance using the specified Encoding. Encoding control,
		  ' among other things, the type of compression being used. (For GZip pass GZIP_ENCODING)
		  ' If the inflate engine could not be initialized an exception will be raised.
		  
		  // Calling the overridden superclass constructor.
		  // Constructor() -- From zlib.FlateEngine
		  Super.Constructor()
		  
		  If Encoding = DEFLATE_ENCODING Then
		    mLastError = inflateInit_(zstruct, zlib.Version, zstruct.Size)
		  Else
		    mLastError = inflateInit2_(zstruct, Encoding, zlib.Version, zstruct.Size)
		  End If
		  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(CopyStream As zlib.Inflater)
		  ' Construct a new Inflater instance using the specified compression options.
		  ' If the inflate engine could not be initialized an exception will be raised.
		  
		  // Calling the overridden superclass constructor.
		  // Constructor() -- From zlib.FlateEngine
		  Super.Constructor()
		  
		  mLastError = inflateCopy(zstruct, CopyStream.zstruct)
		  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
		  mDictionary = CopyStream.mDictionary
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If IsOpen Then mLastError = inflateEnd(zstruct)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetHeader(ByRef HeaderStruct As zlib.gz_headerp) As Boolean
		  ' Reads gzip header information when a gzip stream is opened. This method may be called after the constructor
		  ' or a call to Reset(), but before the first call to inflate()
		  
		  If Not IsOpen Then Return False
		  mLastError = inflateGetHeader(zstruct, HeaderStruct)
		  Return mLastError = Z_OK
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Inflate(Data As MemoryBlock) As MemoryBlock
		  ' Decompresses Data and returns it as a new MemoryBlock, or Nil on error.
		  ' Check LastError for details if there was an error.
		  
		  If Not IsOpen Then Return Nil
		  
		  Dim ret As New MemoryBlock(0)
		  Dim retstream As New BinaryStream(ret)
		  Dim instream As New BinaryStream(Data)
		  If Not Me.Inflate(instream, retstream, -1) Then Return Nil
		  retstream.Close
		  Return ret
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Inflate(ReadFrom As Readable, WriteTo As Writeable, ReadCount As Integer = - 1) As Boolean
		  ' Reads compressed bytes from ReadFrom and writes all decompressed output to WriteTo. If
		  ' ReadCount is specified then exactly ReadCount compressed bytes are read; otherwise
		  ' compressed bytes will continue to be read until ReadFrom.EOF. If ReadFrom represents more 
		  ' than CHUNK_SIZE compressed bytes then they will be read in chunks of CHUNK_SIZE. The size 
		  ' of the output is variable, typically many times larger than the input, but will be written 
		  ' to WriteTo in chunks no greater than CHUNK_SIZE. Consult the zlib documentation before 
		  ' changing CHUNK_SIZE. If this method returns True then all valid output was written and the 
		  ' decompressor is ready for more input. Check LastError to determine whether there was an 
		  ' error while decompressing.
		  
		  If Not IsOpen Then Return False
		  
		  Dim outbuff As New MemoryBlock(CHUNK_SIZE)
		  Dim count As Integer
		  ' The outer loop reads compressed bytes from ReadFrom until EOF, using them as input
		  ' The inner loop provides more output space, calls inflate, and writes any output to WriteTo
		  Do
		    Dim chunk As MemoryBlock
		    Dim sz As Integer
		    If ReadCount > -1 Then sz = Min(ReadCount, CHUNK_SIZE) Else sz = CHUNK_SIZE
		    If ReadFrom <> Nil And sz > 0 Then chunk = ReadFrom.Read(sz) Else chunk = ""
		    zstruct.avail_in = chunk.Size
		    zstruct.next_in = chunk
		    count = count + chunk.Size
		    Do
		      ' provide more output space
		      zstruct.next_out = outbuff
		      zstruct.avail_out = outbuff.Size
		      mLastError = inflate(zstruct, Z_NO_FLUSH)
		      ' consume any output
		      Dim have As UInt32 = CHUNK_SIZE - zstruct.avail_out
		      If have > 0 Then WriteTo.Write(outbuff.StringValue(0, have))
		      ' keep going until zlib doesn't use all the output space or an error
		    Loop Until mLastError <> Z_OK Or zstruct.avail_out <> 0
		    
		  Loop Until (ReadCount > -1 And count >= ReadCount) Or ReadFrom = Nil Or ReadFrom.EOF
		  
		  ' Z_BUF_ERROR is non-fatal to the decompression process; you can keep 
		  ' providing input to the decompressor in search of a valid deflate block.
		  ' 
		  Return mLastError = Z_OK Or mLastError = Z_STREAM_END Or mLastError = Z_BUF_ERROR
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function InflateMark() As UInt32
		  ' If the upper 16 bits of the return value is –1 and the lower bits are zero, then inflate() is currently decoding 
		  ' information outside of a block. If the upper value is –1 and the lower value is non-zero, then inflate is in the
		  ' middle of a stored block, with the lower value equaling the number of bytes from the input remaining to copy. If
		  ' the upper value is not –1, then it is the number of bits back from the current bit position in the input of the
		  ' code (literal or length/distance pair) currently being processed. In that case the lower value is the number of
		  ' bytes already emitted for that code.
		  
		  If Not IsOpen Then Return 0
		  Return inflateMark(zstruct)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Reset(Encoding As Integer = 0)
		  ' Reinitializes the decompressor but does not free and reallocate all the internal decompression state.
		  ' The stream will keep the attributes that may have been set by the constructor.
		  
		  If Not IsOpen Then Return
		  If Encoding = 0 Then
		    mLastError = inflateReset(zstruct)
		  Else
		    mLastError = inflateReset2(zstruct, Encoding)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SyncToNextFlush() As Boolean
		  ' Skips invalid compressed data until a possible full flush point can be found, or until all available input is skipped.
		  
		  If Not IsOpen Then Return False
		  mLastError = inflateSync(zstruct)
		  Return mLastError = Z_OK
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the sliding dictionary being maintained by inflate()
			  
			  If Not IsOpen Then Return Nil
			  Dim sz As UInt32 = 32768
			  Dim mb As New MemoryBlock(sz)
			  mLastError = inflateGetDictionary(zstruct, mb, sz)
			  If mLastError <> Z_OK Then Return Nil
			  Return mb.StringValue(0, sz)
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Sets the compression dictionary from the given uncompressed byte sequence. Must be set immediately after the
			  ' constructor or a call to Reset(), but before the first call to inflate. The compressor and decompressor must
			  ' use exactly the same dictionary (see Deflater.Dictionary).
			  
			  If value = Nil Or Not IsOpen Then Return
			  mLastError = inflateSetDictionary(zstruct, value, value.Size)
			  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
			End Set
		#tag EndSetter
		Dictionary As MemoryBlock
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
