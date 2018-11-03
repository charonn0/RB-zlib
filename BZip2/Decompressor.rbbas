#tag Class
Protected Class Decompressor
Inherits bz2Engine
	#tag Method, Flags = &h0
		Sub Constructor(Verbosity As Integer = 0, LowMemoryMode As Boolean = False)
		  ' Construct a new Inflater instance using the specified Encoding. Encoding control,
		  ' among other things, the type of compression being used. (For GZip pass GZIP_ENCODING)
		  ' If the inflate engine could not be initialized an exception will be raised.
		  
		  // Calling the overridden superclass constructor.
		  // Constructor() -- From bz2Engine
		  Super.Constructor()
		  Dim small As Integer
		  If LowMemoryMode Then small = 1
		  mLastError = BZ2_bzDecompressInit(bzstruct, Verbosity, small)
		  If mLastError <> BZ_OK Then Raise New BZip2Exception(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Decompress(ReadFrom As Readable, WriteTo As Writeable, ReadCount As Integer = - 1) As Boolean
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
		      mLastError = BZ2_bzDecompress(bzstruct)
		      ' consume any output
		      Dim have As UInt32 = CHUNK_SIZE - bzstruct.avail_out
		      If have > 0 Then
		        If have <> outbuff.Size Then outbuff.Size = have
		        WriteTo.Write(outbuff)
		      End If
		      ' keep going until bzip2 doesn't use all the output space or an error
		    Loop Until mLastError <> BZ_OK Or bzstruct.avail_out <> 0
		    
		  Loop Until (ReadCount > -1 And count >= ReadCount) Or ReadFrom = Nil Or ReadFrom.EOF
		  
		  Return mLastError = BZ_OK Or mLastError = BZ_STREAM_END
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If IsOpen Then mLastError = BZ2_bzDecompressEnd(bzstruct)
		End Sub
	#tag EndMethod


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
