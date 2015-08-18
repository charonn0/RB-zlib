#tag Class
Protected Class App
Inherits Application
	#tag Event
		Sub Open()
		  'If Not TestZStreamRead(TestZStreamWrite) Then MsgBox("ZStream failed")
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
		  Dim gz As zlib.GZStream = zlib.GZStream.Create(g, True)
		  While Not bs.EOF
		    gz.Write(bs.Read(1024))
		    If gz.LastError <> 0 Or gz.LastErrorMsg <> "" Then
		      Dim err As Integer = gz.LastError
		      Dim msg As String = gz.LastErrorMsg
		      Break
		    End If
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
		  dlg.Filter = FileTypes1.ApplicationXGzip
		  If f = Nil Then Return False
		  Dim gz As zlib.GZStream = zlib.GZStream.Open(f)
		  Dim g As FolderItem = f.Parent.Child(f.Name + "_uncompressed")
		  Dim bs As BinaryStream = BinaryStream.Create(g, True)
		  While Not gz.EOF
		    bs.Write(gz.Read(1024))
		    If gz.LastError <> 0 Or gz.LastErrorMsg <> "" Then
		      Dim err As Integer = gz.LastError
		      Dim msg As String = gz.LastErrorMsg
		      Break
		    End If
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
		  Dim g As FolderItem = f.Parent.Child(f.Name + ".gz")
		  Dim tmp As BinaryStream = BinaryStream.Create(g, True)
		  tmp.Close
		  Dim gz As zlib.GZStream = zlib.GZStream.Create(g)
		  gz.Level = 9
		  gz.Strategy = 3
		  While Not bs.EOF
		    gz.Write(bs.Read(1024))
		    If gz.LastError <> 0 Or gz.LastErrorMsg <> "" Then
		      Dim err As Integer = gz.LastError
		      Dim msg As String = gz.LastErrorMsg
		      Break
		    End If
		  Wend
		  bs.Close
		  gz.Close
		  Return True
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function TestZStreamRead(Deflated As MemoryBlock) As Boolean
		  Dim dstream As New BinaryStream(Deflated)
		  Dim zipstream As zlib.ZStream = zlib.ZStream.Open(dstream)
		  Dim out As New MemoryBlock(0)
		  Dim outs As New BinaryStream(out)
		  While not zipstream.EOF
		    outs.Write(zipstream.Read(2048))
		  Wend
		  zipstream.Close
		  dstream.Close
		  outs.Close
		  Break
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function TestZStreamWrite() As MemoryBlock
		  Dim data As New MemoryBlock(0)
		  Dim dstream As New BinaryStream(data)
		  Dim zipstream As zlib.ZStream = zlib.ZStream.Create(dstream)
		  For i As Integer = 0 To 99
		    zipstream.Write("Hello! ")
		  Next
		  zipstream.Close
		  dstream.Close
		  Return data
		End Function
	#tag EndMethod


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
