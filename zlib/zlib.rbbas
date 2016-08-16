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
		Protected Function Deflate(Source As FolderItem, Destination As FolderItem, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Overwrite As Boolean = False, Encoding As Integer = zlib.DEFLATE_ENCODING) As Boolean
		  ' Compress the Source file into the Destination file. Use Inflate to reverse.
		  
		  Dim dst As BinaryStream = BinaryStream.Create(Destination, Overwrite)
		  Dim src As BinaryStream = BinaryStream.Open(Source)
		  Dim ok As Boolean
		  Try
		    ok = Deflate(src, dst, CompressionLevel, Encoding)
		  Finally
		    src.Close
		    dst.Close
		  End Try
		  Return ok
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Deflate(Source As FolderItem, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Encoding As Integer = zlib.DEFLATE_ENCODING) As MemoryBlock
		  ' Compress the Source file and return it. Use Inflate to reverse.
		  
		  Dim buffer As New MemoryBlock(0)
		  Dim dst As New BinaryStream(buffer)
		  Dim src As BinaryStream = BinaryStream.Open(Source)
		  Dim ok As Boolean
		  Try
		    ok = Deflate(src, dst, CompressionLevel, Encoding)
		  Finally
		    src.Close
		    dst.Close
		  End Try
		  If ok Then Return buffer
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Deflate(Source As MemoryBlock, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Encoding As Integer = zlib.DEFLATE_ENCODING) As MemoryBlock
		  ' Compress the Source data and return it. Use Inflate to reverse.
		  
		  Dim buffer As New MemoryBlock(0)
		  Dim dst As New BinaryStream(buffer)
		  Dim src As New BinaryStream(Source)
		  If Not Deflate(src, dst, CompressionLevel, Encoding) Then Return Nil
		  dst.Close
		  Return buffer
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Deflate(Source As Readable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Encoding As Integer = zlib.DEFLATE_ENCODING) As MemoryBlock
		  ' Compress the Source stream and return it. Use Inflate to reverse.
		  
		  Dim buffer As New MemoryBlock(0)
		  Dim stream As New BinaryStream(buffer)
		  If Not Deflate(Source, stream, CompressionLevel, Encoding) Then Return Nil
		  stream.Close
		  Return buffer
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Deflate(Source As Readable, Destination As Writeable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Encoding As Integer = zlib.DEFLATE_ENCODING) As Boolean
		  ' Compress the Source stream and write the output to the Destination stream. Use Inflate to reverse.
		  
		  Dim z As ZStream
		  If Encoding = DEFLATE_ENCODING Then
		    z = ZStream.Create(Destination, CompressionLevel)
		  Else
		    z = ZStream.Create(Destination, CompressionLevel, Z_DEFAULT_STRATEGY, Encoding)
		  End If
		  Try
		    Do Until Source.EOF
		      z.Write(Source.Read(CHUNK_SIZE))
		    Loop
		  Finally
		    z.Close
		  End Try
		  Return True
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
		Private Soft Declare Function deflateInit2_ Lib "zlib1" (ByRef Stream As z_stream, CompressionLevel As Integer, CompressionMethod As Integer, WindowBits As Integer, MemLevel As Integer, Strategy As Integer, Version As CString, StreamSz As Integer) As Integer
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
		Private Soft Declare Function deflatePrime Lib "zlib1" (ByRef Stream As z_stream, Bits As Integer, Value As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateReset Lib "zlib1" (ByRef Stream As z_stream) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateSetDictionary Lib "zlib1" (ByRef Stream As z_stream, Dictionary As Ptr, DictLength As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateSetHeader Lib "zlib1" (ByRef Stream As z_stream, Header As gz_headerp) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateTune Lib "zlib1" (ByRef Stream As z_stream, GoodLength As Integer, MaxLazy As Integer, NiceLength As Integer, MaxChain As Integer) As Integer
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function GUnZip(Source As FolderItem) As MemoryBlock
		  ' GUnZip the Source file and return it. Reverses the GZip method
		  
		  Dim buffer As New MemoryBlock(0)
		  Dim dst As New BinaryStream(buffer)
		  Dim src As BinaryStream = BinaryStream.Open(Source)
		  Dim ok As Boolean
		  Try
		    ok = GUnZip(src, dst)
		  Finally
		    src.Close
		    dst.Close
		  End Try
		  If ok Then Return buffer
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GUnZip(Source As FolderItem, Destination As FolderItem, Overwrite As Boolean = False) As Boolean
		  ' GUnZip the Source file and write the output to the Destination file. Reverses the GZip method
		  
		  Dim dst As BinaryStream = BinaryStream.Create(Destination, Overwrite)
		  Dim src As BinaryStream = BinaryStream.Open(Source)
		  Dim ok As Boolean
		  Try
		    ok = GUnZip(src, dst)
		  Finally
		    src.Close
		    dst.Close
		  End Try
		  Return ok
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GUnZip(Source As MemoryBlock) As MemoryBlock
		  ' GUnZip the Source data and return it. Reverses the GZip method
		  
		  Dim src As New BinaryStream(Source)
		  Return GUnZip(src)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GUnZip(Source As Readable) As MemoryBlock
		  ' GUnZip the Source stream and Return it. Reverses the GZip method
		  
		  Dim buffer As New MemoryBlock(0)
		  Dim stream As New BinaryStream(buffer)
		  If Not GUnZip(Source, stream) Then Return Nil
		  stream.Close
		  Return buffer
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GUnZip(Source As Readable, Destination As Writeable) As Boolean
		  ' gunzip the Source stream and write the output to the Destination stream. Reverses the GZip method
		  
		  Return Inflate(Source, Destination, Nil, GZIP_ENCODING)
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
		Protected Function GZip(Source As FolderItem, Destination As FolderItem, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Overwrite As Boolean = False) As Boolean
		  ' GZip the Source file into the Destination file. Use GUnZip to reverse.
		  
		  Dim dst As BinaryStream = BinaryStream.Create(Destination, Overwrite)
		  Dim src As BinaryStream = BinaryStream.Open(Source)
		  Dim ok As Boolean
		  Try
		    ok = GZip(src, dst, CompressionLevel)
		  Finally
		    src.Close
		    dst.Close
		  End Try
		  Return ok
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GZip(Source As FolderItem, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION) As MemoryBlock
		  ' GZip the Source file and return it. Use GUnZip to reverse.
		  
		  Dim buffer As New MemoryBlock(0)
		  Dim dst As New BinaryStream(buffer)
		  Dim src As BinaryStream = BinaryStream.Open(Source)
		  Dim ok As Boolean
		  Try
		    ok = GZip(src, dst, CompressionLevel)
		  Finally
		    src.Close
		    dst.Close
		  End Try
		  If ok Then Return buffer
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GZip(Source As MemoryBlock, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION) As MemoryBlock
		  ' GZip the Source data and return it. Use GUnZip to reverse.
		  
		  Dim src As New BinaryStream(Source)
		  Return GZip(src, CompressionLevel)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GZip(Source As Readable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION) As MemoryBlock
		  ' GZip the Source stream and return it. Use GUnZip to reverse.
		  
		  Dim buffer As New MemoryBlock(0)
		  Dim stream As New BinaryStream(buffer)
		  If Not GZip(Source, stream, CompressionLevel) Then Return Nil
		  stream.Close
		  Return buffer
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GZip(Source As Readable, Destination As Writeable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION) As Boolean
		  ' GZip the Source stream and write the output to the Destination stream. Use GUnZip to reverse.
		  
		  Return Deflate(Source, Destination, CompressionLevel, GZIP_ENCODING)
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
		Protected Function Inflate(Source As FolderItem, Destination As FolderItem, Dictionary As MemoryBlock = Nil, Overwrite As Boolean = False, Encoding As Integer = zlib.DEFLATE_ENCODING) As Boolean
		  ' Decompress the Source file and write the output to the Destination file. Reverses the Deflate method
		  
		  Dim dst As BinaryStream = BinaryStream.Create(Destination, Overwrite)
		  Dim src As BinaryStream = BinaryStream.Open(Source)
		  Dim ok As Boolean
		  Try
		    ok = Inflate(src, dst, Dictionary, Encoding)
		  Finally
		    src.Close
		    dst.Close
		  End Try
		  Return ok
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Inflate(Source As FolderItem, Dictionary As MemoryBlock = Nil, Encoding As Integer = zlib.DEFLATE_ENCODING) As MemoryBlock
		  ' Decompress the Source file and return it. Reverses the Deflate method
		  
		  Dim buffer As New MemoryBlock(0)
		  Dim dst As New BinaryStream(buffer)
		  Dim src As BinaryStream = BinaryStream.Open(Source)
		  Dim ok As Boolean
		  Try
		    ok = Inflate(src, dst, Dictionary, Encoding)
		  Finally
		    src.Close
		    dst.Close
		  End Try
		  If ok Then Return buffer
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Inflate(Source As MemoryBlock, Dictionary As MemoryBlock = Nil, Encoding As Integer = zlib.DEFLATE_ENCODING) As MemoryBlock
		  ' Decompress the Source data and return it. Reverses the Deflate method
		  
		  Dim src As New BinaryStream(Source)
		  Return Inflate(src, Dictionary, Encoding)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Inflate(Source As Readable, Dictionary As MemoryBlock = Nil, Encoding As Integer = zlib.DEFLATE_ENCODING) As MemoryBlock
		  ' Decompress the Source stream and return it. Reverses the Deflate method
		  
		  Dim buffer As New MemoryBlock(0)
		  Dim stream As New BinaryStream(buffer)
		  If Not Inflate(Source, stream, Dictionary, Encoding) Then Return Nil
		  stream.Close
		  Return buffer
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Inflate(Source As Readable, Destination As Writeable, Dictionary As MemoryBlock = Nil, Encoding As Integer = zlib.DEFLATE_ENCODING) As Boolean
		  ' Decompress the Source stream and write the output to the Destination stream. Reverses the Deflate method
		  
		  Dim z As ZStream
		  If Encoding = DEFLATE_ENCODING Then
		    z = ZStream.Open(Source)
		  Else
		    z = ZStream.Open(Source, Encoding)
		  End If
		  Try
		    z.Dictionary = Dictionary
		    Do Until z.EOF
		      Destination.Write(z.Read(CHUNK_SIZE))
		    Loop
		  Finally
		    z.Close
		  End Try
		  Return True
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
		Private Soft Declare Function inflateGetHeader Lib "zlib1" (ByRef Stream As z_stream, ByRef Header As gz_headerp) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateInit2_ Lib "zlib1" (ByRef Stream As z_stream, WindowBits As Integer, Version As CString, StreamSz As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateInit_ Lib "zlib1" (ByRef Stream As z_stream, Version As CString, StreamSz As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateMark Lib "zlib1" (ByRef Stream As z_stream) As UInt32
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
		Private Soft Declare Function zlibCompileFlags Lib "zlib1" () As UInt32
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

	#tag Constant, Name = DEFLATE_ENCODING, Type = Double, Dynamic = False, Default = \"15", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = GZIP_ENCODING, Type = Double, Dynamic = False, Default = \"31", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = RAW_ENCODING, Type = Double, Dynamic = False, Default = \"-15", Scope = Protected
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

	#tag Constant, Name = Z_DETECT, Type = Double, Dynamic = False, Default = \"47", Scope = Protected
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


	#tag Structure, Name = gz_headerp, Flags = &h1
		Text As Integer
		  Time As UInt32
		  xflags As Integer
		  OS As Integer
		  Extra As Ptr
		  ExtraLen As UInt32
		  ExtraMax As UInt32
		  Name As Ptr
		  NameMax As UInt32
		  Comment As Ptr
		  CommentMax As UInt32
		  hcrc As Integer
		Done As Integer
	#tag EndStructure

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
