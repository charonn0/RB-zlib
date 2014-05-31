#tag Class
Protected Class GZStream
Implements Readable, Writeable
	#tag Method, Flags = &h0
		 Shared Function Append(GzipFile As FolderItem, AllowSeek As Boolean = False) As zlib.GZStream
		  ' Opens an existing gzip stream
		  If GzipFile = Nil Or GzipFile.Directory Then Raise New IOException
		  If AllowSeek Then
		    Return gzOpen(GzipFile, "a+")
		  Else
		    Return gzOpen(GzipFile, "a")
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Close()
		  Call zlib.gzclose(gzFile)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(gzOpaque As Ptr)
		  gzFile = gzOpaque
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Create(OutputFile As FolderItem, OverWrite As Boolean = False) As zlib.GZStream
		  ' Creates an empty gzip stream
		  If OutputFile = Nil Or OutputFile.Directory Then Raise New IOException
		  Dim mode As String
		  Select Case True
		  Case OutputFile.Exists And OverWrite, Not OutputFile.Exists
		    mode = "w+"
		  Else
		    Raise New IOException
		  End Select
		  Return gzOpen(OutputFile, mode)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EOF() As Boolean
		  // Part of the Readable interface.
		  Return zlib.gzeof(gzFile)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Flush()
		  // Part of the Writeable interface.
		  If zlib.gzflush(gzFile, Z_FINISH) <> Z_OK Then
		    Raise New RuntimeException
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function gzError(ByRef Msg As String) As Integer
		  Dim num As Integer
		  Dim p As Ptr = zlib.gzerror(gzFile, num)
		  If p <> Nil Then
		    Dim mb As MemoryBlock = p
		    Msg = mb.CString(0)
		    Return num
		  End If
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Shared Function gzOpen(GzipFile As FolderItem, Mode As String) As zlib.GZStream
		  Dim strm As Ptr = zlib.gzOpen(GzipFile.AbsolutePath, mode)
		  If strm <> Nil Then
		    Return New zlib.GZStream(strm)
		  Else
		    Raise New RuntimeException
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(GzipFile As FolderItem, ReadWrite As Boolean) As zlib.GZStream
		  ' Opens an existing gzip stream
		  If GzipFile = Nil Or GzipFile.Directory Or Not GzipFile.Exists Then Raise New IOException
		  Dim mode As String
		  If ReadWrite Then
		    mode = "r+"
		  Else
		    mode = "r"
		  End If
		  Return gzOpen(GzipFile, mode)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  // Part of the Readable interface.
		  Dim mb As New MemoryBlock(Count)
		  Dim red As Integer = zlib.gzread(gzFile, mb, mb.Size)
		  If red > 0 Then
		    Return DefineEncoding(mb.StringValue(0, mb.Size), encoding)
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadError() As Boolean
		  // Part of the Readable interface.
		  Dim msg As String
		  Return gzError(msg) <> 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(text As String)
		  // Part of the Writeable interface.
		  Dim mb As MemoryBlock = text
		  If zlib.gzwrite(gzFile, mb, text.LenB) <> text.LenB Then
		    Raise New IOException
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function WriteError() As Boolean
		  // Part of the Writeable interface.
		  Dim msg As String
		  Return gzError(msg) <> 0
		End Function
	#tag EndMethod


	#tag Property, Flags = &h1
		Protected gzFile As Ptr
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
