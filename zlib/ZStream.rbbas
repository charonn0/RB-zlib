#tag Class
Protected Class ZStream
Implements Readable,Writeable
	#tag Method, Flags = &h0
		Sub Close()
		  If mOutStream <> Nil Then ' Compressing
		    Do Until zstream.avail_in <= 0
		      mLastError = zlib.deflate(zstream, Z_PARTIAL_FLUSH)
		    Loop Until mLastError <> Z_OK
		    If zstream.avail_out > 0 Then
		      Dim outdata As MemoryBlock = zstream.next_out
		      mOutstream.Write(outdata.StringValue(0, zstream.avail_out))
		    End If
		  Else
		    mLastError = zlib.inflate(zstream, Z_FINISH)
		  End If
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor(zStruct As z_stream)
		  zstream = zStruct
		  mOutData = New MemoryBlock(262144)
		  zstream.next_out = mOutData
		  zstream.avail_out = mOutData.Size
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Create(Output As Writeable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION) As zlib.ZStream
		  Dim zstruct As z_stream
		  zstruct.opaque = GenOpaque()
		  Dim err As Integer = deflateInit_(zstruct, CompressionLevel, zlib.Version, zstruct.Size)
		  If err = Z_OK Then
		    Dim stream As New zlib.ZStream(zstruct)
		    stream.mOutStream = Output
		    Return stream
		  Else
		    Raise New zlibException(err)
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EOF() As Boolean
		  // Part of the Readable interface.
		  Return mInStream.EOF
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Flush()
		  // Part of the Writeable interface.
		  Do Until zstream.avail_in <= 0
		    mLastError = zlib.deflate(zstream, Z_PARTIAL_FLUSH)
		  Loop Until mLastError <> Z_OK
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function GenOpaque() As Ptr
		  Static opaque As Integer
		  opaque = opaque + 1
		  Return Ptr(opaque)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(InputStream As Readable) As zlib.ZStream
		  Dim zstruct As z_stream
		  zstruct.opaque = GenOpaque()
		  Dim err As Integer = inflateInit_(zstruct, zlib.Version, zstruct.Size)
		  If err = Z_OK Then
		    Dim stream As New zlib.ZStream(zstruct)
		    stream.mInStream = InputStream
		    Return stream
		  Else
		    Raise New zlibException(err)
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  // Part of the Readable interface.
		  Dim zdata As MemoryBlock = mInStream.Read(Count)
		  zstream.next_in = zdata
		  zstream.avail_in = zdata.Size
		  
		  Dim odata As New MemoryBlock(Count * 4)
		  zstream.next_out = odata
		  zstream.avail_out = odata.Size
		  mLastError = inflate(zstream, 0)
		  
		  If mLastError = Z_OK Or mLastError = Z_STREAM_END Then
		    Return DefineEncoding(odata, encoding)
		  Else
		    Raise New zlibException(mLastError)
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadError() As Boolean
		  // Part of the Readable interface.
		  Return mInStream.ReadError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(text As String)
		  // Part of the Writeable interface.
		  'writes to a compressed stream
		  Dim indata As New MemoryBlock(text.LenB)
		  zstream.next_in = indata
		  zstream.avail_in = indata.Size
		  'Dim outdata As New MemoryBlock(indata.Size * 1.1 + 13)
		  'zstream.next_out = outdata
		  'zstream.avail_out = outdata.Size
		  
		  Do Until zstream.avail_in <= 0
		    mLastError = zlib.deflate(zstream, Z_NO_FLUSH)
		  Loop Until mLastError <> Z_OK
		  
		  If zstream.total_out > 0 Then
		    Dim data As MemoryBlock = zstream.next_out
		    data = data.StringValue(0, zstream.total_out)
		    mOutstream.Write(data)
		  End If
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function WriteError() As Boolean
		  // Part of the Writeable interface.
		  Return mOutStream.WriteError
		End Function
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mInStream As Readable
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mOutData As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mOutStream As Writeable
	#tag EndProperty

	#tag Property, Flags = &h21
		Private zstream As z_stream
	#tag EndProperty


	#tag Constant, Name = Z_NO_FLUSH, Type = Double, Dynamic = False, Default = \"0", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_STREAM_END, Type = Double, Dynamic = False, Default = \"1", Scope = Protected
	#tag EndConstant


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
