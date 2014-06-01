#tag Class
Protected Class App
Inherits Application
	#tag Event
		Sub Open()
		  TestCompressMem()
		  'TestCompress()
		  'TestDecompress()
		  Break
		  
		  
		  ''If zlib.IsAvailable Then
		  ''Dim s As String = "Hello, world! Hello, world! Hello, world! Hello, world! Hello, world! Hello, world! Hello, world!"
		  ''Dim c As String = zlib.Compress(s)
		  ''Dim d As String = zlib.Uncompress(c, s.LenB)
		  ''
		  ''Break
		  ''Else
		  ''Break
		  ''End If
		  '
		  ''Dim f As FolderItem = GetOpenFolderItem("")
		  ''Dim g As FolderItem = GetSaveFolderItem("", "")
		  ''Dim z As zlibStream = zlibStream.Create(g)
		  ''Dim bs As BinaryStream = BinaryStream.Open(f)
		  ''While Not bs.EOF
		  ''z.Write(bs.Read(32768))
		  ''Wend
		  ''z.Flush
		  '''z.Close
		  ''Break
		  '
		  'Dim p, c, b As String
		  'p = BlankErrorPage
		  ''"hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!hello, world!"
		  'c = zlib.Compress(p, 9)
		  'b = zlib.Uncompress(c, p.LenB)
		  'Break
		  '
		  '
		  ''Dim f As FolderItem = GetOpenFolderItem("")
		  'Dim g As FolderItem = GetSaveFolderItem("", "")
		  ''Dim z As zlib.Compressor = zlib.Compressor.Create(g)
		  'Dim bs As BinaryStream = BinaryStream.Create(g, True)
		  'bs.WriteByte(&h1F) 'magic
		  'bs.WriteByte(&h8B) 'magic
		  'bs.WriteByte(&h08) 'use deflate
		  'For i As Integer = 3 To 7
		  'bs.WriteByte(&h0) 'Null
		  'Next
		  'bs.Write(c)
		  'bs.Close
		  ''While Not bs.EOF
		  ''z.Write(bs.Read(1024))
		  ''Wend
		  '''bs.Flush
		  ''z.Close
		  ''Break
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h1
		Protected Sub TestCompress()
		  Dim saveto As FolderItem = GetSaveFolderItem("", "")
		  Dim readfrom As FolderItem = GetOpenFolderItem("")
		  Dim stream As zlib.GZStream = zlib.GZStream.Append(saveto)
		  Dim bs As BinaryStream = BinaryStream.Open(readfrom)
		  While Not bs.EOF
		    stream.Write(bs.Read(256))
		  Wend
		  stream.Flush
		  MsgBox(stream.LastErrorMessage)
		  stream.Close
		  bs.Close
		  Break
		  Quit
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub TestCompressMem()
		  Dim mb As New MemoryBlock(4096)
		  Dim stream As New zlib.GZStream(mb)
		  For i As Integer = 0 To 4096 Step 64
		    stream.Write("HelloHelloHelloHelloHelloHelloHelloHelloHelloHelloHelloHello1111")
		  Next
		  stream.Flush
		  stream.Close
		  Break
		  Quit
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub TestDecompress()
		  Dim saveto As FolderItem = GetSaveFolderItem("", "")
		  Dim readfrom As FolderItem = GetOpenFolderItem("")
		  Dim bs As zlib.GZStream = zlib.GZStream.Open(readfrom, False)
		  Dim stream As BinaryStream = BinaryStream.Create(saveto, True)
		  While Not bs.EOF
		    stream.Write(bs.Read(1))
		  Wend
		  MsgBox(bs.LastErrorMessage)
		  stream.Close
		  bs.Close
		  Break
		  Quit
		End Sub
	#tag EndMethod


	#tag Constant, Name = BlankErrorPage, Type = String, Dynamic = False, Default = \"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\r<html xmlns\x3D\"http://www.w3.org/1999/xhtml\">\r<head>\r<meta http-equiv\x3D\"Content-Type\" content\x3D\"text/html; charset\x3Diso-8859-1\" />\r<title>%HTTPERROR%</title>\r<style type\x3D\"text/css\">\r<!--\rbody\x2Ctd\x2Cth {\r\tfont-family: Arial\x2C Helvetica\x2C sans-serif;\r\tfont-size: medium;\r}\ra:link {\r\tcolor: #0000FF;\r\ttext-decoration: none;\r}\ra:visited {\r\ttext-decoration: none;\r\tcolor: #990000;\r}\ra:hover {\r\ttext-decoration: underline;\r\tcolor: #009966;\r}\ra:active {\r\ttext-decoration: none;\r\tcolor: #FF0000;\r}\r-->\r</style></head>\r\r<body>\r<h1>%HTTPERROR%</h1>\r<p>%DOCUMENT%</p>\r<hr />\r<p>%SIGNATURE%</p>\r</body>\r</html>", Scope = Protected
	#tag EndConstant

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
