#tag Class
Protected Class Inflater
Inherits FlateEngine
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
		Function GetHeader(ByRef HeaderStruct As zlib.gz_headerp) As Boolean
		  If Not IsOpen Then Return False
		  mLastError = inflateGetHeader(zstream, HeaderStruct)
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
		Function Inflate(Source As Readable, WriteTo As Writeable) As Boolean
		  Dim outbuff As New MemoryBlock(CHUNK_SIZE)
		  Do
		    Dim chunk As MemoryBlock = Source.Read(CHUNK_SIZE)
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
		  Loop Until Source.EOF
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function InflateMark() As UInt32
		  If Not IsOpen Then Return 0
		  Return inflateMark(zstream)
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
		Function SyncToNextFlush() As Boolean
		  ' Skips invalid compressed data until a possible full flush point can be found, or until all available input is skipped.
		  
		  If Not IsOpen Then Return False
		  mLastError = inflateSync(zstream)
		  Return mLastError = Z_OK
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
