#tag Class
Protected Class Inflater
Inherits FlateEngine
	#tag Method, Flags = &h0
		Sub Constructor(WindowBits As Integer = zlib.DEFLATE_ENCODING)
		  zstruct.zalloc = Nil
		  zstruct.zfree = Nil
		  zstruct.opaque = Nil
		  zstruct.avail_in = 0
		  zstruct.next_in = Nil
		  If WindowBits = zlib.DEFLATE_ENCODING Then
		    mLastError = inflateInit_(zstruct, zlib.Version, zstruct.Size)
		  Else
		    mLastError = inflateInit2_(zstruct, WindowBits, zlib.Version, zstruct.Size)
		  End If
		  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(CopyStream As zlib.Inflater)
		  mLastError = inflateCopy(zstruct, CopyStream.zstruct)
		  If mLastError <> Z_OK Then Raise New zlibException(mLastError)
		  mDictionary = CopyStream.mDictionary
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If IsOpen Then mLastError = zlib.inflateEnd(zstruct)
		  zstruct.zfree = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetHeader(ByRef HeaderStruct As zlib.gz_headerp) As Boolean
		  ' This method must be called BEFORE Inflate. Provide a gz_headerp structure to contain the 
		  ' gzip header for the stream (if any). zlib will update the referenced structure as the 
		  ' stream is processed.
		  
		  If Not IsOpen Then Return False
		  mLastError = inflateGetHeader(zstruct, HeaderStruct)
		  Return mLastError = Z_OK
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Inflate(Data As MemoryBlock) As MemoryBlock
		  Dim ret As New MemoryBlock(0)
		  Dim retstream As New BinaryStream(ret)
		  Dim instream As New BinaryStream(Data)
		  If Not Me.Inflate(instream, retstream) Then Return Nil
		  retstream.Close
		  Return ret
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Inflate(ReadFrom As Readable, WriteTo As Writeable) As Boolean
		  ' Reads from Source until Source.EOF and writes all output to WriteTo
		  Dim outbuff As New MemoryBlock(CHUNK_SIZE)
		  Do
		    Dim chunk As MemoryBlock
		    If ReadFrom <> Nil Then chunk = ReadFrom.Read(CHUNK_SIZE) Else chunk = ""
		    zstruct.avail_in = chunk.Size
		    zstruct.next_in = chunk
		    Do
		      zstruct.next_out = outbuff
		      zstruct.avail_out = outbuff.Size
		      mLastError = zlib.inflate(zstruct, Z_NO_FLUSH)
		      Dim have As UInt32 = CHUNK_SIZE - zstruct.avail_out
		      If have > 0 Then WriteTo.Write(outbuff.StringValue(0, have))
		    Loop Until mLastError <> Z_OK Or zstruct.avail_out <> 0
		  Loop Until ReadFrom = Nil Or ReadFrom.EOF
		  Select Case mLastError
		  Case Z_OK, Z_STREAM_END, Z_BUF_ERROR
		    Return True
		  Else
		    Return False
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function InflateMark() As UInt32
		  If Not IsOpen Then Return 0
		  Return inflateMark(zstruct)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Reset(WindowBits As Integer = 0)
		  If Not IsOpen Then Return
		  If WindowBits = 0 Then
		    mLastError = inflateReset(zstruct)
		  Else
		    mLastError = inflateReset2(zstruct, WindowBits)
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
