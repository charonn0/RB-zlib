#tag Module
Protected Module zlib
	#tag Method, Flags = &h1
		Protected Function Adler32(NewData As MemoryBlock, LastAdler As UInt32 = 0, NewDataSize As Integer = - 1) As UInt32
		  ' Calculate the Adler32 checksum for the NewData. Pass back the returned value
		  ' to continue processing.
		  '    Dim adler As UInt32
		  '    While True
		  '      adler = zlib.Adler32(NextInputData, adler)
		  '    Wend
		  ' If NewData.Size is not known (-1) then specify the size as NewDataSize
		  
		  If Not zlib.IsAvailable Then Return 0
		  Static ADLER_POLYNOMIAL As UInt32
		  If ADLER_POLYNOMIAL = 0 Then ADLER_POLYNOMIAL = _adler32(0, Nil, 0)
		  
		  If NewDataSize = -1 Then NewDataSize = NewData.Size
		  If LastAdler = 0 Then LastAdler = ADLER_POLYNOMIAL
		  If NewData <> Nil Then Return _adler32(LastAdler, NewData, NewDataSize)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Compress(Data As MemoryBlock, CompressionLevel As Integer = Z_DEFAULT_COMPRESSION, DataSize As Integer = - 1) As MemoryBlock
		  ' Compress memory in one operation using deflate. If Data.Size is not known (-1) then specify the size as DataSize
		  ' Use Uncompress to reverse.
		  
		  If Not zlib.IsAvailable Then Raise New PlatformNotSupportedException
		  
		  If DataSize = -1 Then DataSize = Data.Size
		  Dim OutSize As UInt32 = zlib.compressBound(DataSize)
		  Dim OutBuffer As New MemoryBlock(OutSize)
		  Dim err As Integer
		  
		  Do
		    If CompressionLevel = Z_DEFAULT_COMPRESSION Then
		      err = zlib._compress(OutBuffer, OutSize, Data, DataSize)
		    Else
		      err = zlib._compress2(OutBuffer, OutSize, Data, DataSize, CompressionLevel)
		    End If
		    Select Case err
		    Case Z_STREAM_ERROR
		      Break ' CompressionLevel is invalid; using default
		      Return Compress(Data, Z_DEFAULT_COMPRESSION, DataSize)
		      
		    Case Z_BUF_ERROR
		      OutSize = OutSize * 2
		      OutBuffer = New MemoryBlock(OutSize)
		      
		    Case Z_MEM_ERROR
		      Raise New OutOfMemoryException
		      
		    End Select
		  Loop Until err <> Z_BUF_ERROR
		  
		  If err <> Z_OK Then Raise New zlibException(err)
		  Return OutBuffer.StringValue(0, OutSize)
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function compressBound Lib "zlib1" (sourceLen As UInt64) As UInt32
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function CRC32(NewData As MemoryBlock, LastCRC As UInt32 = 0, NewDataSize As Integer = - 1) As UInt32
		  ' Calculate the CRC32 checksum for the NewData. Pass back the returned value
		  ' to continue processing.
		  '    Dim crc As UInt32
		  '    While True
		  '      crc = zlib.CRC32(NextInputData, crc)
		  '    Wend
		  ' If NewData.Size is not known (-1) then specify the size as NewDataSize
		  
		  If Not zlib.IsAvailable Then Return 0
		  Static CRC_POLYNOMIAL As UInt32
		  If CRC_POLYNOMIAL = 0 Then CRC_POLYNOMIAL = _crc32(0, Nil, 0)
		  
		  If NewDataSize = -1 Then NewDataSize = NewData.Size
		  If LastCRC = 0 Then LastCRC = CRC_POLYNOMIAL
		  If NewData <> Nil Then Return _crc32(LastCRC, NewData, NewDataSize)
		  
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflate Lib "zlib1" (ByRef Stream As z_stream, Flush As Integer) As Integer
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function Deflate(Source As Readable, Destination As Writeable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION) As Boolean
		  ' Compress the Source stream and write the output to the Destination stream. Use Inflate to reverse.
		  
		  Dim z As ZStream = ZStream.Create(Destination, CompressionLevel)
		  Do Until Source.EOF
		    z.Write(Source.Read(CHUNK_SIZE))
		  Loop
		  z.Close
		  Return True
		  
		Exception
		  Return False
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateBound Lib "zlib1" (ByRef Stream As z_stream, DataLength As UInt32) As UInt32
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateCopy Lib "zlib1" (ByRef Dst As z_stream, Src As z_stream) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateEnd Lib "zlib1" (ByRef Stream As z_stream) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateInit_ Lib "zlib1" (ByRef Stream As z_stream, CompressionLevel As Integer, Version As CString, StreamSz As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateParams Lib "zlib1" (ByRef Stream As z_stream, Level As Integer, Strategy As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflatePending Lib "zlib1" (ByRef Stream As z_stream, ByRef Pending As UInt32, ByRef Bits As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateReset Lib "zlib1" (ByRef Stream As z_stream) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateSetDictionary Lib "zlib1" (ByRef Stream As z_stream, Dictionary As Ptr, DictLength As UInt32) As Integer
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function GUnZip(InputFile As FolderItem, OutputStream As Writeable) As Boolean
		  ' Decompress the InputFile as a gzip archive and write it into OutputStream
		  
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
		Private Soft Declare Sub gzclearerr Lib "zlib1" (gzFile As Ptr)
	#tag EndExternalMethod

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
		  ' Compress the InputStream using gzip and write it to OutputFile
		  
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
		Private Soft Declare Function inflate Lib "zlib1" (ByRef Stream As z_stream, Flush As Integer) As Integer
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function Inflate(Source As Readable, Destination As Writeable) As Boolean
		  ' Decompress the Source stream and write the output to the Destination stream. Reverses the Deflate method
		  
		  Dim z As ZStream = ZStream.Open(Source)
		  Do Until z.EOF
		    Destination.Write(z.Read(CHUNK_SIZE))
		  Loop
		  z.Close
		  Return True
		  
		Exception
		  Return False
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateCopy Lib "zlib1" (ByRef Dst As z_stream, Src As z_stream) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateEnd Lib "zlib1" (ByRef Stream As z_stream) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateGetDictionary Lib "zlib1" (ByRef Stream As z_stream, Dictionary As Ptr, ByRef DictLength As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateInit_ Lib "zlib1" (ByRef Stream As z_stream, Version As CString, StreamSz As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateReset Lib "zlib1" (ByRef Stream As z_stream) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateReset2 Lib "zlib1" (ByRef Stream As z_stream, WindowBits As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateSetDictionary Lib "zlib1" (ByRef Stream As z_stream, Dictionary As Ptr, DictLength As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateSync Lib "zlib1" (ByRef Dst As z_stream) As Integer
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
		Protected Function ReadTar(TarFile As FolderItem, ExtractTo As FolderItem) As FolderItem()
		  ' Extracts a TAR file to the ExtractTo directory
		  Dim tar As TapeArchive = zlib.TapeArchive.Open(TarFile)
		  Dim bs As BinaryStream
		  Dim fs() As FolderItem
		  Do
		    If bs <> Nil Then bs.Close
		    Dim g As FolderItem = ExtractTo.Child(tar.CurrentName)
		    bs = BinaryStream.Create(g)
		    fs.Append(g)
		  Loop Until Not tar.MoveNext(bs)
		  bs.Close
		  tar.Close
		  Return fs
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Uncompress(Data As MemoryBlock, ExpandedSize As Integer = - 1, DataSize As Integer = - 1) As MemoryBlock
		  ' Decompress memory in one operation using deflate. If Data.Size is not known (-1) then specify the size as DataSize
		  ' If the size of the decompressed data is known then pass it as ExpandedSize. Reverses the Compress method
		  
		  If Not zlib.IsAvailable Then Raise New PlatformNotSupportedException
		  
		  If DataSize = -1 Then DataSize = Data.Size
		  If ExpandedSize <= 0 Then ExpandedSize = DataSize * 1.1 + 12
		  Dim OutputBuffer As MemoryBlock
		  Dim OutSize As UInt32
		  Dim err As Integer
		  
		  Do
		    OutputBuffer = New MemoryBlock(ExpandedSize)
		    OutSize = OutputBuffer.Size
		    err = zlib._uncompress(OutputBuffer, OutSize, Data, DataSize)
		    ExpandedSize = ExpandedSize * 2
		    Select Case err
		    Case Z_MEM_ERROR
		      Raise New OutOfMemoryException
		      
		    Case Z_DATA_ERROR
		      Raise New UnsupportedFormatException
		      
		    End Select
		  Loop Until err <> Z_BUF_ERROR
		  
		  If err <> Z_OK Then Raise New zlibException(err)
		  Return OutputBuffer.StringValue(0, OutSize)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Version() As String
		  If Not zlib.IsAvailable Then Return ""
		  Dim mb As MemoryBlock = zlib.zlibVersion
		  Return mb.CString(0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function WriteTar(ToArchive() As FolderItem, OutputFile As FolderItem) As Boolean
		  ' Creates/appends a TAR file with the ToArchive FolderItems
		  Dim tar As zlib.TapeArchive
		  If OutputFile.Exists Then
		    tar = zlib.TapeArchive.Open(OutputFile)
		  Else
		    tar = zlib.TapeArchive.Create(OutputFile)
		  End If
		  For i As Integer = 0 To UBound(ToArchive)
		    If Not tar.AppendFile(ToArchive(i)) Then Return False
		  Next
		  tar.Close
		  Return True
		  
		  
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


	#tag Constant, Name = CHUNK_SIZE, Type = Double, Dynamic = False, Default = \"16384", Scope = Private
	#tag EndConstant

	#tag Constant, Name = Z_ASCII, Type = Double, Dynamic = False, Default = \"Z_TEXT", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_BEST_COMPRESSION, Type = Double, Dynamic = False, Default = \"9", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_BEST_SPEED, Type = Double, Dynamic = False, Default = \"1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_BINARY, Type = Double, Dynamic = False, Default = \"0", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_BLOCK, Type = Double, Dynamic = False, Default = \"5", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_BUF_ERROR, Type = Double, Dynamic = False, Default = \"-5", Scope = Private
	#tag EndConstant

	#tag Constant, Name = Z_DATA_ERROR, Type = Double, Dynamic = False, Default = \"-3", Scope = Private
	#tag EndConstant

	#tag Constant, Name = Z_DEFAULT_COMPRESSION, Type = Double, Dynamic = False, Default = \"-1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_DEFAULT_STRATEGY, Type = Double, Dynamic = False, Default = \"0", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_DEFLATED, Type = Double, Dynamic = False, Default = \"8", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_ERRNO, Type = Double, Dynamic = False, Default = \"-1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = Z_FILTERED, Type = Double, Dynamic = False, Default = \"1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_FINISH, Type = Double, Dynamic = False, Default = \"4", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_FIXED, Type = Double, Dynamic = False, Default = \"4", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_HUFFMAN_ONLY, Type = Double, Dynamic = False, Default = \"2", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_MEM_ERROR, Type = Double, Dynamic = False, Default = \"-4", Scope = Private
	#tag EndConstant

	#tag Constant, Name = Z_NEED_DICT, Type = Double, Dynamic = False, Default = \"2", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_NO_COMPRESSION, Type = Double, Dynamic = False, Default = \"0", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_NO_FLUSH, Type = Double, Dynamic = False, Default = \"0", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_OK, Type = Double, Dynamic = False, Default = \"0", Scope = Private
	#tag EndConstant

	#tag Constant, Name = Z_PARTIAL_FLUSH, Type = Double, Dynamic = False, Default = \"1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_RLE, Type = Double, Dynamic = False, Default = \"3", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_STREAM_END, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = Z_STREAM_ERROR, Type = Double, Dynamic = False, Default = \"-2", Scope = Private
	#tag EndConstant

	#tag Constant, Name = Z_SYNC_FLUSH, Type = Double, Dynamic = False, Default = \"2", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_TEXT, Type = Double, Dynamic = False, Default = \"1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_TREES, Type = Double, Dynamic = False, Default = \"6", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_UNKNOWN, Type = Double, Dynamic = False, Default = \"2", Scope = Protected
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
