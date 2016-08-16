#tag Class
Protected Class ZStream
Implements Readable,Writeable
	#tag Method, Flags = &h0
		Sub Close()
		  If mDeflater <> Nil Then Me.Flush(Z_FINISH)
		  mSource = Nil
		  mDestination = Nil
		  mDeflater = Nil
		  mInflater = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor(Engine As zlib.Deflater, Destination As Writeable)
		  mDeflater = Engine
		  mDestination = Destination
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor(Engine As zlib.Inflater, Source As Readable)
		  mInflater = Engine
		  mSource = Source
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Create(Output As Writeable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, CompressionStrategy As Integer = zlib.Z_DEFAULT_STRATEGY, WindowBits As Integer = 15, MemoryLevel As Integer = 8) As zlib.ZStream
		  Dim zstruct As Deflater
		  If CompressionStrategy <> Z_DEFAULT_STRATEGY Or WindowBits <> 15 Or MemoryLevel <> 8 Then
		    ' Open the compressed stream using custom options
		    zstruct =  New Deflater(CompressionLevel, CompressionStrategy, WindowBits, MemoryLevel)
		    
		  Else
		    ' process zlib-wrapped deflate data
		    zstruct = New Deflater(CompressionLevel)
		    
		  End If
		  Return New zlib.ZStream(zstruct, Output)
		  
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
		  Return mSource.EOF And (mInflater <> Nil And mInflater.Avail_In = 0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Flush() Implements Writeable.Flush
		  // Part of the Writeable interface.
		  ' All pending output is flushed to the output buffer and the output is aligned on a byte boundary.
		  ' Flushing may degrade compression so it should be used only when necessary. This completes the
		  ' current deflate block and follows it with an empty stored block that is three bits plus filler bits
		  ' to the next byte, followed by four bytes (00 00 ff ff).
		  Me.Flush(Z_SYNC_FLUSH)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Flush(Flushing As Integer)
		  ' Flushing may be:
		  '   Z_NO_FLUSH:      allows deflate to decide how much data to accumulate before producing output
		  '   Z_SYNC_FLUSH:    all pending output is flushed to the output buffer and the output is aligned on a byte boundary.
		  '   Z_PARTIAL_FLUSH: all pending output is flushed to the output buffer, but the output is not aligned to a byte boundary.
		  '   Z_BLOCK:         a deflate block is completed and emitted, but the output is not aligned on a byte boundary
		  '   Z_FULL_FLUSH:    like Z_SYNC_FLUSH, and the compression state is reset so that decompression can restart from this point.
		  '   Z_FINISH:        processing is finished and flushed.
		  
		  If mDeflater <> Nil Then
		    mDestination.Write(mDeflater.Deflate("", Flushing))
		  Else
		    Raise New IOException
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(InputStream As Readable, WindowBits As Integer = 0) As zlib.ZStream
		  ' process zlib-wrapped deflate data
		  Dim zstruct As New Inflater(WindowBits)
		  Return New zlib.ZStream(zstruct, InputStream)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  // Part of the Readable interface.
		  ' Read Count compressed bytes, inflate and return them
		  Dim data As String
		  If mInflater <> Nil Then
		    Dim tmp As String = mSource.Read(Count)
		    data = mInflater.Inflate(tmp)
		    If encoding <> Nil Then data = DefineEncoding(data, encoding)
		    Return data
		  Else
		    Raise New IOException
		  End IF
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadError() As Boolean
		  // Part of the Readable interface.
		  Return mSource.ReadError Or (mInflater <> Nil And mInflater.LastError <> 0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(text As String)
		  // Part of the Writeable interface.
		  ' Compress text and write it to the output
		  Dim data As New BinaryStream(text)
		  If mDeflater <> Nil And Not mDeflater.Deflate(data, mDestination) Then
		    Raise New IOException
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function WriteError() As Boolean
		  // Part of the Writeable interface.
		  Return mDestination.WriteError Or (mDeflater <> Nil And mDeflater.LastError <> 0)
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mDeflater <> Nil Then
			    Return mDeflater.Dictionary
			  ElseIf mInflater <> Nil Then
			    Return mInflater.Dictionary
			  End If
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If mDeflater <> Nil Then
			    mDeflater.Dictionary = value
			  ElseIf mInflater <> Nil Then
			    mInflater.Dictionary = value
			  End If
			End Set
		#tag EndSetter
		Dictionary As MemoryBlock
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mDeflater <> Nil Then Return mDeflater.Level
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If mDeflater <> Nil Then mDeflater.Level = value
			End Set
		#tag EndSetter
		Level As Integer
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mDeflater As zlib.Deflater
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDestination As Writeable
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mInflater As zlib.Inflater
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSource As Readable
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mDeflater = Nil Then Return 0.0
			  return (mDeflater.Total_Out * 100 / mDeflater.Total_In)
			End Get
		#tag EndGetter
		Ratio As Single
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mDeflater <> Nil Then Return mDeflater.Strategy
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If mDeflater <> Nil Then mDeflater.Strategy = value
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
			Name="Ratio"
			Group="Behavior"
			Type="Single"
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
