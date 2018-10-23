#tag Module
Protected Module BZip2
	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function BZ2_bzCompress Lib libbzip2 (ByRef Stream As bz_stream, Action As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function BZ2_bzCompressEnd Lib libbzip2 (ByRef Stream As bz_stream) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function BZ2_bzCompressInit Lib libbzip2 (ByRef Stream As bz_stream, BlockSize100k As Integer, Verbosity As Integer, WorkFactor As Integer) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function BZ2_bzDecompress Lib libbzip2 (ByRef Stream As bz_stream) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function BZ2_bzDecompressEnd Lib libbzip2 (ByRef Stream As bz_stream) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h21
		Private Soft Declare Function BZ2_bzDecompressInit Lib libbzip2 (ByRef Stream As bz_stream, Verbosity As Integer, Small As Integer) As Integer
	#tag EndExternalMethod

	#tag Method, Flags = &h1
		Protected Function IsAvailable() As Boolean
		  Static mIsAvailable As Boolean
		  
		  If Not mIsAvailable Then mIsAvailable = System.IsFunctionAvailable("BZ2_bzCompressInit", libbzip2)
		  Return mIsAvailable
		End Function
	#tag EndMethod


	#tag Note, Name = Copying
		RB-BZip2 (https://github.com/charonn0/RB-zlib)
		
		Copyright (c)2018 Andrew Lambert, all rights reserved.
		
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


	#tag Constant, Name = BZ_CONFIG_ERROR, Type = Double, Dynamic = False, Default = \"-9", Scope = Private
	#tag EndConstant

	#tag Constant, Name = BZ_DATA_ERROR, Type = Double, Dynamic = False, Default = \"-4", Scope = Private
	#tag EndConstant

	#tag Constant, Name = BZ_DATA_ERROR_MAGIC, Type = Double, Dynamic = False, Default = \"-5", Scope = Private
	#tag EndConstant

	#tag Constant, Name = BZ_DEFAULT_COMPRESSION, Type = Double, Dynamic = False, Default = \"6", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = BZ_FINISH, Type = Double, Dynamic = False, Default = \"2", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = BZ_FINISH_OK, Type = Double, Dynamic = False, Default = \"3", Scope = Private
	#tag EndConstant

	#tag Constant, Name = BZ_FLUSH, Type = Double, Dynamic = False, Default = \"1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = BZ_FLUSH_OK, Type = Double, Dynamic = False, Default = \"2", Scope = Private
	#tag EndConstant

	#tag Constant, Name = BZ_IO_ERROR, Type = Double, Dynamic = False, Default = \"-6", Scope = Private
	#tag EndConstant

	#tag Constant, Name = BZ_MEM_ERROR, Type = Double, Dynamic = False, Default = \"-3", Scope = Private
	#tag EndConstant

	#tag Constant, Name = BZ_OK, Type = Double, Dynamic = False, Default = \"0", Scope = Private
	#tag EndConstant

	#tag Constant, Name = BZ_OUTBUFF_FULL, Type = Double, Dynamic = False, Default = \"-8", Scope = Private
	#tag EndConstant

	#tag Constant, Name = BZ_PARAM_ERROR, Type = Double, Dynamic = False, Default = \"-2", Scope = Private
	#tag EndConstant

	#tag Constant, Name = BZ_RUN, Type = Double, Dynamic = False, Default = \"0", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = BZ_RUN_OK, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = BZ_SEQUENCE_ERROR, Type = Double, Dynamic = False, Default = \"-1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = BZ_STREAM_END, Type = Double, Dynamic = False, Default = \"4", Scope = Private
	#tag EndConstant

	#tag Constant, Name = BZ_UNEXPECTED_EOF, Type = Double, Dynamic = False, Default = \"-7", Scope = Private
	#tag EndConstant

	#tag Constant, Name = CHUNK_SIZE, Type = Double, Dynamic = False, Default = \"16384", Scope = Private
	#tag EndConstant

	#tag Constant, Name = libbzip2, Type = String, Dynamic = False, Default = \"libbzip2.so.1", Scope = Private
		#Tag Instance, Platform = Windows, Language = Default, Definition  = \"bzip2.dll"
		#Tag Instance, Platform = Mac OS, Language = Default, Definition  = \"/usr/lib/libbzip2.dylib"
		#Tag Instance, Platform = Linux, Language = Default, Definition  = \"libbzip2.so.1"
	#tag EndConstant


	#tag Structure, Name = bz_stream, Flags = &h21
		Next_In As Ptr
		  Avail_In As UInt32
		  Total_In_Low As UInt32
		  Total_In_High As UInt32
		  Next_Out As Ptr
		  Avail_Out As UInt32
		  Total_Out_Low As UInt32
		  Total_Out_High As UInt32
		  State As Ptr
		  Alloc As Ptr
		  Free As Ptr
		Opaque As Ptr
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
