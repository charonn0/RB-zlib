#tag Class
Private Class ZStreamPtr
	#tag Method, Flags = &h0
		Sub Close()
		  If Me.IsDeflateStream Then ' Compressing
		    Call Me.Poll(Z_SYNC_FLUSH)
		    mLastError = zlib.deflateEnd(zstream)
		  Else
		    mLastError = zlib.inflateEnd(zstream)
		  End If
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(ByRef zOpaque As z_stream, Deflate As Boolean)
		  zstream = zOpaque
		  mDeflate = Deflate
		  InBuffer = New MemoryBlock(BufferSize)
		  OutBuffer = New MemoryBlock(BufferSize)
		  zstream.next_in = InBuffer
		  zstream.avail_in = 0
		  zstream.next_out = OutBuffer
		  zstream.avail_out = OutBuffer.Size
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Flush()
		  While Me.Poll = Z_OK
		    App.YieldToNextThread
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsDeflateStream() As Boolean
		  Return mDeflate
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Poll(Flushing As Integer = zlib.Z_NO_FLUSH) As Integer
		  If zstream.avail_in <= 0 Then ' more input needed
		    InBuffer = Nil
		    If RaiseEvent DataNeeded(InBuffer, BufferSize) Then
		      zstream.next_in = InBuffer
		      zstream.avail_in = InBuffer.Size
		    End If
		  End If
		  
		  If zstream.avail_out < OutBuffer.Size Then ' output available
		    Dim mb As MemoryBlock = OutBuffer.StringValue(0, BufferSize - zstream.avail_out)
		    RaiseEvent DataAvailable(mb)
		    OutBuffer = New MemoryBlock(BufferSize)
		    zstream.next_out = OutBuffer
		    zstream.avail_out = OutBuffer.Size
		  End If
		  
		  If mDeflate Then
		    mLastError = zlib.deflate(zstream, Flushing)
		  Else
		    mLastError = zlib.inflate(zstream, Flushing)
		  End If
		  Return mLastError
		  
		  
		End Function
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event DataAvailable(NewData As MemoryBlock)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event DataNeeded(ByRef Data As MemoryBlock, MaxLength As Integer) As Boolean
	#tag EndHook


	#tag Property, Flags = &h21
		Private InBuffer As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDeflate As Boolean
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private OutBuffer As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected zstream As z_stream
	#tag EndProperty


	#tag Constant, Name = BufferSize, Type = Double, Dynamic = False, Default = \"262144", Scope = Private
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
