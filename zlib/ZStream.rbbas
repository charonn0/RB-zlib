#tag Class
Protected Class ZStream
Implements Readable,Writeable
	#tag Method, Flags = &h0
		Sub Close()
		  ' End the stream. If the stream is being written/compressed then all pending output is
		  ' flushed. If the stream is being read/decompressed then all pending output is discarded;
		  ' check EOF to determine whether there is pending output. After this method returns all
		  ' calls to Read/Write will raise an exception.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Close
		  
		  If mDeflater <> Nil Then
		    Try
		      Me.Flush(Z_FINISH)
		    Catch
		    End Try
		  End If
		  mSource = Nil
		  mDestination = Nil
		  mDeflater = Nil
		  mInflater = Nil
		  mSourceMB = Nil
		  mReadBuffer = ""
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Source As BinaryStream, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Encoding As Integer = zlib.Z_DETECT)
		  ' Constructs a ZStream from the Source BinaryStream. If the Source's current position is
		  ' equal to its length then compressed output will be appended, otherwise the Source will
		  ' be used as input to be decompressed.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Constructor
		  
		  If Source.Length = Source.Position Then 'compress into Source
		    If Encoding = Z_DETECT Then Encoding = DEFLATE_ENCODING
		    Me.Constructor(New Deflater(CompressionLevel, Z_DEFAULT_STRATEGY, Encoding, DEFAULT_MEM_LVL), Source)
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
		Sub Constructor(Source As MemoryBlock, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Encoding As Integer = zlib.Z_DETECT)
		  ' Constructs a ZStream from the Source MemoryBlock. If the Source's size is zero then compressed
		  ' output will be appended, otherwise the Source will be used as input to be decompressed.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Constructor
		  
		  If Source.Size >= 0 Then
		    Me.Constructor(New BinaryStream(Source), CompressionLevel, Encoding)
		  Else
		    Raise New zlibException(Z_DATA_ERROR) ' can't use memoryblocks of unknown size!!
		  End If
		  mSourceMB = Source
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor(Engine As zlib.Deflater, Destination As Writeable)
		  ' Construct a compression stream using the Engine and Destination parameters.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Constructor
		  
		  mDeflater = Engine
		  mDestination = Destination
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor(Engine As zlib.Inflater, Source As Readable)
		  ' Construct a decompression stream using the Engine and Source parameters.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Constructor
		  
		  mInflater = Engine
		  mSource = Source
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Create(OutputStream As FolderItem, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Overwrite As Boolean = False, Encoding As Integer = zlib.DEFLATE_ENCODING) As zlib.ZStream
		  ' Create a compression stream where compressed output is written to the OutputStream file.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Create
		  
		  Return Create(BinaryStream.Create(OutputStream, Overwrite), CompressionLevel, Encoding)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Create(OutputStream As Writeable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Encoding As Integer = zlib.DEFLATE_ENCODING) As zlib.ZStream
		  ' Create a compression stream where compressed output is written to the OutputStream object.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Create
		  
		  Return New ZStream(New Deflater(CompressionLevel, Z_DEFAULT_STRATEGY, Encoding, DEFAULT_MEM_LVL), OutputStream)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  Me.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function EndOfFile() As Boolean
		  // Part of the Readable interface as of 2019r2
		  Return Me.EOF()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EOF() As Boolean
		  // Part of the Readable interface.
		  ' Returns True if there is no more output to read (decompression only)
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.EOF
		  
		  Return mSource <> Nil And mSource.EOF And mInflater <> Nil And mInflater.Avail_In = 0 And mReadBuffer = ""
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Flush() Implements Writeable.Flush
		  // Part of the Writeable interface.
		  ' All pending output is flushed to the output buffer and the output is aligned on a byte
		  ' boundary. Flushing may degrade compression so it should be used only when necessary. This
		  ' completes the current deflate block and follows it with an empty stored block that is three
		  ' bits plus filler bits to the next byte, followed by four bytes (00 00 ff ff).
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Flush
		  
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
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Flush
		  
		  If mDeflater = Nil Then Raise New IOException
		  If Not mDeflater.Deflate(Nil, mDestination, Flushing) Then Raise New zlibException(mDeflater.LastError)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Lookahead(encoding As TextEncoding = Nil) As String
		  ' Returns the contents of the read buffer if BufferedReading is True (the default). If there
		  ' are fewer than two bytes remaining in the buffer then a new chunk is read into the buffer.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Lookahead
		  
		  If Me.BufferedReading = False Then Return ""
		  If mReadBuffer.LenB < 2 Then
		    mBufferedReading = False
		    mReadBuffer = mReadBuffer + Me.Read(CHUNK_SIZE, encoding)
		    mBufferedReading = True
		  End If
		  Return DefineEncoding(mReadBuffer, encoding)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(InputStream As FolderItem, Encoding As Integer = zlib.Z_DETECT) As zlib.ZStream
		  ' Create a decompression stream where the compressed input is read from the Source file.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Open
		  
		  Return Open(BinaryStream.Open(InputStream), Encoding)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(InputStream As Readable, Encoding As Integer = zlib.Z_DETECT) As zlib.ZStream
		  ' Create a decompression stream where the compressed input is read from the InputStream object.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Open
		  
		  Return New ZStream(New Inflater(Encoding), InputStream)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  // Part of the Readable interface.
		  ' This method reads from the compressed stream.
		  ' If BufferedReading is True (the default) then this method will read as many compressed bytes
		  ' as are necessary to produce exactly Count decompressed bytes (or until EOF if there are fewer
		  ' than Count decompressed bytes remaining in the stream).
		  ' If BufferedReading is False then exactly Count compressed bytes are read and fed into the
		  ' decompressor. Any decompressed output is returned: depending on the size of the read request
		  ' and the state of the decompressor this method might return zero bytes. A zero-length return
		  ' value does not indicate an error or the end of the stream; continue to Read from the stream
		  ' until EOF=True.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Read
		  
		  If mInflater = Nil Then Raise New IOException
		  Dim data As New MemoryBlock(0)
		  Dim ret As New BinaryStream(data)
		  Dim readsz As Integer = Count
		  If BufferedReading Then
		    If Count <= mReadBuffer.LenB Then
		      ' the buffer has enough bytes already
		      ret.Write(LeftB(mReadBuffer, Count))
		      Dim sz As Integer = mReadBuffer.LenB - Count
		      mReadBuffer = RightB(mReadBuffer, sz)
		      ret.Close
		      readsz = 0
		    Else
		      ' not enough bytes in the buffer
		      If mReadBuffer.LenB > 0 Then
		        ret.Write(mReadBuffer)
		        mReadBuffer = ""
		      End If
		      readsz = Max(Count, CHUNK_SIZE) ' read this many more compressed bytes
		    End If
		  End If
		  If readsz > 0 Then
		    If Not mInflater.Inflate(mSource, ret, readsz) Then
		      Dim err As New zlibException(mInflater.LastError)
		      If mInflater.Msg <> Nil Then err.Message = err.Message + EndOfLine + "Additional info: " + mInflater.Msg.CString(0)
		      Raise err
		    End If
		    ret.Close
		    If BufferedReading Then
		      If data.Size >= Count Then
		        ' buffer any leftovers
		        mReadBuffer = RightB(data, data.Size - Count)
		        data = LeftB(data, Count)
		      ElseIf Not Me.EOF Then
		        ' still need even more bytes!
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
		  ' Read compressed bytes until EOF, inflate and return any output.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.ReadAll
		  
		  If mInflater = Nil Then Raise New IOException
		  Dim data As New MemoryBlock(0)
		  Dim ret As New BinaryStream(data)
		  Dim prevmode As Boolean = mBufferedReading
		  If prevmode Then ret.Write(mReadBuffer)
		  Me.BufferedReading = False
		  Do Until Me.EOF
		    ret.Write(Me.Read(CHUNK_SIZE))
		  Loop
		  ret.Close
		  Me.BufferedReading = prevmode
		  Return DefineEncoding(data, encoding)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadError() As Boolean
		  // Part of the Readable interface.
		  ' Returns True if the source Readable object or zlib report an error.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.ReadError
		  
		  If mSource <> Nil Then Return mSource.ReadError Or (mInflater <> Nil And mInflater.LastError <> 0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadLine(encoding As TextEncoding = Nil, EOL As String = "") As String
		  ' Reads one line of decompressed text from the compressed stream.
		  ' If EOL is not specified then the target platform EOL marker is used by default.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.ReadLine
		  
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
		    #Else
		      EOL = EndOfLine.UNIX
		    #endif
		  End If
		  
		  ' try the easy way
		  Dim i As Integer = InStrB(Me.Lookahead, EOL)
		  If i > 0 Then Return Me.Read(i + EOL.LenB - 1, encoding)
		  
		  ' try the hard way
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
		  Return DefineEncoding(data, encoding)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Reset()
		  ' Resets the ZStream to its original state.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Reset
		  
		  If mDeflater <> Nil Then mDeflater.Reset
		  If mInflater <> Nil Then mInflater.Reset
		  mReadBuffer = ""
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Sync(MaxCount As Integer = - 1) As Boolean
		  ' Reads compressed bytes from the input stream until a possible full flush point is detected.
		  ' A full flush point is made when the compression stream is flushed with the Z_FULL_FLUSH parameter.
		  ' If a flush point was found then the decompressor switches to RAW_ENCODING, the Position
		  ' property of the Source BinaryStream is moved to the flush point, and this method returns True.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Sync
		  
		  If mInflater = Nil Or Not mSource IsA BinaryStream Then Return False
		  Dim raw As New zlib.Inflater(RAW_ENCODING)
		  Dim pos As UInt64 = BinaryStream(mSource).Position
		  If raw.SyncToNextFlush(mSource, MaxCount) Then
		    Dim mb As New MemoryBlock(0)
		    Dim tmp As New BinaryStream(mb)
		    Dim flushpos As UInt64 = raw.Total_In + pos
		    BinaryStream(mSource).Position = flushpos
		    If raw.Inflate(mSource, tmp, 1024) Then
		      BinaryStream(mSource).Position = flushpos
		      mInflater.Reset(RAW_ENCODING)
		      mInflater.IgnoreChecksums = True
		      mReadBuffer = ""
		      Return True
		    End If
		  End If
		  BinaryStream(mSource).Position = pos
		  Return False
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(Data As String)
		  // Part of the Writeable interface.
		  ' Write Data to the compressed stream.
		  ' NOTE: the Data may not be immediately written to the output; the compressor will write
		  ' to the output at times dictated by the compression parameters. Use the Flush method to
		  ' forcibly write pending output.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Write
		  
		  If mDeflater = Nil Then Raise New IOException
		  Dim tmp As New BinaryStream(Data)
		  If Not mDeflater.Deflate(tmp, mDestination) Then Raise New zlibException(mDeflater.LastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function WriteError() As Boolean
		  // Part of the Writeable interface.
		  ' Returns True if the destination Writeable object or zlib report an error.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.WriteError
		  
		  If mDestination <> Nil Then Return mDestination.WriteError Or (mDeflater <> Nil And mDeflater.LastError <> 0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub WriteLine(Data As String, EOL As String = "")
		  ' Write Data to the compressed stream followed by an EOL marker.
		  ' If EOL is not specified then the target platform EOL marker is used by default.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.WriteLine
		  
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
			  ' When False, ZStream.Read(Count) will read Count compressed bytes and return zero or
			  ' more (possibly a lot more) decompressed bytes. The decompressor will emit zero bytes
			  ' if no output can be generated without further input; users should continue reading
			  ' until EOF=True even if zero bytes are returned.
			  '
			  ' When True (default), ZStream.Read(Count) will return either exactly Count decompressed
			  ' bytes, buffering any leftovers in memory until the next call to ZStream.Read(Count);
			  ' or, fewer than Count bytes if there is not enough bytes left to read from the stream.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.BufferedReading
			  
			  return mBufferedReading
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' When False, ZStream.Read(Count) will read Count compressed bytes and return zero or
			  ' more (possibly a lot more) decompressed bytes. The decompressor will emit zero bytes
			  ' if no output can be generated without further input; users should continue reading
			  ' until EOF=True even if zero bytes are returned.
			  '
			  ' When True (default), ZStream.Read(Count) will return either exactly Count decompressed
			  ' bytes, buffering any leftovers in memory until the next call to ZStream.Read(Count);
			  ' or, fewer than Count bytes if there is not enough bytes left to read from the stream.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.BufferedReading
			  
			  If Not value Then mReadBuffer = ""
			  mBufferedReading = value
			End Set
		#tag EndSetter
		BufferedReading As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' When in compression/write mode, this property will return a reference to the 
			  ' Deflater instance that is actually doing the compression.
			  ' 
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Deflater
			  
			  Return mDeflater
			End Get
		#tag EndGetter
		Deflater As zlib.Deflater
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets the compression dictionary for the stream. Refer to Deflater.Dictionary
			  ' and Inflater.Dictionary for details.
			  ' 
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Dictionary
			  
			  If mDeflater <> Nil Then
			    Return mDeflater.Dictionary
			  ElseIf mInflater <> Nil Then
			    Return mInflater.Dictionary
			  End If
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Sets the compression dictionary for the stream. Refer to Deflater.Dictionary
			  ' and Inflater.Dictionary for details.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Dictionary
			  
			  If mDeflater <> Nil Then mDeflater.Dictionary = value
			  If mInflater <> Nil Then mInflater.Dictionary = value
			End Set
		#tag EndSetter
		Dictionary As MemoryBlock
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets the compression encoding (gzip, deflate, etc.) for the stream.
			  ' 
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Encoding
			  
			  If mDeflater <> Nil Then
			    Return mDeflater.Encoding
			  ElseIf mInflater <> Nil Then
			    Return mInflater.Encoding
			  End If
			End Get
		#tag EndGetter
		Encoding As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' When in decompression/read mode, this property will return a reference to the
			  ' Inflater instance that is actually doing the decompression.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Inflater
			  
			  Return mInflater
			End Get
		#tag EndGetter
		Inflater As zlib.Inflater
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns True if the stream is in read/decompression mode.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.IsReadable
			  
			  Return mInflater <> Nil
			End Get
		#tag EndGetter
		IsReadable As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns True if the stream is in write/compression mode.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.IsWriteable
			  
			  Return mDeflater <> Nil
			End Get
		#tag EndGetter
		IsWriteable As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets the most recent zlib error code.
			  ' 
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.LastError
			  
			  If mInflater <> Nil Then
			    Return mInflater.LastError
			  ElseIf mDeflater <> Nil Then
			    Return mDeflater.LastError
			  End IF
			End Get
		#tag EndGetter
		LastError As Int32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets the compression level for the stream. Valid levels are Z_BEST_SPEED(1) to
			  ' Z_BEST_COMPRESSION(9). 0 means no compression. The compression level controls
			  ' the tradeoff between compression speed and compression ratio. Faster compression
			  ' results in worse compression ratios.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Level
			  
			  If mDeflater <> Nil Then Return mDeflater.Level
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Sets the compression level for the stream. Valid levels are Z_BEST_SPEED(1) to
			  ' Z_BEST_COMPRESSION(9). 0 means no compression. Specify Z_DEFAULT_COMPRESSION(-1)
			  ' to use the default level, which is equivalent to level 6.
			  ' The compression level controls the tradeoff between compression speed and
			  ' compression ratio. Faster compression results in worse compression ratios.
			  ' Changes to this property will affect subsequent calls to Write(). Input from
			  ' previous calls to Write() which have already been fed to the compressor but not
			  ' yet emitted as output will use the previous Level.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Level
			  
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

	#tag Property, Flags = &h21
		Private mSource As Readable
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSourceMB As MemoryBlock
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets the compression ratio so far for the stream so far. For example, a compression
			  ' ratio of 50.0 means that the compressed stream is 50% the size of the uncompressed
			  ' stream.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Ratio
			  
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
			  ' Gets the compression Strategy for the stream. Refer to Deflater.Strategy for details
			  ' on the different strategies available.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Strategy
			  
			  If mDeflater <> Nil Then Return mDeflater.Strategy
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  ' Sets the compression Strategy for the stream. Use Z_DEFAULT_STRATEGY(0) unless you have
			  ' a good reason not to. Refer to Deflater.Strategy for details on the different
			  ' strategies available.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Strategy
			  
			  If mDeflater <> Nil Then mDeflater.Strategy = value
			End Set
		#tag EndSetter
		Strategy As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Gets the total number of input bytes so far. This value will overflow on streams
			  ' that are larger than 4GB, however this will not affect compression/decompression.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.TotalIn
			  
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
			  ' Gets the total number of output bytes so far. This value will overflow on streams
			  ' that are larger than 4GB, however this will not affect compression/decompression.
			  '
			  ' See:
			  ' https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.TotalIn
			  
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
