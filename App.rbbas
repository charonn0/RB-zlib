#tag Class
Protected Class App
Inherits Application
	#tag Event
		Sub Open()
		  'Call TestZStreamWrite
		  If Not TestCompress() Then MsgBox("Compression failed")
		  If Not TestGZAppend() Then MsgBox("gzip append failed")
		  If Not TestGZWrite() Then MsgBox("gzip failed")
		  If Not TestGZRead() Then MsgBox("gunzip failed")
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Function TestCompress() As Boolean
		  Dim data As String
		  Dim rand As New Random
		  For i As Integer = 0 To 999
		    data = data + "Hello! "
		    If Rand.InRange(0, 5) = 5 Then data = data + Str(rand.InRange(0, 1000))
		  Next
		  Return _
		  (zlib.Uncompress(zlib.Compress(data, 9)) = data) And _
		  (zlib.Uncompress(zlib.Compress(data), data.LenB) = data) And _
		  (zlib.Uncompress(zlib.Compress(data, 9), data.LenB) = data)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function TestGZAppend() As Boolean
		  Dim dlg As New OpenDialog
		  dlg.Title = "Select a file to GZip"
		  Dim f As FolderItem = dlg.ShowModal
		  If f = Nil Then Return False
		  Dim bs As BinaryStream = BinaryStream.Open(f)
		  Dim g As FolderItem = f.Parent.Child(f.Name + ".gz")
		  Dim gz As zlib.GZStream = zlib.GZStream.Append(g)
		  While Not bs.EOF
		    gz.Write(bs.Read(1024))
		  Wend
		  gz.Close
		  Return True
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function TestGZRead() As Boolean
		  Dim dlg As New OpenDialog
		  dlg.Title = "Select a GZip file to read"
		  Dim f As FolderItem = dlg.ShowModal
		  If f = Nil Then Return False
		  Dim gz As zlib.GZStream = zlib.GZStream.Open(f)
		  Dim g As FolderItem = f.Parent.Child(f.Name + "_uncompressed")
		  Dim bs As BinaryStream = BinaryStream.Create(g, True)
		  While Not gz.EOF
		    bs.Write(gz.Read(1024))
		  Wend
		  bs.Close
		  gz.Close
		  Return True
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function TestGZWrite() As Boolean
		  Dim dlg As New OpenDialog
		  dlg.Title = "Select a file to GZip"
		  Dim f As FolderItem = dlg.ShowModal
		  If f = Nil Then Return False
		  Dim bs As BinaryStream = BinaryStream.Open(f)
		  Dim gz As zlib.GZStream = zlib.GZStream.Create(f.Parent.Child(f.Name + ".gz"), 99)
		  gz.Level = 9
		  gz.Strategy = 3
		  While Not bs.EOF
		    gz.Write(bs.Read(1024))
		  Wend
		  bs.Close
		  gz.Close
		  Return True
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function TestZStreamWrite() As Boolean
		  Dim data As New MemoryBlock(0)
		  Dim dstream As New BinaryStream(data)
		  'For i As Integer = 0 To 99
		  'dstream.Write("Hello! ")
		  'Next
		  'dstream.Close
		  'dstream = New BinaryStream(data)
		  Dim zipstream As zlib.ZStream = zlib.ZStream.Create(dstream)
		  For i As Integer = 0 To 99
		    zipstream.Write("Hello! ")
		  Next
		  zipstream.Flush
		  zipstream.Close
		  dstream.Close
		  Break
		End Function
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
