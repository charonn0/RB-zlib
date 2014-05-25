#tag Class
Protected Class App
Inherits Application
	#tag Event
		Sub Open()
		  'If zlib.IsAvailable Then
		  'Dim s As String = "Hello, world! Hello, world! Hello, world! Hello, world! Hello, world! Hello, world! Hello, world!"
		  'Dim c As String = zlib.Compress(s)
		  'Dim d As String = zlib.Uncompress(c, s.LenB)
		  '
		  'Break
		  'Else
		  'Break
		  'End If
		  
		  'Dim f As FolderItem = GetOpenFolderItem("")
		  'Dim g As FolderItem = GetSaveFolderItem("", "")
		  'Dim z As zlibStream = zlibStream.Create(g)
		  'Dim bs As BinaryStream = BinaryStream.Open(f)
		  'While Not bs.EOF
		  'z.Write(bs.Read(32768))
		  'Wend
		  'z.Flush
		  ''z.Close
		  'Break
		  
		  Dim p, c, b As String
		  p = "hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!"
		  c = zlib.Compress(p)
		  b = zlib.Uncompress(c, p.LenB)
		  Break
		  
		  
		  'Dim f As FolderItem = GetOpenFolderItem("")
		  Dim g As FolderItem = GetSaveFolderItem("", "")
		  'Dim z As zlib.Compressor = zlib.Compressor.Create(g)
		  Dim bs As BinaryStream = BinaryStream.Create(g, True)
		  bs.WriteByte(&h1F) 'magic
		  bs.WriteByte(&h8B) 'magic
		  bs.WriteByte(&h08) 'use deflate
		  For i As Integer = 3 To 7
		    bs.WriteByte(&h0) 'Null
		  Next
		  bs.Write(c)
		  bs.Close
		  'While Not bs.EOF
		  'z.Write(bs.Read(1024))
		  'Wend
		  ''bs.Flush
		  'z.Close
		  'Break
		End Sub
	#tag EndEvent


	#tag Constant, Name = kEditClear, Type = String, Dynamic = False, Default = \"&Delete", Scope = Public
		#Tag Instance, Platform = Windows, Language = Default, Definition  = \"&Delete"
		#Tag Instance, Platform = Linux, Language = Default, Definition  = \"&Delete"
	#tag EndConstant

	#tag Constant, Name = kFileQuit, Type = String, Dynamic = False, Default = \"&Quit", Scope = Public
		#Tag Instance, Platform = Windows, Language = Default, Definition  = \"E&xit"
	#tag EndConstant

	#tag Constant, Name = kFileQuitShortcut, Type = String, Dynamic = False, Default = \"", Scope = Public
		#Tag Instance, Platform = Mac OS, Language = Default, Definition  = \"Cmd+Q"
		#Tag Instance, Platform = Linux, Language = Default, Definition  = \"Ctrl+Q"
	#tag EndConstant


	#tag ViewBehavior
	#tag EndViewBehavior
End Class
#tag EndClass
