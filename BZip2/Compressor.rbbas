#tag Class
Protected Class Compressor
Inherits bz2Engine
	#tag Method, Flags = &h0
		Function Compress(ReadFrom As Readable, WriteTo As Writeable, ReadCount As Integer = - 1) As Boolean
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
		    Dim sz As Integer
		    If ReadCount > -1 Then sz = Min(ReadCount - count, CHUNK_SIZE) Else sz = CHUNK_SIZE
		    If ReadFrom <> Nil And sz > 0 Then chunk = ReadFrom.Read(sz) Else chunk = ""
		    
		    bzstruct.avail_in = chunk.Size
		    bzstruct.next_in = chunk
		    count = count + chunk.Size
		    
		    Do
		      ' provide more output space
		      If outbuff.Size <> CHUNK_SIZE Then outbuff.Size = CHUNK_SIZE
		      bzstruct.next_out = outbuff
		      bzstruct.avail_out = outbuff.Size
		      mLastError = BZ2_bzCompress(bzstruct, BZ_RUN)
		      ' consume any output
		      Dim have As UInt32 = CHUNK_SIZE - bzstruct.avail_out
		      If have > 0 Then
		        If have <> outbuff.Size Then outbuff.Size = have
		        WriteTo.Write(outbuff)
		      End If
		      ' keep going until an error
		    Loop Until mLastError <> BZ_RUN_OK Or (ReadCount > -1 And count >= ReadCount And bzstruct.avail_out <> 0)
		    
		  Loop Until (ReadCount > -1 And count >= ReadCount) Or ReadFrom = Nil Or ReadFrom.EOF
		  
		  Return mLastError = BZ_RUN_OK Or (mLastError = BZ_PARAM_ERROR And ReadFrom <> Nil And ReadFrom.EOF)
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(BlockSize100K As Integer = BZip2.BZ_DEFAULT_COMPRESSION, Verbosity As Integer = 0, WorkFactor As Integer = 0)
		  ' Construct a new Compressor instance using the specified compression options.
		  ' If the bzip2 engine could not be initialized an exception will be raised.
		  
		  // Calling the overridden superclass constructor.
		  // Constructor() -- From bz2Engine
		  Super.Constructor()
		  If BlockSize100K < 0 Then BlockSize100K = BZ_DEFAULT_COMPRESSION
		  ' Open the compressed stream
		  mLastError = BZ2_bzCompressInit(bzstruct, BlockSize100K, Verbosity, WorkFactor)
		  
		  If mLastError <> BZ_OK Then Raise New BZip2Exception(mLastError)
		  mLevel = BlockSize100K
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If IsOpen Then mLastError = BZ2_bzCompressEnd(bzstruct)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Finish(WriteTo As Writeable) As Boolean
		  If Not IsOpen Then Return False
		  
		  Dim outbuff As New MemoryBlock(CHUNK_SIZE)
		  bzstruct.avail_in = 0
		  bzstruct.next_in = Nil
		  
		  Do
		    ' provide more output space
		    If outbuff.Size <> CHUNK_SIZE Then outbuff.Size = CHUNK_SIZE
		    bzstruct.next_out = outbuff
		    bzstruct.avail_out = outbuff.Size
		    mLastError = BZ2_bzCompress(bzstruct, BZ_FINISH)
		    ' consume any output
		    Dim have As UInt32 = CHUNK_SIZE - bzstruct.avail_out
		    If have > 0 Then
		      If have <> outbuff.Size Then outbuff.Size = have
		      WriteTo.Write(outbuff)
		    End If
		    ' keep going until an error
		  Loop Until mLastError <> BZ_FINISH_OK
		  
		  Return mLastError = BZ_STREAM_END
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Flush(WriteTo As Writeable) As Boolean
		  If Not IsOpen Then Return False
		  
		  Dim outbuff As New MemoryBlock(CHUNK_SIZE)
		  bzstruct.avail_in = 0
		  bzstruct.next_in = Nil
		  
		  Do
		    ' provide more output space
		    If outbuff.Size <> CHUNK_SIZE Then outbuff.Size = CHUNK_SIZE
		    bzstruct.next_out = outbuff
		    bzstruct.avail_out = outbuff.Size
		    mLastError = BZ2_bzCompress(bzstruct, BZ_FLUSH)
		    ' consume any output
		    Dim have As UInt32 = CHUNK_SIZE - bzstruct.avail_out
		    If have > 0 Then
		      If have <> outbuff.Size Then outbuff.Size = have
		      WriteTo.Write(outbuff)
		    End If
		    ' keep going until an error
		  Loop Until mLastError <> BZ_FLUSH_OK' Or mLastError < 0
		  
		  Return mLastError = BZ_RUN
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mLevel
			End Get
		#tag EndGetter
		Level As Integer
	#tag EndComputedProperty

	#tag Property, Flags = &h1
		Protected mLevel As Integer = BZip2.BZ_DEFAULT_COMPRESSION
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
