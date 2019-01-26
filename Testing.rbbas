#tag Module
Protected Module Testing
	#tag Method, Flags = &h1
		Protected Sub RunTests()
		  If Not TestTar() Then MsgBox("Tar failed")
		  If Not TestUntar() Then MsgBox("Untar failed")
		  If Not TestZStream() Then MsgBox("ZStream failed")
		  If Not TestZWrite() Then MsgBox("Z write failed")
		  If Not TestZRead() Then MsgBox("Z read failed")
		  If Not TestDeflate() Then MsgBox("Deflate read failed")
		  If Not TestUnzip() Then MsgBox("Zip read failed")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function TestDeflate() As Boolean
		  Dim dlg As New OpenDialog
		  dlg.Title = CurrentMethodName + " - Select a file to deflate"
		  Dim f As FolderItem = dlg.ShowModal
		  If f = Nil Then Return False
		  Dim g As FolderItem = f.Parent.Child(f.Name + ".gz")
		  
		  If Not zlib.Deflate(f, g) Then
		    If g.Exists Then g.Delete
		    Return False
		  End If
		  
		  Dim output As New MemoryBlock(0)
		  Dim oustrt As New BinaryStream(output)
		  Dim bs As BinaryStream = BinaryStream.Open(f)
		  If Not zlib.Deflate(bs, oustrt) Then Return False
		  bs.Close
		  oustrt.Close
		  
		  Dim inf As MemoryBlock = zlib.Inflate(output)
		  Dim def As String = zlib.Deflate(inf)
		  Return def = output
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function TestTar() As Boolean
		  Dim sdlg As New SaveAsDialog
		  sdlg.Title = CurrentMethodName + " - Create TAR file"
		  sdlg.Filter = FileTypes1.ApplicationXTar
		  sdlg.SuggestedFileName = "TestArchive"
		  Dim f As FolderItem = sdlg.ShowModal
		  If f = Nil Then Return False
		  Dim tar As New USTAR.TarWriter
		  Dim odlg As New OpenDialog
		  odlg.Title = CurrentMethodName + " - Add files to TAR"
		  odlg.MultiSelect = True
		  If odlg.ShowModal = Nil Then Return False
		  For i As Integer = 0 To odlg.Count - 1
		    Call tar.AppendEntry(odlg.Item(i))
		  Next
		  tar.Commit(f)
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function TestUntar() As Boolean
		  Dim odlg As New OpenDialog
		  odlg.Title = CurrentMethodName + " - Open TAR file for extraction"
		  odlg.Filter = FileTypes1.ApplicationXTar
		  
		  Dim tarf As FolderItem = odlg.ShowModal
		  If tarf = Nil Then Return False
		  
		  Dim sfdlg As New SelectFolderDialog
		  sfdlg.Title = CurrentMethodName + " - Choose folder to extract into"
		  Dim target As FolderItem = sfdlg.ShowModal
		  If target = Nil Then Return False
		  Dim result() As FolderItem = USTAR.ReadTar(tarf, target)
		  Return result.Ubound > -1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function TestUnzip() As Boolean
		  Dim odlg As New OpenDialog
		  odlg.Title = CurrentMethodName + " - Open ZIP file for extraction"
		  odlg.Filter = FileTypes1.ApplicationZip
		  
		  Dim zipf As FolderItem = odlg.ShowModal
		  If zipf = Nil Then Return False
		  
		  Dim sfdlg As New SelectFolderDialog
		  sfdlg.Title = CurrentMethodName + " - Choose folder to extract into"
		  Dim target As FolderItem = sfdlg.ShowModal
		  If target = Nil Then Return False
		  Dim out() As FolderItem = PKZip.ReadZip(zipf, target, True)
		  Return UBound(out) > -1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function TestZRead() As Boolean
		  Dim dlg As New OpenDialog
		  dlg.Title = CurrentMethodName + " - Select a Z-compressed file to read"
		  Dim f As FolderItem = dlg.ShowModal
		  dlg.Filter = FileTypes1.ApplicationXCompress
		  If f = Nil Then Return False
		  Dim g As FolderItem = f.Parent.Child(f.Name + "_uncompressed")
		  If Not zlib.Inflate(f, g) Then Return False
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function TestZStream() As Boolean
		  Dim cmp As New MemoryBlock(0)
		  Dim bs As New BinaryStream(cmp)
		  Dim z As zlib.ZStream = zlib.ZStream.Create(bs)
		  Dim src As String = "TestData123TestData123TestData123TestData123TestData123TestData123"
		  z.Write(src)
		  z.Close
		  bs.Close
		  If DecodeHex("789C0B492D2E71492C493434320E218F0900F29E1621") <> cmp Then Return False
		  bs = New BinaryStream(cmp)
		  z = z.Open(bs)
		  Dim decm As String
		  Do Until z.EOF
		    decm = decm + z.Read(64)
		  Loop
		  Return decm = src
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function TestZWrite() As Boolean
		  Dim dlg As New OpenDialog
		  dlg.Title = CurrentMethodName + " - Select a file to Z-compress"
		  Dim f As FolderItem = dlg.ShowModal
		  If f = Nil Then Return False
		  Dim g As FolderItem = f.Parent.Child(f.Name + ".z")
		  If Not zlib.Deflate(f, g, 9) Then Return False
		  Return True
		End Function
	#tag EndMethod


End Module
#tag EndModule
