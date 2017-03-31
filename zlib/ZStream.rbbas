#tag Class
Protected Class ZStream
Implements zlib.CompressedStream
	#tag Method, Flags = &h0
		Sub Close()
		  // Part of the zlib.CompressedStream interface.
		  ' End the stream. If the stream is being written/compressed then all pending output is flushed.
		  ' If the stream is being read/decompressed then all pending output is discarded; check EOF to
		  ' determine whether there is pending output. After this method returns all calls to Read/Write 
		  ' will raise an exception.
		  
		  If mDeflater <> Nil Then Me.Flush(Z_FINISH)
		  mSource = Nil
		  mDestination = Nil
		  mDeflater = Nil
		  mInflater = Nil
		  mSourceMB = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Source As BinaryStream, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, CompressionStrategy As Integer = zlib.Z_DEFAULT_STRATEGY, Encoding As Integer = zlib.Z_DETECT, MemoryLevel As Integer = zlib.DEFAULT_MEM_LVL)
		  ' Constructs a ZStream from the Source BinaryStream. If the Source's current position is equal
		  ' to its length then compressed output will be appended, otherwise the Source will be used as 
		  ' input to be decompressed.
		  
		  If Source.Length = Source.Position Then 'compress into Source
		    If Encoding = Z_DETECT Then Encoding = DEFLATE_ENCODING
		    Me.Constructor(New Deflater(CompressionLevel, CompressionStrategy, Encoding, MemoryLevel), Source)
		  Else ' decompress from Source
		    If Encoding = Z_DETECT Then
		      Select Case True
		      Case Source.IsDeflated
		        Encoding = DEFLATE_ENCODING
		      Case Source.IsGZipped
		        Encoding = GZIP_ENCODING
		      Else
		        Encoding = RAW_ENCODING
		      End Select
		    End If
		    Me.Constructor(New Inflater(Encoding), Source)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Source As MemoryBlock, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, CompressionStrategy As Integer = zlib.Z_DEFAULT_STRATEGY, Encoding As Integer = zlib.Z_DETECT, MemoryLevel As Integer = zlib.DEFAULT_MEM_LVL)
		  ' Constructs a ZStream from the Source MemoryBlock. If the Source's size is zero then
		  ' compressed output will be appended, otherwise the Source will be used as input
		  ' to be decompressed.
		  
		  If Source.Size >= 0 Then
		    Me.Constructor(New BinaryStream(Source), CompressionLevel, CompressionStrategy, Encoding, MemoryLevel)
		  Else
		    Raise New zlibException(Z_DATA_ERROR) ' can't use memoryblocks of unknown size!!
		  End If
		  mSourceMB = Source
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor(Engine As zlib.Deflater, Destination As Writeable)
		  ' Construct a compression stream using the Engine and Destination parameters
		  mDeflater = Engine
		  mDestination = Destination
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor(Engine As zlib.Inflater, Source As Readable)
		  ' Construct a decompression stream using the Engine and Source parameters
		  mInflater = Engine
		  mSource = Source
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Create(OutputStream As FolderItem, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, CompressionStrategy As Integer = zlib.Z_DEFAULT_STRATEGY, Overwrite As Boolean = False, Encoding As Integer = zlib.DEFLATE_ENCODING, MemoryLevel As Integer = zlib.DEFAULT_MEM_LVL) As zlib.ZStream
		  ' Create a compression stream where compressed output is written to the OutputStream file.
		  
		  Return Create(BinaryStream.Create(OutputStream, Overwrite), CompressionLevel, CompressionStrategy, Encoding, MemoryLevel)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Create(OutputStream As Writeable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, CompressionStrategy As Integer = zlib.Z_DEFAULT_STRATEGY, Encoding As Integer = zlib.DEFLATE_ENCODING, MemoryLevel As Integer = zlib.DEFAULT_MEM_LVL) As zlib.ZStream
		  ' Create a compression stream where compressed output is written to the OutputStream object.
		  
		  Return New ZStream(New Deflater(CompressionLevel, CompressionStrategy, Encoding, MemoryLevel), OutputStream)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function CreatePipe(InputStream As Readable, OutputStream As Writeable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, CompressionStrategy As Integer = zlib.Z_DEFAULT_STRATEGY, Encoding As Integer = zlib.DEFLATE_ENCODING, MemoryLevel As Integer = zlib.DEFAULT_MEM_LVL) As zlib.ZStream
		  ' Create a compressed stream from two endpoints. Writing to the stream writes compressed bytes to
		  ' the OutputStream object; reading from the stream decompresses bytes from the InputStream object.
		  
		  Dim z As zlib.ZStream = Create(OutputStream, CompressionLevel, CompressionStrategy, Encoding, MemoryLevel)
		  If z = Nil Then Return Nil
		  z.mSource = InputStream
		  z.mInflater = New Inflater(Encoding)
		  Return z
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Deflater() As zlib.Deflater
		  Return mDeflater
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
		  Return mSource <> Nil And mSource.EOF And mInflater <> Nil And mInflater.Avail_In = 0 And mReadBuffer = ""
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
		  // Part of the zlib.CompressedStream interface.
		  ' Flushing may be:
		  '   Z_NO_FLUSH:      allows deflate to decide how much data to accumulate before producing output
		  '   Z_SYNC_FLUSH:    all pending output is flushed to the output buffer and the output is aligned on a byte boundary.
		  '   Z_PARTIAL_FLUSH: all pending output is flushed to the output buffer, but the output is not aligned to a byte boundary.
		  '   Z_BLOCK:         a deflate block is completed and emitted, but the output is not aligned on a byte boundary
		  '   Z_FULL_FLUSH:    like Z_SYNC_FLUSH, and the compression state is reset so that decompression can restart from this point.
		  '   Z_FINISH:        processing is finished and flushed.
		  
		  If mDeflater = Nil Then Raise New IOException
		  If Not mDeflater.Deflate(Nil, mDestination, Flushing) Then Raise New zlibException(mDeflater.LastError)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Inflater() As zlib.Inflater
		  Return mInflater
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsReadable() As Boolean
		  ' Returns True if the stream is in decompression mode
		  Return Me.Inflater <> Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsWriteable() As Boolean
		  ' Returns True if the stream is in compression mode
		  Return Me.Deflater <> Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  If mInflater <> Nil Then
		    Return mInflater.LastError
		  ElseIf mDeflater <> Nil Then
		    Return mDeflater.LastError
		  End IF
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(InputStream As FolderItem, Encoding As Integer = zlib.Z_DETECT) As zlib.ZStream
		  ' Create a decompression stream where the compressed input is read from the Source file.
		  
		  Return Open(BinaryStream.Open(InputStream), Encoding)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(InputStream As Readable, Encoding As Integer = zlib.Z_DETECT) As zlib.ZStream
		  ' Create a decompression stream where the compressed input is read from the InputStream object.
		  
		  Return New ZStream(New Inflater(Encoding), InputStream)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  // Part of the Readable interface.
		  ' Read Count decompressed bytes
		  
		  If mInflater = Nil Then Raise New IOException
		  Dim data As New MemoryBlock(0)
		  Dim ret As New BinaryStream(data)
		  Dim readsz As Integer = Count
		  If BufferedReading Then
		    If Count <= mReadBuffer.LenB Then
		      ret.Write(LeftB(mReadBuffer, Count))
		      Dim sz As Integer = mReadBuffer.LenB - Count
		      mReadBuffer = RightB(mReadBuffer, sz)
		      ret.Close
		      readsz = 0
		    Else
		      If mReadBuffer.LenB > 0 Then
		        ret.Write(mReadBuffer)
		        mReadBuffer = ""
		      End If
		      readsz = Max(Count, CHUNK_SIZE)
		    End If
		  End If
		  If readsz > 0 Then
		    If Not mInflater.Inflate(mSource, ret, readsz) Then Raise New zlibException(mInflater.LastError)
		    ret.Close
		    If BufferedReading Then
		      If data.Size >= Count Then
		        mReadBuffer = RightB(data, data.Size - Count)
		        data = LeftB(data, Count)
		      ElseIf Not Me.EOF Then
		        mReadBuffer = data
		        Return Me.Read(Count, encoding)
		      End If
		    End If
		  End If
		  
		  If data <> Nil Then Return DefineEncoding(data, encoding)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadAll(encoding As TextEncoding = Nil) As String
		  // Part of the zlib.CompressedStream interface.
		  ' Read compressed bytes until EOF, inflate and return any output
		  
		  If mInflater = Nil Then Raise New IOException
		  Dim data As New MemoryBlock(0)
		  Dim ret As New BinaryStream(data)
		  Dim prevmode As Boolean = mBufferedReading
		  If prevmode Then ret.Write(mReadBuffer)
		  Me.BufferedReading = False
		  Do Until Me.EOF
		    ret.Write(Me.Read(CHUNK_SIZE, encoding))
		  Loop
		  ret.Close
		  Me.BufferedReading = prevmode
		  Return data
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadError() As Boolean
		  // Part of the Readable interface.
		  Return mSource.ReadError Or (mInflater <> Nil And mInflater.LastError <> 0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadLine(encoding As TextEncoding = Nil, EOL As String = "") As String
		  // Part of the zlib.CompressedStream interface.
		  ' Reads one line of decompressed text from the compressed stream.
		  ' If EOL is not specified then the target platform EOL marker is used by default.
		  
		  If mInflater = Nil Then
		    Dim e As New NilObjectException
		    e.Message = "The stream is not readable."
		    Raise e
		  ElseIf Not BufferedReading Then 
		    Dim e As New IOException
		    e.Message = "The stream is not buffered."
		    Raise e
		  End If
		  
		  If EOL = "" Then
		    #If TargetWin32 Then
		      EOL = EndOfLine.Windows
		    #ElseIf TargetMacOS Then
		      EOL = EndOfLine.Macintosh
		    #ElseIf TargetLinux Then
		      EOL = EndOfLine.UNIX
		    #endif
		  End If
		  Dim data As New MemoryBlock(0)
		  Dim ret As New BinaryStream(data)
		  Dim lastchar As String
		  Do Until Me.EOF
		    Dim char As String = Me.Read(1, encoding)
		    If char = "" Then Continue
		    char = lastchar + char
		    Dim lineend As Integer = InstrB(char, EOL)
		    If lineend > 0 Then
		      lastchar = RightB(char, char.LenB - lineend - (EOL.LenB - 1))
		      char = LeftB(char, lineend + (EOL.LenB - 1))
		      ret.Write(char)
		      Exit Do
		    Else
		      lastchar = char
		    End If
		  Loop
		  If lastchar <> "" Then ret.Write(lastchar)
		  ret.Close
		  Return data
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Reset()
		  If mDeflater <> Nil Then mDeflater.Reset
		  If mInflater <> Nil Then mInflater.Reset
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(Data As String)
		  // Part of the Writeable interface.
		  ' Write Data to the compressed stream. 
		  ' NOTE: the Data may not be immediately written to the output; the compressor will write
		  ' to the output at times dictated by the compression parameters. Use the Flush method to
		  ' forcibly write pending output.
		  
		  If mDeflater = Nil Then Raise New IOException
		  Dim tmp As New BinaryStream(Data)
		  If Not mDeflater.Deflate(tmp, mDestination) Then Raise New zlibException(mDeflater.LastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function WriteError() As Boolean
		  // Part of the Writeable interface.
		  Return mDestination.WriteError Or (mDeflater <> Nil And mDeflater.LastError <> 0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub WriteLine(Data As String, EOL As String = "")
		  // Part of the zlib.CompressedStream interface.
		  ' Write Data to the compressed stream followed by an EOL marker.
		  ' If EOL is not specified then the target platform EOL marker is used by default.
		  
		  If mDeflater = Nil Then Raise New IOException
		  If EOL = "" Then
		    #If TargetWin32 Then
		      EOL = EndOfLine.Windows
		    #ElseIf TargetMacOS Then
		      EOL = EndOfLine.Macintosh
		    #ElseIf TargetLinux Then
		      EOL = EndOfLine.UNIX
		    #endif
		  End If
		  Me.Write(Data + EOL)
		End Sub
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mBufferedReading
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If Not value Then mReadBuffer = ""
			  mBufferedReading = value
			End Set
		#tag EndSetter
		BufferedReading As Boolean
	#tag EndComputedProperty

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
			  If mDeflater <> Nil Then mDeflater.Dictionary = value
			  If mInflater <> Nil Then mInflater.Dictionary = value
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
		Private mBufferedReading As Boolean = True
	#tag EndProperty

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
		Private mReadBuffer As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mSource As Readable
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSourceMB As MemoryBlock
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mDeflater <> Nil Then
			    Return (mDeflater.Total_Out * 100 / mDeflater.Total_In)
			  ElseIf mInflater <> Nil Then
			    Return (mInflater.Total_In * 100 / mInflater.Total_Out)
			  End If
			  Return 0.0
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

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mDeflater <> Nil Then
			    Return mDeflater.Total_In
			  ElseIf mInflater <> Nil Then
			    Return mInflater.Total_In
			  End If
			End Get
		#tag EndGetter
		TotalIn As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mDeflater <> Nil Then
			    Return mDeflater.Total_Out
			  ElseIf mInflater <> Nil Then
			    Return mInflater.Total_Out
			  End If
			End Get
		#tag EndGetter
		TotalOut As UInt32
	#tag EndComputedProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="BufferedReading"
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
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
