#tag Class
Protected Class Inflater
Inherits FlateEngine
	#tag Method, Flags = &h0
		Sub Constructor(Encoding As Integer = zlib.DEFLATE_ENCODING)
		  ' Construct a new Inflater instance using the specified Encoding. Encoding control,
		  ' among other things, the type of compression being used. (For GZip pass GZIP_ENCODING)
		  ' If the inflate engine could not be initialized an exception will be raised.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Inflater.Constructor
		  
		  // Calling the overridden superclass constructor.
		  // Constructor() -- From zlib.FlateEngine
		  Super.Constructor()
		  
		  If Encoding = DEFLATE_ENCODING Then
		    mLastError = inflateInit_(zstruct, "1.2.8" + Chr(0), Me.Size)
		  Else
		    mLastError = inflateInit2_(zstruct, Encoding, "1.2.8" + Chr(0), Me.Size)
		    If mLastError = Z_OK And Encoding >= GZIP_ENCODING Then mLastError = inflateGetHeader(zstruct, mGZHeader)
		  End If
		  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
		  mEncoding = Encoding
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(CopyStream As zlib.Inflater)
		  ' Creates a duplicate of the CopyStream and its current state. Duplication can be useful
		  ' when randomly accessing a long stream. The first pass through the stream can periodically
		  ' record a duplicate of the inflate state, allowing restarting inflate at those points when
		  ' randomly accessing the stream.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Inflater.Constructor
		  
		  // Calling the overridden superclass constructor.
		  // Constructor() -- From zlib.FlateEngine
		  Super.Constructor()
		  
		  mLastError = inflateCopy(zstruct, CopyStream.zstruct)
		  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
		  mDictionary = CopyStream.mDictionary
		  mEncoding = CopyStream.Encoding
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If IsOpen Then mLastError = inflateEnd(zstruct)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Inflate(Data As MemoryBlock) As MemoryBlock
		  ' Processes the compressed bytes in the Data parameter into the decompressor and returns
		  ' any decompressed output. Check LastError to determine whether there was an error while
		  ' decompressing.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Inflater.Inflate
		  
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
		Function Inflate(ReadFrom As Readable, WriteTo As Writeable, ReadCount As Integer = -1) As Boolean
		  ' Reads compressed bytes from ReadFrom and writes all decompressed output to WriteTo. If
		  ' ReadCount is specified then exactly ReadCount compressed bytes are read; otherwise
		  ' compressed bytes will continue to be read until ReadFrom.EOF. If ReadFrom represents more
		  ' than CHUNK_SIZE compressed bytes then they will be read in chunks of CHUNK_SIZE. The size
		  ' of the output is variable, typically many times larger than the input, but will be written
		  ' to WriteTo in chunks no greater than CHUNK_SIZE. Consult the zlib documentation before
		  ' changing CHUNK_SIZE. If this method returns True then all valid output was written and the
		  ' decompressor is ready for more input. Check LastError to determine whether there was an
		  ' error while decompressing.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Inflater.Inflate
		  
		  If Not IsOpen Then Return False
		  
		  Dim outbuff As New MemoryBlock(CHUNK_SIZE)
		  Dim count As Integer
		  ' The outer loop reads compressed bytes from ReadFrom until EOF, using them as input
		  ' The inner loop provides more output space, calls inflate, and writes any output to WriteTo
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
		      mLastError = inflate(zstruct, Z_NO_FLUSH)
		      ' consume any output
		      Dim have As UInt32 = CHUNK_SIZE - Me.avail_out
		      If have > 0 Then
		        If have <> outbuff.Size Then outbuff.Size = have
		        WriteTo.Write(outbuff)
		      End If
		      ' keep going until zlib doesn't use all the output space or an error
		    Loop Until mLastError <> Z_OK Or Me.avail_out <> 0
		    
		  Loop Until (ReadCount > -1 And count >= ReadCount) Or ReadFrom = Nil Or ReadFrom.EOF
		  
		  ' Z_BUF_ERROR is non-fatal to the decompression process; you can keep 
		  ' providing input to the decompressor in search of a valid deflate block.
		  
		  Return mLastError = Z_OK Or mLastError = Z_STREAM_END Or mLastError = Z_BUF_ERROR Or (mLastError = Z_DATA_ERROR And IgnoreChecksums)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function InflateMark() As UInt32
		  ' If the upper 16 bits of the return value is –1 and the lower bits are zero, then
		  ' inflate() is currently decoding information outside of a block. If the upper value is –1
		  ' and the lower value is non-zero, then inflate is in the' middle of a stored block, with the
		  ' lower value equaling the number of bytes from the input remaining to copy. If' the upper
		  ' value is not –1, then it is the number of bits back from the current bit position in the
		  ' input of the code (literal or length/distance pair) currently being processed. In that case
		  ' the lower value is the number of bytes already emitted for that code.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Inflater.InflateMark
		  
		  If Not IsOpen Then Return 0
		  Return inflateMark(zstruct)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Reset(Encoding As Integer = 0)
		  ' Reinitializes the decompressor but does not free and reallocate all the internal
		  ' decompression state. The stream will keep the attributes that may have been set by
		  ' the constructor.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Inflater.Reset
		  
		  If Not IsOpen Then Return
		  If mGZHeader.Done = 1 Then mGZHeader.Done = 0
		  If Encoding = 0 Then
		    mLastError = inflateReset(zstruct)
		  Else
		    mLastError = inflateReset2(zstruct, Encoding)
		    If mLastError = Z_OK Then mEncoding = Encoding
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SyncToNextFlush(ReadFrom As Readable, MaxCount As Integer = -1) As Boolean
		  ' Reads compressed bytes from ReadFrom until a possible full flush point is detected. If a
		  ' flush point is detected then this method returns True and the Total_In property will
		  ' reflect the point in the input where it was detected.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Inflater.SyncToNextFlush
		  
		  If Not IsOpen Then Return False
		  
		  Me.next_out = Nil
		  Me.avail_out = 0
		  
		  Dim count As Integer
		  Do
		    Dim sz As Integer
		    If MaxCount > -1 Then sz = Min(MaxCount - count, CHUNK_SIZE) Else sz = CHUNK_SIZE
		    Dim chunk As MemoryBlock = ReadFrom.Read(sz)
		    If chunk.Size <= 0 Then Return False
		    Me.avail_in = chunk.Size
		    Me.next_in = chunk
		    count = count + chunk.Size
		    mLastError = inflateSync(zstruct)
		  Loop Until mLastError <> Z_DATA_ERROR Or ReadFrom.EOF Or (MaxCount > -1 And count >= MaxCount)
		  
		  Return mLastError = Z_OK
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the sliding dictionary being maintained by inflate().
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Inflater.Dictionary
			  
			  If Not IsOpen Then Return Nil
			  Dim sz As UInt32 = 32768
			  Dim mb As New MemoryBlock(sz)
			  mLastError = inflateGetDictionary(zstruct, mb, sz)
			  If mLastError <> Z_OK Then Return Nil
			  mb.Size = sz
			  Return mb
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Sets the compression dictionary from the given uncompressed byte sequence. Must be set
			  ' immediately after the Constructor() or a call to Reset(), but before the first call to
			  ' Inflate(). The compressor and decompressor must use exactly the same dictionary (see
			  ' Deflater.Dictionary).
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Inflater.Dictionary
			  
			  If value = Nil Or Not IsOpen Then Return
			  mLastError = inflateSetDictionary(zstruct, value, value.Size)
			  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
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
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Inflater.Encoding
			  
			  Return mEncoding
			End Get
		#tag EndGetter
		Encoding As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mGZHeader
			End Get
		#tag EndGetter
		GZHeader As zlib.gz_headerp
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mGZHeader.Done = 1
			End Get
		#tag EndGetter
		HasHeader As Boolean
	#tag EndComputedProperty

	#tag Property, Flags = &h0
		#tag Note
			When set to True, corrupt or invalid compressed input will not be considered a fatal error,
			meaning you can keep providing more input in the hope of finding a valid compressed stream.
			The default is False, which treats all errors as fatal.
			
			See:
			https://github.com/charonn0/RB-zlib/wiki/zlib.Inflater.IgnoreChecksums
		#tag EndNote
		IgnoreChecksums As Boolean = False
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mEncoding As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mGZHeader As gz_headerp
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
