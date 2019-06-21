#tag Class
Protected Class ZipEntry
	#tag Method, Flags = &h0
		Sub Constructor(Header As ZipEntryHeader, Path As String, Offset As UInt32, Index As Integer)
		  mHeader = Header
		  mPath = Path
		  mOffset = Offset
		  mIndex = Index
		End Sub
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mHeader.CompressedSize
			End Get
		#tag EndGetter
		CompressedSize As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mIndex
			End Get
		#tag EndGetter
		Index As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the compression level that was used on the current item. Some archivers do not
			  ' fill in this information.
			  
			  Dim bit1, bit2 As Boolean
			  bit1 = (BitAnd(mHeader.Flag, 1) = 1)
			  bit2 = (BitAnd(mHeader.Flag, 2) = 2)
			  
			  Select Case True
			  Case bit1 And bit2
			    Return 1 ' fastest
			  Case Not bit1 And bit2
			    Return 3 ' fast
			  Case Not bit1 And Not bit2
			    Return 6 ' normal
			  Case bit1 And Not bit2
			    Return 9 ' best
			  Case Me.Method = 0
			    Return 0 ' none
			  End Select
			  
			  
			End Get
		#tag EndGetter
		Level As UInt32
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mCompressedSize As UInt32
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mHeader.Method
			End Get
		#tag EndGetter
		Method As UInt32
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mHeader As ZipEntryHeader
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mIndex As Integer
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return ConvertDate(mHeader.ModDate, mHeader.ModTime)
			End Get
		#tag EndGetter
		ModifiedDate As Date
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mOffset As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPath As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSize As UInt32
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mOffset
			End Get
		#tag EndGetter
		Offset As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mPath
			End Get
		#tag EndGetter
		Path As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mHeader.UncompressedSize
			End Get
		#tag EndGetter
		UncompressedSize As UInt32
	#tag EndComputedProperty


End Class
#tag EndClass
