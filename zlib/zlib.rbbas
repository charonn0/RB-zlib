#tag Module
Protected Module zlib
	#tag Method, Flags = &h1
		Protected Function Adler32(NewData As MemoryBlock, LastAdler As UInt32 = 0, NewDataSize As Integer = -1) As UInt32
		  ' Calculate the Adler32 checksum for the NewData. Pass back the returned value
		  ' to continue processing.
		  '    Dim adler As UInt32
		  '    Do
		  '      adler = zlib.Adler32(NextInputData, adler)
		  '    Loop
		  ' If NewData.Size is not known (-1) then specify the size as NewDataSize
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Adler32
		  
		  If Not zlib.IsAvailable Or NewData = Nil Then Return 0
		  Static ADLER_POLYNOMIAL As UInt32
		  If ADLER_POLYNOMIAL = 0 Then ADLER_POLYNOMIAL = _adler32(0, Nil, 0)
		  
		  If NewDataSize = -1 Then NewDataSize = NewData.Size
		  If LastAdler = 0 Then LastAdler = ADLER_POLYNOMIAL
		  Return _adler32(LastAdler, NewData, NewDataSize)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Adler32Combine(Adler1 As UInt32, Adler2 As UInt32, Length2 As UInt32) As UInt32
		  ' Combine Adler1 and Adler2, needing only then length of the data for Adler2
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Adler32Combine
		  
		  If Not zlib.IsAvailable Then Return 0
		  Return _adler32_combine(Adler1, Adler2, Length2)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Attributes( deprecated = "zlib.Deflate" ) Protected Function Compress(Data As MemoryBlock, CompressionLevel As Integer = Z_DEFAULT_COMPRESSION, DataSize As Integer = -1) As MemoryBlock
		  ' Compress memory in one operation using deflate. If Data.Size is not known (-1) then
		  ' specify the size as DataSize. Use Uncompress() to reverse.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Compress
		  
		  If Not zlib.IsAvailable Then Raise New PlatformNotSupportedException
		  
		  If DataSize = -1 Then DataSize = Data.Size
		  Dim OutSize As UInt32 = compressBound(DataSize)
		  Dim OutBuffer As MemoryBlock
		  Dim err As Integer
		  If CompressionLevel < Z_NO_COMPRESSION Or CompressionLevel > Z_BEST_COMPRESSION Then CompressionLevel = Z_DEFAULT_COMPRESSION
		  
		  Do
		    If OutBuffer <> Nil Then OutSize = OutSize * 2
		    OutBuffer = New MemoryBlock(OutSize)
		    If CompressionLevel = Z_DEFAULT_COMPRESSION Then
		      err = _compress(OutBuffer, OutSize, Data, DataSize)
		    Else
		      err = _compress2(OutBuffer, OutSize, Data, DataSize, CompressionLevel)
		    End If
		  Loop Until err <> Z_BUF_ERROR
		  
		  If err <> Z_OK Then Raise New zlibException(err)
		  
		  OutBuffer.Size = OutSize
		  Return OutBuffer
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function CompressBound(DataLength As UInt32) As UInt32
		  ' Computes the upper bound of the compressed size after deflation of DataLength bytes.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.CompressBound
		  
		  If Not zlib.IsAvailable Then Raise New PlatformNotSupportedException
		  
		  Return compressBound_(DataLength)
		  
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function compressBound_ Lib zlib1 Alias "compressBound" (sourceLen As UInt32) As UInt32
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function CRC32(NewData As MemoryBlock, LastCRC As UInt32 = 0, NewDataSize As Integer = -1) As UInt32
		  ' Calculate the CRC32 checksum for the NewData. Pass back the returned value
		  ' to continue processing.
		  '    Dim crc As UInt32
		  '    While True
		  '      crc = zlib.CRC32(NextInputData, crc)
		  '    Wend
		  ' If NewData.Size is not known (-1) then specify the size as NewDataSize
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.CRC32
		  
		  Static avail As Boolean
		  If Not avail Then avail = zlib.IsAvailable
		  If Not avail Or NewData = Nil Then Return 0
		  
		  If NewDataSize = -1 Then NewDataSize = NewData.Size
		  Return _crc32(LastCRC, NewData, NewDataSize)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function CRC32Combine(CRC1 As UInt32, CRC2 As UInt32, Length2 As UInt32) As UInt32
		  ' Combine CRC1 and CRC2, needing only then length of the data for crc2
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.CRC32Combine
		  
		  If Not zlib.IsAvailable Then Return 0
		  Return _crc32_combine(CRC1, CRC2, Length2)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Deflate(Source As FolderItem, Destination As FolderItem, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Overwrite As Boolean = False, Encoding As Integer = zlib.DEFLATE_ENCODING) As Boolean
		  ' Compress the Source file into the Destination file. Use Inflate to reverse.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Deflate
		  
		  Dim dst As BinaryStream = BinaryStream.Create(Destination, Overwrite)
		  Dim src As BinaryStream = BinaryStream.Open(Source)
		  Dim ok As Boolean
		  Try
		    ' calls Deflate(Readable, Writeable, Integer, Integer) As Boolean
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
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Deflate
		  
		  Dim buffer As New MemoryBlock(0)
		  Dim dst As New BinaryStream(buffer)
		  Dim src As BinaryStream = BinaryStream.Open(Source)
		  Dim ok As Boolean
		  Try
		    ' calls Deflate(Readable, Writeable, Integer, Integer) As Boolean
		    ok = Deflate(src, dst, CompressionLevel, Encoding)
		  Finally
		    src.Close
		    dst.Close
		  End Try
		  If ok Then Return buffer
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Deflate(Source As FolderItem, Destination As Writeable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Encoding As Integer = zlib.DEFLATE_ENCODING) As Boolean
		  ' Compress the Source file into the Destination stream. Use Inflate to reverse.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Deflate
		  
		  Dim src As BinaryStream = BinaryStream.Open(Source)
		  Dim ok As Boolean
		  Try
		    ' calls Deflate(Readable, Writeable, Integer, Integer) As Boolean
		    ok = Deflate(src, Destination, CompressionLevel, Encoding)
		  Finally
		    src.Close
		  End Try
		  Return ok
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Deflate(Source As MemoryBlock, Destination As FolderItem, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Overwrite As Boolean = False, Encoding As Integer = zlib.DEFLATE_ENCODING) As Boolean
		  ' Compress the Source data into the Destination file. Use Inflate to reverse.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Deflate
		  
		  Dim dst As BinaryStream = BinaryStream.Create(Destination, Overwrite)
		  Dim ok As Boolean
		  Try
		    ' calls Deflate(MemoryBlock, Writeable, Integer, Integer) As Boolean
		    ok = Deflate(Source, dst, CompressionLevel, Encoding)
		  Finally
		    dst.Close
		  End Try
		  Return ok
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Deflate(Source As MemoryBlock, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Encoding As Integer = zlib.DEFLATE_ENCODING) As MemoryBlock
		  ' Compress the Source data and return it. Use Inflate to reverse.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Deflate
		  
		  Dim buffer As New MemoryBlock(0)
		  Dim dst As New BinaryStream(buffer)
		  Dim src As New BinaryStream(Source)
		  ' calls Deflate(Readable, Writeable, Integer, Integer) As Boolean
		  If Not Deflate(src, dst, CompressionLevel, Encoding) Then Return Nil
		  dst.Close
		  Return buffer
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Deflate(Source As MemoryBlock, Destination As Writeable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Encoding As Integer = zlib.DEFLATE_ENCODING) As Boolean
		  ' Compress the Source data into the Destination stream. Use Inflate to reverse.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Deflate
		  
		  Dim src As New BinaryStream(Source)
		  ' calls Deflate(Readable, Writeable, Integer, Integer) As Boolean
		  Return Deflate(src, Destination, CompressionLevel, Encoding)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Deflate(Source As Readable, Destination As FolderItem, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Overwrite As Boolean = False, Encoding As Integer = zlib.DEFLATE_ENCODING) As Boolean
		  ' Compress the Source stream into the Destination file. Use Inflate to reverse.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Deflate
		  
		  Dim dst As BinaryStream = BinaryStream.Create(Destination, Overwrite)
		  Dim ok As Boolean
		  Try
		    ' calls Deflate(Readable, Writeable, Integer, Integer) As Boolean
		    ok = Deflate(Source, dst, CompressionLevel, Encoding)
		  Finally
		    dst.Close
		  End Try
		  Return ok
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Deflate(Source As Readable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Encoding As Integer = zlib.DEFLATE_ENCODING) As MemoryBlock
		  ' Compress the Source stream and return it. Use Inflate to reverse.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Deflate
		  
		  Dim buffer As New MemoryBlock(0)
		  Dim stream As New BinaryStream(buffer)
		  ' calls Deflate(Readable, Writeable, Integer, Integer) As Boolean
		  If Not Deflate(Source, stream, CompressionLevel, Encoding) Then Return Nil
		  stream.Close
		  Return buffer
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Deflate(Source As Readable, Destination As Writeable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Encoding As Integer = zlib.DEFLATE_ENCODING) As Boolean
		  ' Deflate the Source stream and write the output to the Destination stream. Use Inflate to reverse.
		  ' Calling this method with the default parameters produces the same output as zlib.Compress. The difference
		  ' is that the size of the input to this method is not limited by available memory whereas Compress() has less
		  ' memory overhead.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Deflate
		  
		  Dim z As ZStream = ZStream.Create(Destination, CompressionLevel, Encoding)
		  Try
		    Do Until Source.EOF
		      z.Write(Source.Read(CHUNK_SIZE))
		    Loop
		    z.Close
		  Catch
		    Return False
		  End Try
		  Return True
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateBound Lib zlib1 (Stream As Ptr, DataLength As UInt32) As UInt32
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateCopy Lib zlib1 (Dst As Ptr, Src As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateEnd Lib zlib1 (Stream As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateInit2_ Lib zlib1 (Stream As Ptr, CompressionLevel As Integer, CompressionMethod As Integer, Encoding As Integer, MemLevel As Integer, Strategy As Integer, Version As CString, StreamSz As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateInit_ Lib zlib1 (Stream As Ptr, CompressionLevel As Integer, Version As CString, StreamSz As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateParams Lib zlib1 (Stream As Ptr, Level As Integer, Strategy As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflatePending Lib zlib1 (Stream As Ptr, ByRef Pending As UInt32, ByRef Bits As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflatePrime Lib zlib1 (Stream As Ptr, Bits As Integer, Value As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateReset Lib zlib1 (Stream As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateSetDictionary Lib zlib1 (Stream As Ptr, Dictionary As Ptr, DictLength As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateSetHeader Lib zlib1 (Stream As Ptr, Header As gz_headerp) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflateTune Lib zlib1 (Stream As Ptr, GoodLength As Integer, MaxLazy As Integer, NiceLength As Integer, MaxChain As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function deflate_ Lib zlib1 Alias "deflate" (Stream As Ptr, Flush As Integer) As Integer
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function GUnZip(Source As FolderItem) As MemoryBlock
		  ' GUnZip the Source file and return it. Reverses the GZip method
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.GUnZip
		  
		  ' calls Inflate(FolderItem, MemoryBlock, Integer) As MemoryBlock
		  Return Inflate(Source, Nil, GZIP_ENCODING)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GUnZip(Source As FolderItem, Destination As FolderItem, Overwrite As Boolean = False) As Boolean
		  ' GUnZip the Source file and write the output to the Destination file. Reverses the GZip method
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.GUnZip
		  
		  ' calls Inflate(FolderItem, FolderItem, Boolean, MemoryBlock, Integer) As Boolean
		  Return Inflate(Source, Destination, Overwrite, Nil, GZIP_ENCODING)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GUnZip(Source As FolderItem, Destination As Writeable) As Boolean
		  ' Gunzip the Source file into the Destination stream. Reverses the GZip method
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.GUnZip
		  
		  ' calls Inflate(FolderItem, Writeable, Integer, Integer) As Boolean
		  Return Inflate(Source, Destination, Nil, GZIP_ENCODING)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GUnZip(Source As MemoryBlock) As MemoryBlock
		  ' GUnZip the Source data and return it. Reverses the GZip method
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.GUnZip
		  
		  ' calls Inflate(MemoryBlock, MemoryBlock, Integer) As MemoryBlock
		  Return Inflate(Source, Nil, GZIP_ENCODING)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GUnZip(Source As MemoryBlock, Destination As FolderItem, Overwrite As Boolean = False) As Boolean
		  ' GUnzips the Source data into the Destination file. Reverses the GZip method
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.GUnZip
		  
		  ' calls Inflate(MemoryBlock, FolderItem, Boolean, MemoryBlock, Integer) As Boolean
		  Return Inflate(Source, Destination, Overwrite, Nil, GZIP_ENCODING)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GUnZip(Source As MemoryBlock, Destination As Writeable) As Boolean
		  ' GUnzips the Source data into the Destination stream. Reverses the GZip method
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.GUnZip
		  
		  ' calls Inflate(MemoryBlock, Writeable, MemoryBlock, Integer) As Boolean
		  Return Inflate(Source, Destination, Nil, GZIP_ENCODING)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GUnZip(Source As Readable) As MemoryBlock
		  ' GUnZip the Source stream and Return it. Reverses the GZip method.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.GUnZip
		  
		  ' calls Inflate(Readable, MemoryBlock, Integer) As MemoryBlock
		  Return Inflate(Source, Nil, GZIP_ENCODING)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GUnZip(Source As Readable, Destination As FolderItem, Overwrite As Boolean = False) As Boolean
		  ' GUnZip the Source stream into the Destination file. Reverses the GZip method.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.GUnZip
		  
		  ' calls Inflate(Readable, FolderItem, Boolean, MemoryBlock, Integer) As Boolean
		  Return Inflate(Source, Destination, Overwrite, Nil, GZIP_ENCODING)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GUnZip(Source As Readable, Destination As Writeable) As Boolean
		  ' GUnZip the Source stream and write the output to the Destination stream. Reverses the GZip method
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.GUnZip
		  
		  ' calls Inflate(Readable, Writeable, MemoryBlock, Integer) As Boolean
		  Return Inflate(Source, Destination, Nil, GZIP_ENCODING)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GZip(Source As FolderItem, Destination As FolderItem, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Overwrite As Boolean = False) As Boolean
		  ' GZip the Source file into the Destination file. Use GUnZip to reverse.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.GZip
		  
		  ' calls Deflate(FolderItem, FolderItem, Integer, Boolean, Integer) As Boolean
		  Return Deflate(Source, Destination, CompressionLevel, Overwrite, GZIP_ENCODING)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GZip(Source As FolderItem, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION) As MemoryBlock
		  ' GZip the Source file and return it. Use GUnZip to reverse.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.GZip
		  
		  ' calls Deflate(FolderItem, Integer, Integer) As MemoryBlock
		  Return Deflate(Source, CompressionLevel, GZIP_ENCODING)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GZip(Source As FolderItem, Destination As Writeable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION) As Boolean
		  ' GZip the Source file into the Destination stream. Use GUnZip to reverse.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.GZip
		  
		  ' calls Deflate(FolderItem, Writeable, Integer, Integer) As Boolean
		  Return Deflate(Source, Destination, CompressionLevel, GZIP_ENCODING)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GZip(Source As MemoryBlock, Destination As FolderItem, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Overwrite As Boolean = False) As Boolean
		  ' GZip the Source data into the Destination file. Use GUnZip to reverse.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.GZip
		  
		  ' calls Deflate(MemoryBlock, FolderItem, Integer, Boolean, Integer) As Boolean
		  Return Deflate(Source, Destination, CompressionLevel, Overwrite, GZIP_ENCODING)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GZip(Source As MemoryBlock, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION) As MemoryBlock
		  ' GZip the Source data and return it. Use GUnZip to reverse.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.GZip
		  
		  ' calls Deflate(MemoryBlock, Integer, Integer) As MemoryBlock
		  Return Deflate(Source, CompressionLevel, GZIP_ENCODING)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GZip(Source As MemoryBlock, Destination As Writeable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION) As Boolean
		  ' GZip the Source data into the Destination stream. Use GUnZip to reverse.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.GZip
		  
		  Dim src As New BinaryStream(Source)
		  ' calls Deflate(Readable, Writeable, Integer, Integer) As Boolean
		  Return Deflate(src, Destination, CompressionLevel, GZIP_ENCODING)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GZip(Source As Readable, Destination As FolderItem, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, Overwrite As Boolean = False) As Boolean
		  ' GZip the Source stream into the Destination file. Use GUnZip to reverse.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.GZip
		  
		  ' calls Deflate(Readable, FolderItem, Integer, Boolean, Integer) As Boolean
		  Return Deflate(Source, Destination, CompressionLevel, Overwrite, GZIP_ENCODING)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GZip(Source As Readable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION) As MemoryBlock
		  ' GZip the Source stream and return it. Use GUnZip to reverse.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.GZip
		  
		  ' calls Deflate(Readable, Integer, Integer) As MemoryBlock
		  Return Deflate(Source, CompressionLevel, GZIP_ENCODING)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GZip(Source As Readable, Destination As Writeable, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION) As Boolean
		  ' GZip the Source stream and write the output to the Destination stream. Use GUnZip to reverse.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.GZip
		  
		  ' calls Deflate(Readable, Writeable, Integer, Integer) As Boolean
		  Return Deflate(Source, Destination, CompressionLevel, GZIP_ENCODING)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Inflate(Source As FolderItem, Destination As FolderItem, Overwrite As Boolean = False, Dictionary As MemoryBlock = Nil, Encoding As Integer = zlib.DEFLATE_ENCODING) As Boolean
		  ' Decompress the Source file and write the output to the Destination file. Reverses the Deflate method
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Inflate
		  
		  Dim dst As BinaryStream = BinaryStream.Create(Destination, Overwrite)
		  Dim src As BinaryStream = BinaryStream.Open(Source)
		  Dim ok As Boolean
		  Try
		    ' calls Inflate(Readable, Writeable, MemoryBlock, Integer) As Boolean
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
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Inflate
		  
		  Dim buffer As New MemoryBlock(0)
		  Dim dst As New BinaryStream(buffer)
		  Dim src As BinaryStream = BinaryStream.Open(Source)
		  Dim ok As Boolean
		  Try
		    ' calls Inflate(Readable, Writeable, MemoryBlock, Integer) As Boolean
		    ok = Inflate(src, dst, Dictionary, Encoding)
		  Finally
		    src.Close
		    dst.Close
		  End Try
		  If ok Then Return buffer
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Inflate(Source As FolderItem, Destination As Writeable, Dictionary As MemoryBlock = Nil, Encoding As Integer = zlib.DEFLATE_ENCODING) As Boolean
		  ' Decompresses the Source file into the Destination stream. Reverses the Deflate method
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Inflate
		  
		  Dim src As BinaryStream = BinaryStream.Open(Source)
		  Dim ok As Boolean
		  Try
		    ' calls Inflate(Readable, Writeable, Integer, Integer) As Boolean
		    ok = Inflate(src, Destination, Dictionary, Encoding)
		  Finally
		    src.Close
		  End Try
		  Return ok
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Inflate(Source As MemoryBlock, Destination As FolderItem, Overwrite As Boolean = False, Dictionary As MemoryBlock = Nil, Encoding As Integer = zlib.DEFLATE_ENCODING) As Boolean
		  ' Decompress the Source data into the Destination file. Reverses the Deflate method
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Inflate
		  
		  Dim dst As BinaryStream = BinaryStream.Create(Destination, Overwrite)
		  Dim src As New BinaryStream(Source)
		  Dim ok As Boolean
		  Try
		    ' calls Inflate(Readable, Writeable, MemoryBlock, Integer) As Boolean
		    ok = Inflate(src, dst, Dictionary, Encoding)
		  Finally
		    src.Close
		    dst.Close
		  End Try
		  Return ok
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Inflate(Source As MemoryBlock, Dictionary As MemoryBlock = Nil, Encoding As Integer = zlib.DEFLATE_ENCODING) As MemoryBlock
		  ' Decompress the Source data and return it. Reverses the Deflate method
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Inflate
		  
		  Dim src As New BinaryStream(Source)
		  ' calls Inflate(Readable, MemoryBlock, Integer) As MemoryBlock
		  Return Inflate(src, Dictionary, Encoding)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Inflate(Source As MemoryBlock, Destination As Writeable, Dictionary As MemoryBlock = Nil, Encoding As Integer = zlib.DEFLATE_ENCODING) As Boolean
		  ' Decompress the Source data into the Destination stream. Reverses the Deflate method
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Inflate
		  
		  Dim src As New BinaryStream(Source)
		  Dim ok As Boolean
		  Try
		    ' calls Inflate(Readable, Writeable, MemoryBlock, Integer) As Boolean
		    ok = Inflate(src, Destination, Dictionary, Encoding)
		  Finally
		    src.Close
		  End Try
		  Return ok
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflate Lib zlib1 (Stream As Ptr, Flush As Integer) As Integer
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function Inflate(Source As Readable, Destination As FolderItem, Overwrite As Boolean = False, Dictionary As MemoryBlock = Nil, Encoding As Integer = zlib.DEFLATE_ENCODING) As Boolean
		  ' Decompress the Source stream into the Destination file. Reverses the Deflate method
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Inflate
		  
		  Dim dst As BinaryStream = BinaryStream.Create(Destination, Overwrite)
		  Dim ok As Boolean
		  Try
		    ' calls Inflate(Readable, Writeable, MemoryBlock, Integer) As Boolean
		    ok = Inflate(Source, dst, Dictionary, Encoding)
		  Finally
		    dst.Close
		  End Try
		  Return ok
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Inflate(Source As Readable, Dictionary As MemoryBlock = Nil, Encoding As Integer = zlib.DEFLATE_ENCODING) As MemoryBlock
		  ' Decompress the Source stream and return it. Reverses the Deflate method
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Inflate
		  
		  Dim buffer As New MemoryBlock(0)
		  Dim stream As New BinaryStream(buffer)
		  ' calls Inflate(Readable, Writeable, MemoryBlock, Integer) As Boolean
		  If Not Inflate(Source, stream, Dictionary, Encoding) Then Return Nil
		  stream.Close
		  Return buffer
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Inflate(Source As Readable, Destination As Writeable, Dictionary As MemoryBlock = Nil, Encoding As Integer = zlib.DEFLATE_ENCODING) As Boolean
		  ' Decompress the Source stream and write the output to the Destination stream. Reverses the Deflate method
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Inflate
		  
		  Dim z As ZStream = ZStream.Open(Source, Encoding)
		  Try
		    z.BufferedReading = False
		    z.Dictionary = Dictionary
		    Do Until z.EOF
		      Dim data As MemoryBlock = z.Read(CHUNK_SIZE)
		      If data <> Nil And data.Size > 0 Then Destination.Write(Data)
		    Loop
		    z.Close
		  Catch
		    Return False
		  End Try
		  Return True
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateCopy Lib zlib1 (Dst As Ptr, Src As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateEnd Lib zlib1 (Stream As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateGetDictionary Lib zlib1 (Stream As Ptr, Dictionary As Ptr, ByRef DictLength As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateGetHeader Lib zlib1 (Stream As Ptr, ByRef Header As gz_headerp) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateInit2_ Lib zlib1 (Stream As Ptr, Encoding As Integer, Version As CString, StreamSz As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateInit_ Lib zlib1 (Stream As Ptr, Version As CString, StreamSz As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateMark Lib zlib1 (Stream As Ptr) As UInt32
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateReset Lib zlib1 (Stream As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateReset2 Lib zlib1 (Stream As Ptr, Encoding As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateSetDictionary Lib zlib1 (Stream As Ptr, Dictionary As Ptr, DictLength As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function inflateSync Lib zlib1 (Dst As Ptr) As Integer
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function IsAvailable() As Boolean
		  ' Returns True if zlib is available at runtime.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.IsAvailable
		  
		  Static mIsAvailable As Boolean
		  
		  If Not mIsAvailable Then mIsAvailable = System.IsFunctionAvailable("zlibVersion", zlib1)
		  Return mIsAvailable
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function IsDeflated(Extends Target As BinaryStream) As Boolean
		  //Checks the deflate magic number. Returns True if the Target is likely a deflate stream
		  
		  Dim IsDeflate As Boolean
		  Dim pos As UInt64 = Target.Position
		  If Target.ReadUInt8 = &h78 Then IsDeflate = True 'maybe
		  Target.Position = pos
		  Return IsDeflate
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsDeflated(Extends TargetFile As FolderItem) As Boolean
		  ' Checks the deflate magic number. Returns True if the TargetFile is likely a deflate stream.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.IsDeflated
		  
		  If Not TargetFile.Exists Then Return False
		  If TargetFile.Directory Then Return False
		  Dim bs As BinaryStream
		  Dim IsDeflate As Boolean
		  Try
		    bs = BinaryStream.Open(TargetFile)
		    IsDeflate = bs.IsDeflated()
		  Catch
		    IsDeflate = False
		  Finally
		    If bs <> Nil Then bs.Close
		  End Try
		  Return IsDeflate
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsDeflated(Extends Target As MemoryBlock) As Boolean
		  ' Checks the deflate magic number. Returns True if the Target is likely a deflate stream.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.IsDeflated
		  
		  If Target.Size = -1 Then Return False
		  Dim bs As BinaryStream
		  Dim IsDeflate As Boolean
		  Try
		    bs = New BinaryStream(Target)
		    IsDeflate = bs.IsDeflated()
		  Catch
		    IsDeflate = False
		  Finally
		    If bs <> Nil Then bs.Close
		  End Try
		  Return IsDeflate
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function IsGZipped(Extends Target As BinaryStream) As Boolean
		  //Checks the GZip magic number. Returns True if the Target is likely a GZip stream
		  
		  Dim IsGZ As Boolean
		  Dim pos As UInt64 = Target.Position
		  If Target.ReadUInt8 = &h1F And Target.ReadUInt8 = &h8B Then IsGZ = True
		  Target.Position = pos
		  Return IsGZ
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsGZipped(Extends TargetFile As FolderItem) As Boolean
		  ' Checks the GZip magic number. Returns True if the TargetFile is likely a GZip stream.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.IsGZipped
		  
		  If TargetFile.Directory Or Not TargetFile.Exists Then Return False
		  Dim bs As BinaryStream
		  Dim IsGZ As Boolean
		  Try
		    bs = bs.Open(TargetFile)
		    IsGZ = bs.IsGZipped()
		  Catch
		    IsGZ = False
		  Finally
		    If bs <> Nil Then bs.Close
		  End Try
		  Return IsGZ
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsGZipped(Extends Target As MemoryBlock) As Boolean
		  ' Checks the GZip magic number. Returns True if the Target is likely a GZip stream.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.IsGZipped
		  
		  If Target.Size = -1 Then Return False
		  Dim bs As BinaryStream
		  Dim IsGZ As Boolean
		  Try
		    bs = New BinaryStream(Target)
		    IsGZ = bs.IsGZipped()
		  Catch
		    IsGZ = False
		  Finally
		    If bs <> Nil Then bs.Close
		  End Try
		  Return IsGZ
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Attributes( deprecated = "zlib.Inflate" ) Protected Function Uncompress(Data As MemoryBlock, ExpandedSize As Integer = -1, DataSize As Integer = -1) As MemoryBlock
		  ' Decompress memory in one operation using deflate. If Data.Size is not known (-1) then
		  ' specify the size as DataSize. If the size of the decompressed data is known then pass
		  ' it as ExpandedSize. Reverses the Compress() method.
		  '
		  ' See: https://github.com/charonn0/RB-zlib/wiki/zlib.Uncompress
		  
		  If Not zlib.IsAvailable Then Raise New PlatformNotSupportedException
		  
		  If DataSize = -1 Then DataSize = Data.Size
		  If ExpandedSize <= 0 Then ExpandedSize = DataSize * 1.1 + 12
		  Dim OutputBuffer As MemoryBlock
		  Dim OutSize As UInt32
		  Dim err As Integer
		  
		  Do
		    OutputBuffer = New MemoryBlock(ExpandedSize)
		    OutSize = OutputBuffer.Size
		    err = _uncompress(OutputBuffer, OutSize, Data, DataSize)
		    ExpandedSize = ExpandedSize * 2
		  Loop Until err <> Z_BUF_ERROR
		  
		  If err <> Z_OK Then Raise New zlibException(err)
		  
		  OutputBuffer.Size = OutSize
		  Return OutputBuffer
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Version() As String
		  ' Returns the version string of zlib.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-zlib/wiki/zlib.Version
		  
		  If Not zlib.IsAvailable Then Return ""
		  Dim mb As MemoryBlock = zlibVersion
		  Return mb.CString(0)
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function zError Lib zlib1 (ErrorCode As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function zlibCompileFlags Lib zlib1 () As UInt32
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function zlibVersion Lib zlib1 () As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function _adler32 Lib zlib1 Alias "adler32" (adler As UInt32, Buffer As Ptr, BufferLen As UInt32) As UInt32
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function _adler32_combine Lib zlib1 Alias "adler32_combine" (adler1 As UInt32, adler2 As UInt32, Length2 As Int32) As UInt32
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function _compress Lib zlib1 Alias "compress" (Output As Ptr, ByRef OutLen As UInt32, Source As Ptr, SourceLen As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function _compress2 Lib zlib1 Alias "compress2" (Output As Ptr, ByRef OutLen As UInt32, Source As Ptr, SourceLen As UInt32, Level As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function _crc32 Lib zlib1 Alias "crc32" (crc As UInt32, Buffer As Ptr, BufferLen As UInt32) As UInt32
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function _crc32_combine Lib zlib1 Alias "crc32_combine" (crc1 As UInt32, crc2 As UInt32, Length2 As Int32) As UInt32
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function _gzerror Lib zlib1 Alias "gzerror" (gzFile As Ptr, ByRef ErrorNum As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function _uncompress Lib zlib1 Alias "uncompress" (Output As Ptr, ByRef OutLen As UInt32, Source As Ptr, SourceLen As UInt32) As Integer
	#tag EndExternalMethod


	#tag Note, Name = Copying
		RB-zlib (https://github.com/charonn0/RB-zlib)
		
		Copyright (c)2015-23 Andrew Lambert, all rights reserved.
		
		 Permission to use, copy, modify, and distribute this software for any purpose
		 with or without fee is hereby granted, provided that the above copyright
		 notice and this permission notice appear in all copies.
		 
		    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF THIRD PARTY RIGHTS. IN
		    NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
		    DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
		    OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
		    OR OTHER DEALINGS IN THE SOFTWARE.
		 
		 Except as contained in this notice, the name of a copyright holder shall not
		 be used in advertising or otherwise to promote the sale, use or other dealings
		 in this Software without prior written authorization of the copyright holder.
	#tag EndNote


	#tag Constant, Name = CHUNK_SIZE, Type = Double, Dynamic = False, Default = \"65535", Scope = Private
	#tag EndConstant

	#tag Constant, Name = DEFAULT_MEM_LVL, Type = Double, Dynamic = False, Default = \"8", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = DEFLATE_ENCODING, Type = Double, Dynamic = False, Default = \"15", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = GZIP_ENCODING, Type = Double, Dynamic = False, Default = \"31", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = RAW_ENCODING, Type = Double, Dynamic = False, Default = \"-15", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = zlib1, Type = String, Dynamic = False, Default = \"libz.so.1", Scope = Private
		#Tag Instance, Platform = Windows, Language = Default, Definition  = \"zlib1.dll"
		#Tag Instance, Platform = Mac OS, Language = Default, Definition  = \"/usr/lib/libz.dylib"
		#Tag Instance, Platform = Linux, Language = Default, Definition  = \"libz.so.1"
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

	#tag Constant, Name = Z_FULL_FLUSH, Type = Double, Dynamic = False, Default = \"3", Scope = Protected
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

	#tag Structure, Name = z_stream_32_1, Flags = &h21
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

	#tag Structure, Name = z_stream_32_8, Flags = &h21, Attributes = \"StructureAlignment \x3D 8"
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

	#tag Structure, Name = z_stream_64_8, Flags = &h21, Attributes = \"StructureAlignment \x3D 8"
		next_in as Ptr
		  avail_in as UInt64
		  total_in as UInt64
		  next_out as Ptr
		  avail_out as UInt64
		  total_out as UInt64
		  msg as Ptr
		  internal_state as Ptr
		  zalloc as Ptr
		  zfree as Ptr
		  opaque as Ptr
		  data_type as Int64
		  adler as UInt64
		reserved as UInt64
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
