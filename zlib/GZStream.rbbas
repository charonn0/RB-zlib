#tag Class
Protected Class GZStream
Implements Readable,Writeable
	#tag Method, Flags = &h0
		Sub Close()
		  If gzFile <> Nil Then 
		    mLastError = zlib.gzclose(gzFile)
		    If mLastError = Z_ERRNO Then
		      #If TargetWin32 Then
		        If Not _get_errno(mLastError) Then
		          Raise New IOException
		        Else
		          Raise New zlibException(mLastError)
		        End If
		      #Else
		        Raise New IOException
		      #EndIf
		    End If
		  End If
		  gzFile = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor(gzOpaque As Ptr)
		  If Not zlib.IsAvailable Then Raise New PlatformNotSupportedException
		  gzFile = gzOpaque
		  gzError() ' set LastError
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Create(OutputFile As FolderItem, Append As Boolean = False, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, CompressionStrategy As Integer = zlib.Z_DEFAULT_STRATEGY) As zlib.GZStream
		  ' Creates an empty gzip stream, or opens an existing stream for appending
		  If OutputFile = Nil Or OutputFile.Directory Then Raise New IOException
		  Dim mode As String = "wb"
		  If Append Then mode = "ab"
		  If CompressionLevel <> Z_DEFAULT_COMPRESSION Then
		    If CompressionLevel < 0 Or CompressionLevel > 9 Then
		      Break ' Invalid CompressionLevel
		    Else
		      mode = mode + Str(CompressionLevel)
		    End If
		  End If
		  Dim z As GZStream = gzOpen(OutputFile, mode)
		  z.mLevel = CompressionLevel
		  z.Strategy = CompressionStrategy
		  Return z
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If gzFile <> Nil Then Me.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EOF() As Boolean
		  // Part of the Readable interface.
		  If gzFile <> Nil Then Return zlib.gzeof(gzFile)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub FinishBlock()
		  ' A stronger version of Flush(). All remaining data is written and the gzip stream is completed in the output. If GZStream.Write is
		  ' called again, a new gzip stream will be started in the output. GZStream.Read is able to read such concatented gzip streams. This
		  ' will severely impact compression ratios, even into the negative.
		  
		  If Not Me.Flush(Z_FINISH) Then Raise New zlibException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Flush()
		  // Part of the Writeable interface.
		  ' Z_PARTIAL_FLUSH: All pending output is flushed to the output buffer, but the output is not aligned to a byte boundary.
		  ' This completes the current deflate block and follows it with an empty fixed codes block that is 10 bits long.
		  
		  If Not Me.Flush(Z_PARTIAL_FLUSH) Then Raise New zlibException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Flush(Flushing As Integer) As Boolean
		  If Not mIsWriteable Then Raise New IOException ' opened for reading!
		  If gzFile = Nil Then Raise New NilObjectException
		  mLastError = zlib.gzflush(gzFile, Flushing)
		  Return mLastError <> Z_OK
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub gzError()
		  If gzFile <> Nil Then mLastMsg = zlib._gzerror(gzFile, mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Shared Function gzOpen(GzipFile As FolderItem, Mode As String) As zlib.GZStream
		  If Not zlib.IsAvailable Then Raise New PlatformNotSupportedException
		  Dim strm As Ptr = zlib.gzOpen(GzipFile.AbsolutePath, mode)
		  If strm <> Nil Then
		    Dim s As New zlib.GZStream(strm)
		    s.mIsWriteable = (mode <> "rb")
		    Return s
		  Else
		    #If TargetWin32 Then
		      Dim err As Integer
		      If Not _get_errno(err) Then
		        Raise New IOException
		      Else
		        Raise New zlibException(err)
		      End If
		    #Else
		      Raise New IOException
		    #EndIf
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastErrorMsg() As CString
		  If mLastMsg <> Nil Then
		    Dim mb As MemoryBlock = mLastMsg
		    Return mb.CString(0)
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Level() As Integer
		  Return mLevel
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Level(Assigns NewLevel As Integer)
		  If Not mIsWriteable Then Raise New IOException ' opened for reading!
		  If gzFile = Nil Then Raise New NilObjectException
		  mLastError = zlib.gzsetparams(gzFile, NewLevel, mStrategy)
		  If mLastError = Z_OK Then
		    mLevel = NewLevel
		  Else
		    Raise New zlibException(mLastError)
		  End If
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(GzipFile As FolderItem) As zlib.GZStream
		  ' Opens an existing gzip stream for reading only
		  If GzipFile = Nil Or GzipFile.Directory Or Not GzipFile.Exists Then Raise New IOException
		  Return gzOpen(GzipFile, "rb")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  // Part of the Readable interface.
		  ' Reads the requested number of DEcompressed bytes from the compressed stream.
		  
		  If mIsWriteable Then Raise New IOException ' opened for writing!
		  If gzFile = Nil Then Raise New NilObjectException
		  Dim mb As New MemoryBlock(Count)
		  Dim red As Integer = zlib.gzread(gzFile, mb, mb.Size)
		  gzError() ' set LastError
		  If red > 0 Then
		    Return DefineEncoding(mb.StringValue(0, red), encoding)
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadError() As Boolean
		  // Part of the Readable interface.
		  Return mLastError <> Z_OK
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Strategy() As Integer
		  Return mStrategy
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Strategy(Assigns NewStrategy As Integer)
		  If Not mIsWriteable Or gzFile = Nil Then Raise New IOException
		  mLastError = zlib.gzsetparams(gzFile, mLevel, NewStrategy)
		  If mLastError = Z_OK Then
		    mStrategy = NewStrategy
		  Else
		    Raise New zlibException(mLastError)
		  End If
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(text As String)
		  // Part of the Writeable interface.
		  ' Compresses the data and writes it to the stream
		  
		  If Not mIsWriteable Then Raise New IOException ' opened for reading!
		  If gzFile = Nil Then Raise New NilObjectException
		  Dim mb As MemoryBlock = text
		  If zlib.gzwrite(gzFile, mb, mb.Size) <> text.LenB Then 
		    gzError() ' set LastError
		    Raise New zlibException(mLastError)
		  Else
		    gzError() ' set LastError
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function WriteError() As Boolean
		  // Part of the Writeable interface.
		  Return mLastError <> Z_OK
		End Function
	#tag EndMethod


	#tag Property, Flags = &h1
		Protected gzFile As Ptr
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mIsWriteable As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastMsg As Ptr
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLevel As Integer = Z_DEFAULT_COMPRESSION
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mStrategy As Integer = Z_DEFAULT_STRATEGY
	#tag EndProperty


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
