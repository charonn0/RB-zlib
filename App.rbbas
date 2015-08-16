#tag Class
Protected Class App
Inherits Application
	#tag Event
		Sub Open()
		  Dim data1 As String
		  Dim d As New MemoryBlock(0)
		  Dim bs As New BinaryStream(d)
		  For i As Integer = 0 To 99
		    bs.Write(zlib.Compress("Hello! "))
		  Next
		  bs.Close
		  'Dim comp1 As String = zlib.Compress(data1, 90)
		  'Dim decom1 As String = zlib.Uncompress(comp1, data1.LenB)
		  Dim decom2 As String = zlib.Uncompress(d)
		  Break
		End Sub
	#tag EndEvent


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
