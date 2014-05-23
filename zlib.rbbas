#tag Module
Protected Module zlib
	#tag Method, Flags = &h1
		Protected Function Compress(Data As MemoryBlock) As MemoryBlock
		  Dim out As New MemoryBlock(Data.Size)
		  Dim outsz As UInt32 = out.Size
		  Dim err As Integer = zlib._compress(out, outsz, Data, Data.Size)
		  If err = Z_OK Then
		    Return out.StringValue(0, outsz)
		  Else
		    Break
		  End If
		End Function
	#tag EndMethod

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
		Protected Soft Declare Function zlibVersion Lib "zlib1" () As Ptr
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function _compress Lib "zlib1" Alias "compress" (Output As Ptr, ByRef OutLen As UInt32, Source As Ptr, SourceLen As UInt32) As Integer
	#tag EndExternalMethod

	#tag ExternalMethod, Flags = &h1
		Protected Soft Declare Function _uncompress Lib "zlib1" Alias "uncompress" (Output As Ptr, ByRef OutLen As UInt32, Source As Ptr, SourceLen As UInt32) As Integer
	#tag EndExternalMethod


	#tag Constant, Name = Z_BUF_ERROR, Type = Double, Dynamic = False, Default = \"-5", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_DATA_ERROR, Type = Double, Dynamic = False, Default = \"-3", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_ERRNO, Type = Double, Dynamic = False, Default = \"-1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_MEM_ERROR, Type = Double, Dynamic = False, Default = \"-4", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_OK, Type = Double, Dynamic = False, Default = \"0", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_STREAM_ERROR, Type = Double, Dynamic = False, Default = \"-2", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Z_VERSION_ERROR, Type = Double, Dynamic = False, Default = \"-6", Scope = Protected
	#tag EndConstant


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