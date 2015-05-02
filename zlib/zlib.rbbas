#tag Module
Protected Module zlib
	#tag Method, Flags = &h1
		Protected Function Adler32(NewData As MemoryBlock, LastAdler As UInt32) As UInt32
		  ' You must call this method once with NIL to initialize, and then pass back the returned value to each pass.
		  '    Dim adler As UInt32 = zlib.Adler32(Nil, 0) //initialize
		  '    While True
		  '      adler = Adler32(NextInputData, adler)
		  '    Wend
		  
		  If NewData <> Nil Then
		    Return _adler32(LastAdler, NewData, NewData.Size)
		  Else
		    Return _adler32(0, Nil, 0)
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Compress(Data As MemoryBlock, CompressionLevel As Integer = Z_DEFAULT_COMPRESSION) As MemoryBlock
		  Dim cb As UInt32 = zlib.compressBound(Data.Size)
		  Dim out As New MemoryBlock(cb)
		  Dim err As Integer
		  If CompressionLevel = Z_DEFAULT_COMPRESSION Then
		    err = zlib._compress(out, cb, Data, Data.Size)
		  Else
		    err = zlib._compress2(out, cb, Data, Data.Size, CompressionLevel)
		  End If
		  If err = Z_OK Then
		    Return out.StringValue(0, cb)
		  Else
		    Break
		  End If
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function compressBound Lib "zlib1" (sourceLen As UInt64) As UInt32
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function CRC32(NewData As MemoryBlock, LastCRC As UInt32) As UInt32
		  ' You must call this method once with NIL to initialize, and then pass back the returned value to each pass.
		  '    Dim crc As UInt32 = zlib.CRC32(Nil, 0) //initialize
		  '    While True
		  '      crc = CRC32(NextInputData, crc)
		  '    Wend
		  
		  If NewData <> Nil Then
		    Return _crc32(LastCRC, NewData, NewData.Size)
		  Else
		    Return _crc32(0, Nil, 0)
		  End If
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function deflate Lib "zlib1" (ByRef Stream As zlib . z_stream, Flush As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function deflateBound Lib "zlib1" (ByRef Stream As zlib . z_stream, sourceLen As UInt32) As UInt32
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function deflateEnd Lib "zlib1" (ByRef Stream As zlib . z_stream) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function deflateInit_ Lib "zlib1" (ByRef Stream As zlib . z_stream, CompressionLevel As Integer, Version As CString, StreamSz As Integer) As Integer
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function FormatError(ErrorCode As Integer) As String
		  If zlib.IsAvailable Then
		    Dim err As MemoryBlock = zlib.zError(ErrorCode)
		    Return err.CString(0)
		  End If
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function gzclose Lib "zlib1" (gzFile As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function gzdopen Lib "zlib1" (FileDescriptor As Integer, Mode As CString) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function gzeof Lib "zlib1" (gzFile As Ptr) As Boolean
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function gzerror Lib "zlib1" (gzFile As Ptr, ByRef ErrorNum As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function gzflush Lib "zlib1" (gzFile As Ptr, Flush As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function gzoffset Lib "zlib1" (gzFile As Ptr) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function gzopen Lib "zlib1" (Path As CString, Mode As CString) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function gzread Lib "zlib1" (gzFile As Ptr, Buffer As Ptr, Length As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function gzseek Lib "zlib1" (gzFile As Ptr, Offset As Integer, Whence As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function gzsetparams Lib "zlib1" (gzFile As Ptr, Level As Integer, Strategy As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function gzwrite Lib "zlib1" (gzFile As Ptr, Buffer As Ptr, Length As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function inflate Lib "zlib1" (ByRef Stream As zlib . z_stream, Flush As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function inflateInit_ Lib "zlib1" (ByRef Stream As zlib . z_stream, Version As CString, StreamSz As Integer) As Integer
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function IsAvailable() As Boolean
		  Return System.IsFunctionAvailable("zlibVersion", "zlib1")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Uncompress(Data As MemoryBlock, ExpandedSize As Integer) As MemoryBlock
		  Dim out As New MemoryBlock(ExpandedSize)
		  Dim outsz As UInt32 = out.Size
		  Dim err As Integer = zlib._uncompress(out, outsz, Data, Data.Size)
		  If err = Z_OK Then
		    Return out.StringValue(0, outsz)
		  Else
		    Break
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Version() As String
		  Dim mb As MemoryBlock = zlib.zlibVersion
		  Return mb.CString(0)
		End Function
	#tag EndMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function zError Lib "zlib1" (ErrorCode As Integer) As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function zlibVersion Lib "zlib1" () As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function _adler32 Lib "zlib1" Alias "adler32" (adler As UInt32, Buffer As Ptr, BufferLen As UInt32) As UInt32
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function _compress Lib "zlib1" Alias "compress" (Output As Ptr, ByRef OutLen As UInt32, Source As Ptr, SourceLen As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function _compress2 Lib "zlib1" Alias "compress2" (Output As Ptr, ByRef OutLen As UInt32, Source As Ptr, SourceLen As UInt32, Level As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function _crc32 Lib "zlib1" Alias "crc32" (crc As UInt32, Buffer As Ptr, BufferLen As UInt32) As UInt32
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function _uncompress Lib "zlib1" Alias "uncompress" (Output As Ptr, ByRef OutLen As UInt32, Source As Ptr, SourceLen As UInt32) As Integer
	#tag EndExternalMethod


	#tag Constant, Name = Z_BUF_ERROR, Type = Double, Dynamic = False, Default = \"-5", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_DATA_ERROR, Type = Double, Dynamic = False, Default = \"-3", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_DEFAULT_COMPRESSION, Type = Double, Dynamic = False, Default = \"-1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_DEFAULT_STRATEGY, Type = Double, Dynamic = False, Default = \"0", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_ERRNO, Type = Double, Dynamic = False, Default = \"-1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_FINISH, Type = Double, Dynamic = False, Default = \"4", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_FULL_FLUSH, Type = Double, Dynamic = False, Default = \"3", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_MEM_ERROR, Type = Double, Dynamic = False, Default = \"-4", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_NO_FLUSH, Type = Double, Dynamic = False, Default = \"0", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_OK, Type = Double, Dynamic = False, Default = \"0", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_PARTIAL_FLUSH, Type = Double, Dynamic = False, Default = \"1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_STREAM_END, Type = Double, Dynamic = False, Default = \"1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_STREAM_ERROR, Type = Double, Dynamic = False, Default = \"-2", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_SYNC_FLUSH, Type = Double, Dynamic = False, Default = \"2", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_VERSION_ERROR, Type = Double, Dynamic = False, Default = \"-6", Scope = Protected
	#tag EndConstant


	#tag Structure, Name = z_stream, Flags = &h1
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
