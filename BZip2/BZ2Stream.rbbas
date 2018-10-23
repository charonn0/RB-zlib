#tag Class
Protected Class BZ2Stream
Implements Readable,Writeable
	#tag Method, Flags = &h0
		Sub Close()
		  ' End the stream. If the stream is being written/compressed then all pending output is flushed.
		  ' If the stream is being read/decompressed then all pending output is discarded; check EOF to
		  ' determine whether there is pending output. After this method returns all calls to Read/Write
		  ' will raise an exception.
		  
		  If mCompressor <> Nil Then
		    Try
		      Call mCompressor.Finish(mDestination)
		    Catch
		    End Try
		  End If
		  mSource = Nil
		  mDestination = Nil
		  mCompressor = Nil
		  mDecompressor = Nil
		  mSourceMB = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Source As BinaryStream, CompressionLevel As Integer = BZip2.BZ_DEFAULT_COMPRESSION)
		  ' Constructs a BZ2Stream from the Source BinaryStream. If the Source's current position is equal
		  ' to its length then compressed output will be appended, otherwise the Source will be used as
		  ' input to be decompressed.
		  
		  If Source.Length = Source.Position Then 'compress into Source
		    Me.Constructor(New Compressor(CompressionLevel), Source)
		  Else ' decompress from Source
		    Me.Constructor(New Decompressor(), Source)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor(Engine As BZip2.Compressor, Destination As Writeable)
		  ' Construct a compression stream using the Engine and Destination parameters
		  mCompressor = Engine
		  mDestination = Destination
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor(Engine As BZip2.Decompressor, Source As Readable)
		  ' Construct a decompression stream using the Engine and Source parameters
		  mDecompressor = Engine
		  mSource = Source
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Source As MemoryBlock, CompressionLevel As Integer = BZip2.BZ_DEFAULT_COMPRESSION)
		  ' Constructs a BZ2Stream from the Source MemoryBlock. If the Source's size is zero then
		  ' compressed output will be appended, otherwise the Source will be used as input
		  ' to be decompressed.
		  
		  If Source.Size >= 0 Then
		    Me.Constructor(New BinaryStream(Source), CompressionLevel)
		  Else
		    Raise New BZip2Exception(BZ_DATA_ERROR) ' can't use memoryblocks of unknown size!!
		  End If
		  mSourceMB = Source
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Create(OutputStream As FolderItem, CompressionLevel As Integer = BZip2.BZ_DEFAULT_COMPRESSION, Overwrite As Boolean = False) As BZip2.BZ2Stream
		  ' Create a compression stream where compressed output is written to the OutputStream file.
		  
		  Return Create(BinaryStream.Create(OutputStream, Overwrite), CompressionLevel)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Create(OutputStream As Writeable, CompressionLevel As Integer = BZip2.BZ_DEFAULT_COMPRESSION) As BZip2.BZ2Stream
		  ' Create a compression stream where compressed output is written to the OutputStream object.
		  
		  Return New BZ2Stream(New Compressor(CompressionLevel), OutputStream)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function CreatePipe(InputStream As Readable, OutputStream As Writeable, CompressionLevel As Integer = BZip2.BZ_DEFAULT_COMPRESSION) As BZip2.BZ2Stream
		  ' Create a compressed stream from two endpoints. Writing to the stream writes compressed bytes to
		  ' the OutputStream object; reading from the stream decompresses bytes from the InputStream object.
		  
		  Dim z As BZip2.BZ2Stream = Create(OutputStream, CompressionLevel)
		  If z = Nil Then Return Nil
		  z.mSource = InputStream
		  z.mDecompressor = New Decompressor()
		  Return z
		  
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
		  ' Returns True if there is no more output to read (decompression only)
		  Return mSource <> Nil And mSource.EOF And mDecompressor <> Nil And mDecompressor.Avail_In = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Flush()
		  // Part of the Writeable interface.
		  If mCompressor <> Nil Then Call mCompressor.Flush(mDestination)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsReadable() As Boolean
		  ' Returns True if the stream is in decompression mode
		  Return mDecompressor <> Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsWriteable() As Boolean
		  ' Returns True if the stream is in compression mode
		  Return mCompressor <> Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  If mDecompressor <> Nil Then
		    Return mDecompressor.LastError
		  ElseIf mCompressor <> Nil Then
		    Return mCompressor.LastError
		  End IF
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(InputStream As FolderItem) As BZip2.BZ2Stream
		  ' Create a decompression stream where the compressed input is read from the Source file.
		  
		  Return Open(BinaryStream.Open(InputStream))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(InputStream As Readable) As BZip2.BZ2Stream
		  ' Create a decompression stream where the compressed input is read from the InputStream object.
		  
		  Return New BZ2Stream(New Decompressor, InputStream)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  // Part of the Readable interface.
		  Dim data As New MemoryBlock(0)
		  Dim ret As New BinaryStream(data)
		  If Not mDecompressor.Decompress(mSource, ret, Count) Then Raise New BZip2Exception(mDecompressor.LastError)
		  ret.Close
		  If data <> Nil Then Return DefineEncoding(data, encoding)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadError() As Boolean
		  // Part of the Readable interface.
		  Return mSource.ReadError Or (mDecompressor <> Nil And mDecompressor.LastError <> 0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(Data As String)
		  // Part of the Writeable interface.
		  ' Write Data to the compressed stream.
		  
		  If mCompressor = Nil Then Raise New IOException
		  Dim tmp As New BinaryStream(Data)
		  If Not mCompressor.Compress(tmp, mDestination) Then Raise New BZip2Exception(mCompressor.LastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function WriteError() As Boolean
		  // Part of the Writeable interface.
		  Return mDestination.WriteError Or (mCompressor <> Nil And mCompressor.LastError <> 0)
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mCompressor <> Nil Then Return mCompressor.Level
			End Get
		#tag EndGetter
		Level As Integer
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mCompressor As BZip2.Compressor
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDecompressor As BZip2.Decompressor
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDestination As Writeable
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSource As Readable
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSourceMB As MemoryBlock
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mCompressor <> Nil Then
			    Return mCompressor.Total_In
			  ElseIf mDecompressor <> Nil Then
			    Return mDecompressor.Total_In
			  End If
			End Get
		#tag EndGetter
		TotalIn As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mCompressor <> Nil Then
			    Return mCompressor.Total_Out
			  ElseIf mDecompressor <> Nil Then
			    Return mDecompressor.Total_Out
			  End If
			End Get
		#tag EndGetter
		TotalOut As UInt32
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
