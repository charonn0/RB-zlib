#tag Class
Protected Class ZStream
Implements Readable,Writeable
	#tag Method, Flags = &h0
		Sub Close()
		  If zstream <> Nil Then 
		    zstream.Close()
		    mLastError = zstream.LastError
		  End If
		  zstream = Nil
		  mReadBuffer = Nil
		  mOutStream = Nil
		  mInStream = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor(ByRef zStruct As z_stream, Deflate As Boolean)
		  zstream = New ZStreamPtr(zStruct, Deflate)
		  AddHandler zstream.DataAvailable, WeakAddressOf _DataAvailableHandler
		  AddHandler zstream.DataNeeded, WeakAddressOf _DataNeededHandler
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Create(Output As Writeable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION) As zlib.ZStream
		  Dim zstruct As z_stream
		  zstruct.opaque = GenOpaque()
		  Dim err As Integer = deflateInit_(zstruct, CompressionLevel, zlib.Version, zstruct.Size)
		  If err = Z_OK Then
		    Dim stream As New zlib.ZStream(zstruct, True)
		    stream.mOutStream = Output
		    Return stream
		  Else
		    Raise New zlibException(err)
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  Me.Close()
		End Sub
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
		  Do Until mInStream.EOF
		    mLastError = zstream.Poll(Z_PARTIAL_FLUSH)
		  Loop Until mLastError <> Z_OK
		  mOutStream.Flush
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
		    Dim stream As New zlib.ZStream(zstruct, False)
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
		  
		  Dim bs As BinaryStream
		  If mOutStream = Nil Then 
		    mReadBuffer = New MemoryBlock(0)
		    bs = New BinaryStream(mReadBuffer)
		    bs.Position = bs.Length
		    mOutStream = bs
		  End If
		  
		  Do Until mInStream.EOF
		    mLastError = zstream.Poll()
		  Loop Until mLastError <> Z_OK
		  
		  If mLastError = Z_OK Or mLastError = Z_STREAM_END Then
		    If bs = Nil Then bs = BinaryStream(mOutStream)
		    bs.Position = 0
		    Dim data As String = bs.Read(Count, encoding)
		    bs.Position = Min(bs.Length - Count, Count)
		    Return data
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
		  
		  Dim bs As BinaryStream
		  If mInStream = Nil Then
		    bs = New BinaryStream(text)
		    mInStream = bs
		  Else
		    bs = BinaryStream(mInStream)
		    bs.Position = bs.Length
		    bs.Write(text)
		  End If
		  bs.Position = 0
		  Do Until mInStream.EOF
		    mLastError = zstream.Poll
		  Loop Until mLastError <> Z_OK
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function WriteError() As Boolean
		  // Part of the Writeable interface.
		  Return mOutStream.WriteError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub _DataAvailableHandler(Sender As ZStreamPtr, NewData As MemoryBlock)
		  #pragma Unused Sender
		  If NewData <> Nil Then 
		    mOutStream.Write(NewData)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function _DataNeededHandler(Sender As ZStreamPtr, ByRef Data As MemoryBlock, MaxLength As Integer) As Boolean
		  #pragma Unused Sender
		  If mInStream <> Nil Then 
		    Data = mInStream.Read(MaxLength)
		  End If
		  Return Data <> Nil And Data.Size > 0
		End Function
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mInStream As Readable
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mOutStream As Writeable
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mReadBuffer As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h21
		Private zstream As ZStreamPtr
	#tag EndProperty


	#tag Constant, Name = BufferSize, Type = Double, Dynamic = False, Default = \"262144", Scope = Private
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
