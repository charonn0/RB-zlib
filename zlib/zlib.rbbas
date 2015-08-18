#tag Module
Protected Module zlib
	#tag Method, Flags = &h1
		Protected Function Adler32(NewData As MemoryBlock, LastAdler As UInt32) As UInt32
		  ' You must call this method once with NIL to initialize, and then pass back the returned value to each pass.
		  '    Dim adler As UInt32 = zlib.Adler32(Nil, 0) //initialize
		  '    While True
		  '      adler = Adler32(NextInputData, adler)
		  '    Wend
		  If Not zlib.IsAvailable Then Return 0
		  If NewData <> Nil Then
		    Return _adler32(LastAdler, NewData, NewData.Size)
		  Else
		    Return _adler32(0, Nil, 0)
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Compress(Data As MemoryBlock, CompressionLevel As Integer = Z_DEFAULT_COMPRESSION) As MemoryBlock
		  If Not zlib.IsAvailable Then Return Nil
		  Dim cb As UInt32 = zlib.compressBound(Data.Size)
		  Dim out As New MemoryBlock(cb)
		  Dim err As Integer
		  Do
		    If CompressionLevel = Z_DEFAULT_COMPRESSION Then
		      err = zlib._compress(out, cb, Data, Data.Size)
		    Else
		      err = zlib._compress2(out, cb, Data, Data.Size, CompressionLevel)
		    End If
		    Select Case err
		    Case Z_STREAM_ERROR
		      Break ' CompressionLevel is invalid; using default
		      Return Compress(Data)
		      
		    Case Z_BUF_ERROR
		      out = New MemoryBlock(out.Size * 2)
		      cb = out.Size
		    End Select
		  Loop Until err <> Z_BUF_ERROR
		  If err <> Z_OK Then Raise New zlibException(err)
		  Return out.StringValue(0, cb)
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function compressBound Lib "zlib1" (sourceLen As UInt64) As UInt32
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function CRC32(NewData As MemoryBlock, LastCRC As UInt32) As UInt32
		  ' You must call this method once with NIL to initialize, and then pass back the returned value to each pass.
		  '    Dim crc As UInt32 = zlib.CRC32(Nil, 0) //initialize
		  '    While True
		  '      crc = CRC32(NextInputData, crc)
		  '    Wend
		  
		  If Not zlib.IsAvailable Then Return 0
		  If NewData <> Nil Then
		    Return _crc32(LastCRC, NewData, NewData.Size)
		  Else
		    Return _crc32(0, Nil, 0)
		  End If
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflate Lib "zlib1" (Stream As z_stream, Flush As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateEnd Lib "zlib1" (Stream As z_stream) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateInit_ Lib "zlib1" (ByRef Stream As z_stream, CompressionLevel As Integer, Version As CString, StreamSz As Integer) As Integer
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function GUnZip(InputFile As FolderItem, OutputStream As Writeable) As Boolean
		  ' Decompress the InputFile and write it into OutputStream
		  
		  If Not zlib.IsAvailable Then Return False
		  Dim gz As zlib.GZStream = zlib.GZStream.Open(InputFile)
		  While Not gz.EOF
		    OutputStream.Write(gz.Read(1024))
		  Wend
		  gz.Close
		  Return True
		  
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function gzclose Lib "zlib1" (gzFile As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function gzeof Lib "zlib1" (gzFile As Ptr) As Boolean
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function gzflush Lib "zlib1" (gzFile As Ptr, Flush As Integer) As Integer
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function GZip(InputStream As Readable, OutputFile As FolderItem, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Strategy As Integer = zlib.Z_DEFAULT_STRATEGY) As Boolean
		  ' Compress the InputStream and write it to OutputFile
		  
		  If Not zlib.IsAvailable Then Return False
		  Dim gz As zlib.GZStream = zlib.GZStream.Create(OutputFile)
		  If CompressionLevel <> Z_DEFAULT_COMPRESSION Then gz.Level = CompressionLevel
		  If Strategy <> Z_DEFAULT_STRATEGY Then gz.Strategy = Strategy
		  While Not InputStream.EOF
		    gz.Write(InputStream.Read(1024))
		  Wend
		  gz.Close
		  Return True
		  
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function gzoffset Lib "zlib1" (gzFile As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function gzopen Lib "zlib1" (Path As CString, Mode As CString) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function gzread Lib "zlib1" (gzFile As Ptr, Buffer As Ptr, Length As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function gzseek Lib "zlib1" (gzFile As Ptr, Offset As Integer, Whence As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function gzsetparams Lib "zlib1" (gzFile As Ptr, Level As Integer, Strategy As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function gzwrite Lib "zlib1" (gzFile As Ptr, Buffer As Ptr, Length As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflate Lib "zlib1" (Stream As z_stream, Flush As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateEnd Lib "zlib1" (Stream As z_stream) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateInit_ Lib "zlib1" (ByRef Stream As z_stream, Version As CString, StreamSz As Integer) As Integer
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function IsAvailable() As Boolean
		  Static mIsAvailable As Boolean
		  
		  If Not mIsAvailable Then mIsAvailable = System.IsFunctionAvailable("zlibVersion", "zlib1")
		  Return mIsAvailable
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsGZipped(Extends TargetFile As FolderItem) As Boolean
		  //Checks the GZip magic number. Returns True if the source file is likely a GZip archive
		  
		  If TargetFile.Directory Or Not TargetFile.Exists Then Return False
		  Dim bs As BinaryStream
		  Dim IsGZ As Boolean
		  Try
		    bs = bs.Open(TargetFile)
		    If bs.ReadByte = &h1F And bs.ReadByte = &h8B Then IsGZ = True
		  Catch
		    IsGZ = False
		  Finally
		    If bs <> Nil Then bs.Close
		  End Try
		  Return IsGZ
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Uncompress(Data As MemoryBlock, ExpandedSize As Integer = - 1) As MemoryBlock
		  If Not zlib.IsAvailable Then Return Nil
		  If ExpandedSize <= 0 Then ExpandedSize = Data.Size * 1.1 + 12
		  Dim out As MemoryBlock
		  Dim outsz As UInt32
		  Dim err As Integer
		  Do
		    out = New MemoryBlock(ExpandedSize)
		    outsz = out.Size
		    err = zlib._uncompress(out, outsz, Data, Data.Size)
		    ExpandedSize = ExpandedSize * 2
		  Loop Until err <> Z_BUF_ERROR
		  
		  If err <> Z_OK Then Raise New zlibException(err)
		  Return out.StringValue(0, outsz)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Version() As String
		  If Not zlib.IsAvailable Then Return ""
		  Dim mb As MemoryBlock = zlib.zlibVersion
		  Return mb.CString(0)
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function zError Lib "zlib1" (ErrorCode As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function zlibVersion Lib "zlib1" () As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function _adler32 Lib "zlib1" Alias "adler32" (adler As UInt32, Buffer As Ptr, BufferLen As UInt32) As UInt32
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function _compress Lib "zlib1" Alias "compress" (Output As Ptr, ByRef OutLen As UInt32, Source As Ptr, SourceLen As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function _compress2 Lib "zlib1" Alias "compress2" (Output As Ptr, ByRef OutLen As UInt32, Source As Ptr, SourceLen As UInt32, Level As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function _crc32 Lib "zlib1" Alias "crc32" (crc As UInt32, Buffer As Ptr, BufferLen As UInt32) As UInt32
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function _get_errno Lib "msvcrt" (ByRef errno As Integer) As Boolean
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function _gzerror Lib "zlib1" Alias "gzerror" (gzFile As Ptr, ByRef ErrorNum As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function _uncompress Lib "zlib1" Alias "uncompress" (Output As Ptr, ByRef OutLen As UInt32, Source As Ptr, SourceLen As UInt32) As Integer
	#tag EndExternalMethod


	#tag Constant, Name = Z_BUF_ERROR, Type = Double, Dynamic = False, Default = \"-5", Scope = Private
	#tag EndConstant

	#tag Constant, Name = Z_DATA_ERROR, Type = Double, Dynamic = False, Default = \"-3", Scope = Private
	#tag EndConstant

	#tag Constant, Name = Z_DEFAULT_COMPRESSION, Type = Double, Dynamic = False, Default = \"-1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_DEFAULT_STRATEGY, Type = Double, Dynamic = False, Default = \"0", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_ERRNO, Type = Double, Dynamic = False, Default = \"-1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = Z_FINISH, Type = Double, Dynamic = False, Default = \"4", Scope = Private
	#tag EndConstant

	#tag Constant, Name = Z_MEM_ERROR, Type = Double, Dynamic = False, Default = \"-4", Scope = Private
	#tag EndConstant

	#tag Constant, Name = Z_NO_FLUSH, Type = Double, Dynamic = False, Default = \"0", Scope = Private
	#tag EndConstant

	#tag Constant, Name = Z_OK, Type = Double, Dynamic = False, Default = \"0", Scope = Private
	#tag EndConstant

	#tag Constant, Name = Z_PARTIAL_FLUSH, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = Z_STREAM_ERROR, Type = Double, Dynamic = False, Default = \"-2", Scope = Private
	#tag EndConstant

	#tag Constant, Name = Z_SYNC_FLUSH, Type = Double, Dynamic = False, Default = \"2", Scope = Private
	#tag EndConstant

	#tag Constant, Name = Z_VERSION_ERROR, Type = Double, Dynamic = False, Default = \"-6", Scope = Private
	#tag EndConstant


	#tag Structure, Name = z_stream, Flags = &h21
		next_in as Ptr
		  avail_in as UInt32
		  total_in as UInt32
		  next_out as Ptr
		  avail_out as UInt32
		  total_out as UInt32
		  msg as Ptr
		  internal_state as Ptr
		  zalloc as Ptr
		  zfree as Ptr
		  opaque as Ptr
		  data_type as Int32
		  adler as UInt32
		reserved as UInt32
	#tag EndStructure


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
End Module
#tag EndModule
