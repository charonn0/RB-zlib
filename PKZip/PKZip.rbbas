#tag Module
Protected Module PKZip
	#tag Method, Flags = &h21
		Private Sub CollapseTree(Root As Dictionary, ByRef Paths() As String, ByRef Lengths() As UInt32, ByRef ModTimes() As Date, ByRef Sources() As Readable, ByRef Comments() As String, ByRef Extras() As MemoryBlock, ByRef DirectoryStatus() As Boolean, ByRef Levels() As UInt32, ByRef Methods() As UInt32)
		  For Each key As Variant In Root.Keys
		    If Root.Value(key) IsA Dictionary Then
		      Dim item As Dictionary = Root.Value(key)
		      If item.Lookup("$d", False) Then CollapseTree(item, Paths, Lengths, ModTimes, Sources, Comments, Extras, DirectoryStatus, Levels, Methods)
		      Paths.Append(GetTreeParentPath(item))
		      Lengths.Append(item.Lookup("$s", 0))
		      ModTimes.Append(item.Value("$t"))
		      Sources.Append(item.Value("$r"))
		      DirectoryStatus.Append(item.Value("$d"))
		      Extras.Append(item.Lookup("$e", Nil))
		      Comments.Append(item.Lookup("$c", ""))
		      Levels.Append(item.Lookup("$l", 6))
		      If USE_ZLIB Then
		        Methods.Append(item.Lookup("$m", METHOD_DEFLATED))
		      Else
		        Methods.Append(item.Lookup("$m", 0))
		      End If
		    End If
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ConvertDate(NewDate As Date) As Pair
		  ' Convert the passed Date object into MS-DOS style datestamp and timestamp (16 bits each)
		  ' The DOS format has a resolution of two seconds, no concept of time zones, and is valid
		  ' for dates between 1/1/1980 and 12/31/2107
		  
		  Dim h, m, s, dom, mon, year As UInt32
		  Dim dt, tm As UInt16
		  h = NewDate.Hour
		  m = NewDate.Minute
		  s = NewDate.Second
		  dom = NewDate.Day
		  mon = NewDate.Month
		  year = NewDate.Year - 1980
		  
		  If year > 127 Then Raise New OutOfBoundsException
		  
		  dt = dom
		  dt = dt Or ShiftLeft(mon, 5)
		  dt = dt Or ShiftLeft(year, 9)
		  
		  tm = s \ 2
		  tm = tm Or ShiftLeft(m, 5)
		  tm = tm Or ShiftLeft(h, 11)
		  
		  Return dt:tm
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ConvertDate(Dt As UInt16, tm As UInt16) As Date
		  ' Convert the passed MS-DOS style date and time into a Date object.
		  ' The DOS format has a resolution of two seconds, no concept of time zones,
		  ' and is valid for dates between 1/1/1980 and 12/31/2107
		  
		  Dim h, m, s, dom, mon, year As Integer
		  h = ShiftRight(tm, 11)
		  m = ShiftRight(tm, 5) And &h3F
		  s = (tm And &h1F) * 2
		  dom = dt And &h1F
		  mon = ShiftRight(dt, 5) And &h0F
		  year = (ShiftRight(dt, 9) And &h7F) + 1980
		  
		  Return New Date(year, mon, dom, h, m, s)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function CRC32(Data As MemoryBlock, LastCRC As UInt32 = 0, DataSize As Integer = -1) As UInt32
		  #If USE_ZLIB Then
		    Return zlib.CRC32(Data, LastCRC, DataSize)
		  #Else
		    ' Calculate the CRC32 checksum for the Data. Pass back the returned value
		    ' to continue processing.
		    '    Dim crc As UInt32
		    '    Do
		    '      crc = CRC32(NextData, crc)
		    '    Loop
		    ' If Data.Size is not known (-1) then specify the size as DataSize
		    If DataSize = -1 Then DataSize = Data.Size
		    If DataSize = -1 Then Raise New ZipException(ERR_SIZE_REQUIRED)
		    
		    Static CRCTable(255) As UInt32 = Array( _
		    &h00000000,&h77073096,&hEE0E612C,&h990951BA,&h076DC419,&h706AF48F,&hE963A535,&h9E6495A3, _
		    &h0EDB8832,&h79DCB8A4,&hE0D5E91E,&h97D2D988,&h09B64C2B,&h7EB17CBD,&hE7B82D07,&h90BF1D91, _
		    &h1DB71064,&h6AB020F2,&hF3B97148,&h84BE41DE,&h1ADAD47D,&h6DDDE4EB,&hF4D4B551,&h83D385C7, _
		    &h136C9856,&h646BA8C0,&hFD62F97A,&h8A65C9EC,&h14015C4F,&h63066CD9,&hFA0F3D63,&h8D080DF5, _
		    &h3B6E20C8,&h4C69105E,&hD56041E4,&hA2677172,&h3C03E4D1,&h4B04D447,&hD20D85FD,&hA50AB56B, _
		    &h35B5A8FA,&h42B2986C,&hDBBBC9D6,&hACBCF940,&h32D86CE3,&h45DF5C75,&hDCD60DCF,&hABD13D59, _
		    &h26D930AC,&h51DE003A,&hC8D75180,&hBFD06116,&h21B4F4B5,&h56B3C423,&hCFBA9599,&hB8BDA50F, _
		    &h2802B89E,&h5F058808,&hC60CD9B2,&hB10BE924,&h2F6F7C87,&h58684C11,&hC1611DAB,&hB6662D3D, _
		    &h76DC4190,&h01DB7106,&h98D220BC,&hEFD5102A,&h71B18589,&h06B6B51F,&h9FBFE4A5,&hE8B8D433, _
		    &h7807C9A2,&h0F00F934,&h9609A88E,&hE10E9818,&h7F6A0DBB,&h086D3D2D,&h91646C97,&hE6635C01, _
		    &h6B6B51F4,&h1C6C6162,&h856530D8,&hF262004E,&h6C0695ED,&h1B01A57B,&h8208F4C1,&hF50FC457, _
		    &h65B0D9C6,&h12B7E950,&h8BBEB8EA,&hFCB9887C,&h62DD1DDF,&h15DA2D49,&h8CD37CF3,&hFBD44C65, _
		    &h4DB26158,&h3AB551CE,&hA3BC0074,&hD4BB30E2,&h4ADFA541,&h3DD895D7,&hA4D1C46D,&hD3D6F4FB, _
		    &h4369E96A,&h346ED9FC,&hAD678846,&hDA60B8D0,&h44042D73,&h33031DE5,&hAA0A4C5F,&hDD0D7CC9, _
		    &h5005713C,&h270241AA,&hBE0B1010,&hC90C2086,&h5768B525,&h206F85B3,&hB966D409,&hCE61E49F, _
		    &h5EDEF90E,&h29D9C998,&hB0D09822,&hC7D7A8B4,&h59B33D17,&h2EB40D81,&hB7BD5C3B,&hC0BA6CAD, _
		    &hEDB88320,&h9ABFB3B6,&h03B6E20C,&h74B1D29A,&hEAD54739,&h9DD277AF,&h04DB2615,&h73DC1683, _
		    &hE3630B12,&h94643B84,&h0D6D6A3E,&h7A6A5AA8,&hE40ECF0B,&h9309FF9D,&h0A00AE27,&h7D079EB1, _
		    &hF00F9344,&h8708A3D2,&h1E01F268,&h6906C2FE,&hF762575D,&h806567CB,&h196C3671,&h6E6B06E7, _
		    &hFED41B76,&h89D32BE0,&h10DA7A5A,&h67DD4ACC,&hF9B9DF6F,&h8EBEEFF9,&h17B7BE43,&h60B08ED5, _
		    &hD6D6A3E8,&hA1D1937E,&h38D8C2C4,&h4FDFF252,&hD1BB67F1,&hA6BC5767,&h3FB506DD,&h48B2364B, _
		    &hD80D2BDA,&hAF0A1B4C,&h36034AF6,&h41047A60,&hDF60EFC3,&hA867DF55,&h316E8EEF,&h4669BE79, _
		    &hCB61B38C,&hBC66831A,&h256FD2A0,&h5268E236,&hCC0C7795,&hBB0B4703,&h220216B9,&h5505262F, _
		    &hC5BA3BBE,&hB2BD0B28,&h2BB45A92,&h5CB36A04,&hC2D7FFA7,&hB5D0CF31,&h2CD99E8B,&h5BDEAE1D, _
		    &h9B64C2B0,&hEC63F226,&h756AA39C,&h026D930A,&h9C0906A9,&hEB0E363F,&h72076785,&h05005713, _
		    &h95BF4A82,&hE2B87A14,&h7BB12BAE,&h0CB61B38,&h92D28E9B,&hE5D5BE0D,&h7CDCEFB7,&h0BDBDF21, _
		    &h86D3D2D4,&hF1D4E242,&h68DDB3F8,&h1FDA836E,&h81BE16CD,&hF6B9265B,&h6FB077E1,&h18B74777, _
		    &h88085AE6,&hFF0F6A70,&h66063BCA,&h11010B5C,&h8F659EFF,&hF862AE69,&h616BFFD3,&h166CCF45, _
		    &hA00AE278,&hD70DD2EE,&h4E048354,&h3903B3C2,&hA7672661,&hD06016F7,&h4969474D,&h3E6E77DB, _
		    &hAED16A4A,&hD9D65ADC,&h40DF0B66,&h37D83BF0,&hA9BCAE53,&hDEBB9EC5,&h47B2CF7F,&h30B5FFE9, _
		    &hBDBDF21C,&hCABAC28A,&h53B39330,&h24B4A3A6,&hBAD03605,&hCDD70693,&h54DE5729,&h23D967BF, _
		    &hB3667A2E,&hC4614AB8,&h5D681B02,&h2A6F2B94,&hB40BBE37,&hC30C8EA1,&h5A05DF1B,&h2D02EF8D)
		    
		    LastCRC = LastCRC XOr &hFFFFFFFF
		    For i As Integer = 0 To Data.Size - 1
		      Dim tmp As UInt32 = LastCRC / 256
		      LastCRC = (tmp And &hFFFFFFFF) XOr CRCTable((LastCRC XOr Data.UInt8Value(i)) And &hFF)
		    Next i
		    Return LastCRC XOr &hFFFFFFFF
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function CreateTree(Root As FolderItem, Path As String) As FolderItem
		  ' Returns a FolderItem corresponding to Root+Path, creating subdirectories as needed
		  
		  If Root = Nil Or Not Root.Directory Then Return Nil
		  Dim s() As String = Split(Path, "/")
		  Dim bound As Integer = UBound(s)
		  
		  For i As Integer = 0 To bound - 1
		    Dim name As String = NormalizeFilename(s(i))
		    If name = "" Then Continue
		    root = root.TrueChild(name)
		    If Root.Exists Then
		      If Not Root.Directory Then
		        Dim err As New IOException
		        err.Message = "'" + name + "' is not a directory!"
		        Raise err
		      End If
		    Else
		      root.CreateAsFolder
		    End If
		  Next
		  
		  Dim name As String = NormalizeFilename(s(bound))
		  If name <> "" Then Root = Root.Child(name)
		  
		  Return Root
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub GetChildren(Root As FolderItem, ByRef Results() As FolderItem)
		  Dim c As Integer = Root.Count
		  For i As Integer = 1 To c
		    Dim item As FolderItem = Root.TrueItem(i)
		    Results.Append(item)
		    If item.Directory Then GetChildren(item, Results)
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function GetCompressor(Method As UInt32, Stream As Writeable, CompressionLevel As UInt32) As Writeable
		  If Method = 0 Then Return Stream
		  Select Case Method
		  Case METHOD_DEFLATED
		    #If USE_ZLIB Then
		      Return zlib.ZStream.Create(Stream, CompressionLevel, zlib.Z_DEFAULT_STRATEGY, zlib.RAW_ENCODING)
		    #endif
		    
		  Case METHOD_BZIP2
		    #If USE_BZIP2 Then
		      Return BZip2.BZ2Stream.Create(Stream, CompressionLevel)
		    #endif
		  End Select
		  
		  Return Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function GetDecompressor(Method As UInt32, Stream As Readable) As Readable
		  Select Case Method
		  Case 0 ' store
		    Return Stream
		    
		  Case METHOD_DEFLATED
		    #If USE_ZLIB Then
		      Dim z As zlib.ZStream = zlib.ZStream.Open(Stream, zlib.RAW_ENCODING)
		      z.BufferedReading = False
		      Return z
		    #endif
		    
		  Case METHOD_BZIP2
		    #If USE_BZIP2 Then
		      Dim z As BZip2.BZ2Stream = BZip2.BZ2Stream.Open(Stream)
		      Return z
		    #endif
		  End Select
		  
		  Return Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function GetRelativePath(Root As FolderItem, Item As FolderItem) As String
		  If Root = Nil Then Return Item.Name
		  Dim s() As String
		  Do Until Item.AbsolutePath = Root.AbsolutePath
		    s.Insert(0, Item.Name)
		    Item = Item.Parent
		  Loop Until Item = Nil
		  If Item = Nil Then Return s.Pop ' not relative
		  Return Join(s, "/")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function GetTreeParentPath(Child As Dictionary) As String
		  Dim s() As String
		  If Child.Value("$d") = True Then 
		    s.Append("")
		  End If
		  Do Until Child = Nil Or Child.Value("$n") = "$ROOT"
		    s.Insert(0, Child.Value("$n"))
		    Dim w As WeakRef = Child.Value("$p")
		    If w = Nil Or w.Value = Nil Then
		      Child = Nil
		    Else
		      Child = Dictionary(w.Value)
		    End If
		  Loop
		  
		  Return Join(s, "/")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ListZip(ZipFile As FolderItem) As String()
		  ' Returns a list of file names (with paths relative to the zip root) but does not extract anything.
		  
		  Dim zip As New ZipReader(ZipFile)
		  Dim ret() As String
		  
		  Do Until zip.LastError <> 0
		    ret.Append(zip.CurrentName)
		    Call zip.MoveNext(Nil)
		  Loop
		  zip.Close
		  Return ret
		  
		Exception
		  Return ret
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function NormalizeFilename(Name As String) As String
		  ' This method takes a file name from an archive and transforms it (if necessary) to abide by
		  ' the rules of the target system.
		  
		  #If TargetWin32 Then
		    Static reservednames() As String = Array("con", "prn", "aux", "nul", "com1", "com2", "com3", "com4", "com5", "com6", "com7", "com8", "com9", _
		    "lpt1", "lpt2", "lpt3", "lpt4", "lpt5", "lpt6", "lpt7", "lpt8", "lpt9")
		    Static reservedchars() As String = Array("<", ">", ":", """", "/", "\", "|", "?", "*")
		  #ElseIf TargetLinux Then
		    Static reservednames() As String = Array(".", "..")
		    Static reservedchars() As String = Array("/", Chr(0))
		  #ElseIf TargetMacOS Then
		    Static reservednames() As String ' none
		    Static reservedchars() As String = Array(":", Chr(0))
		  #endif
		  
		  For Each char As String In Name.Split("")
		    If reservedchars.IndexOf(char) > -1 Then name = ReplaceAll(name, char, "_")
		  Next
		  
		  If reservednames.IndexOf(name) > -1 Then name = "_" + name
		  #If TargetWin32 Then
		    ' Windows doesn't like it even if the reserved name is used with an extension, e.g. 'aux.c' is illegal.
		    If reservednames.IndexOf(NthField(name, ".", 1)) > -1 Then name = "_" + name
		  #endif
		  
		  Return name
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ReadZip(ZipFile As FolderItem, ExtractTo As FolderItem, Overwrite As Boolean = False, VerifyCRC As Boolean = True) As FolderItem()
		  ' Extracts a ZIP file to the ExtractTo directory
		  
		  Dim zip As New ZipReader(BinaryStream.Open(ZipFile))
		  zip.ValidateChecksums = VerifyCRC
		  Dim ret() As FolderItem
		  If Not ExtractTo.Exists Then ExtractTo.CreateAsFolder()
		  
		  Do Until zip.LastError <> 0
		    Dim f As FolderItem = CreateTree(ExtractTo, zip.CurrentName)
		    If f = Nil Then Raise New ZipException(ERR_INVALID_NAME)
		    Dim outstream As BinaryStream
		    If Not f.Directory Then outstream = BinaryStream.Create(f, Overwrite)
		    Call zip.MoveNext(outstream)
		    If outstream <> Nil Then outstream.Close
		    ret.Append(f)
		  Loop
		  If zip.LastError <> ERR_END_ARCHIVE Then Raise New ZipException(zip.LastError)
		  zip.Close
		  Return ret
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function RepairZip(ZipFile As FolderItem, RecoveryFile As FolderItem, Optional LogFile As FolderItem) As Boolean
		  Return ZipReader.RepairZip(ZipFile, RecoveryFile, LogFile)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SeekSignature(Stream As BinaryStream, Signature As UInt32) As Boolean
		  Dim pos As UInt64 = Stream.Position
		  Dim ok As Boolean
		  Dim sig As New MemoryBlock(4)
		  sig.LittleEndian = True
		  sig.UInt32Value(0) = Signature
		  
		  Do Until Stream.EOF
		    Dim data As String = Stream.Read(CHUNK_SIZE)
		    Dim offset As Integer = InStrB(data, sig)
		    If offset > 0 Then
		      Stream.Position = Stream.Position - (data.LenB - offset + 1)
		      ok = True
		      Exit Do
		    ElseIf Stream.Length - Stream.Position >= 4 Then
		      Stream.Position = Stream.Position - 3
		    End If
		  Loop
		  If Not ok Then Stream.Position = pos
		  Return ok
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function TestZip(ZipFile As FolderItem) As Boolean
		  ' Tests a ZIP file 
		  
		  Dim zip As ZipReader
		  Try
		    zip = New ZipReader(BinaryStream.Open(ZipFile))
		  Catch Err As ZipException
		    Return False
		  End Try
		  zip.ValidateChecksums = True
		  Do Until zip.LastError <> 0
		    Dim tmp As New MemoryBlock(0)
		    Dim nullstream As New BinaryStream(tmp)
		    nullstream.Close
		    Call zip.MoveNext(nullstream)
		  Loop
		  zip.Close
		  If zip.LastError <> ERR_END_ARCHIVE Then Return False
		  Return True
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function TraverseTree(Root As Dictionary, Path As String, CreateChildren As Boolean) As Dictionary
		  Dim s() As String = Split(Path, "/")
		  Dim bound As Integer = UBound(s)
		  Dim parent As Dictionary = Root
		  For i As Integer = 0 To bound - 1
		    Dim name As String = NormalizeFilename(s(i))
		    If name = "" Then Continue
		    Dim child As Dictionary = parent.Lookup(name, Nil)
		    If child = Nil Then
		      If Not CreateChildren Then Return Nil
		      child = New Dictionary
		      child.Value("$n") = name
		      child.Value("$d") = True
		      child.Value("$p") = New WeakRef(parent)
		      child.Value("$t") = New Date
		      child.Value("$r") = Nil
		    Else
		      child.Value("$d") = True
		    End If
		    parent.Value(name) = child
		    parent = child
		  Next
		  
		  Dim name As String = NormalizeFilename(s(bound))
		  If name <> "" Then 
		    Dim child As Dictionary = parent.Lookup(name, Nil)
		    If child = Nil Then
		      If Not CreateChildren Then Return Nil
		      child = New Dictionary("$n":name, "$d":false, "$p":New WeakRef(parent), "$t":New Date, "$r":Nil)
		    End If
		    parent.Value(name) = child
		    parent = child
		  End If
		  Return parent
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function WriteZip(ToArchive() As FolderItem, OutputFile As FolderItem, RelativeRoot As FolderItem, Overwrite As Boolean = False, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, CompressionMethod As UInt32 = PKZip.METHOD_DEFLATED) As Boolean
		  Dim writer As New ZipWriter
		  writer.CompressionLevel = CompressionLevel
		  writer.CompressionMethod = CompressionMethod
		  Dim c As Integer = UBound(ToArchive)
		  For i As Integer = 0 To c
		    Call writer.AppendEntry(ToArchive(i), RelativeRoot)
		  Next
		  writer.Commit(OutputFile, Overwrite)
		  Return writer.LastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function WriteZip(ToArchive As FolderItem, OutputFile As FolderItem, Overwrite As Boolean = False, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, CompressionMethod As UInt32 = PKZip.METHOD_DEFLATED) As Boolean
		  Dim items() As FolderItem
		  If ToArchive.Directory Then
		    GetChildren(ToArchive, items)
		  Else
		    items.Append(ToArchive)
		  End If
		  Return WriteZip(items, OutputFile, ToArchive, Overwrite, CompressionLevel, CompressionMethod)
		End Function
	#tag EndMethod


	#tag Note, Name = Copying
		RB-PKZip (https://github.com/charonn0/RB-zlib)
		
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


	#tag Constant, Name = CHUNK_SIZE, Type = Double, Dynamic = False, Default = \"16384", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ERR_CHECKSUM_MISMATCH, Type = Double, Dynamic = False, Default = \"-204", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_END_ARCHIVE, Type = Double, Dynamic = False, Default = \"-202", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_INVALID_ENTRY, Type = Double, Dynamic = False, Default = \"-201", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_INVALID_NAME, Type = Double, Dynamic = False, Default = \"-205", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_NOT_ZIPPED, Type = Double, Dynamic = False, Default = \"-200", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_SIZE_REQUIRED, Type = Double, Dynamic = False, Default = \"-207", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_TOO_LARGE, Type = Double, Dynamic = False, Default = \"-206", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = ERR_UNSUPPORTED_COMPRESSION, Type = Double, Dynamic = False, Default = \"-203", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = FLAG_DESCRIPTOR, Type = Double, Dynamic = False, Default = \"8", Scope = Private
	#tag EndConstant

	#tag Constant, Name = FLAG_ENCRYPTED, Type = Double, Dynamic = False, Default = \"1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = FLAG_NAME_ENCODING, Type = Double, Dynamic = False, Default = \"2048", Scope = Private
	#tag EndConstant

	#tag Constant, Name = MAX_COMMENT_SIZE, Type = Double, Dynamic = False, Default = \"&hFFFF", Scope = Private
	#tag EndConstant

	#tag Constant, Name = MAX_EXTRA_SIZE, Type = Double, Dynamic = False, Default = \"&hFFFF", Scope = Private
	#tag EndConstant

	#tag Constant, Name = MAX_NAME_SIZE, Type = Double, Dynamic = False, Default = \"&hFFFF", Scope = Private
	#tag EndConstant

	#tag Constant, Name = METHOD_BZIP2, Type = Double, Dynamic = False, Default = \"12", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = METHOD_DEFLATED, Type = Double, Dynamic = False, Default = \"8", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = MIN_ARCHIVE_SIZE, Type = Double, Dynamic = False, Default = \"ZIP_DIRECTORY_FOOTER_SIZE\r", Scope = Private
	#tag EndConstant

	#tag Constant, Name = USE_BZIP2, Type = Boolean, Dynamic = False, Default = \"True", Scope = Private
	#tag EndConstant

	#tag Constant, Name = USE_ZLIB, Type = Boolean, Dynamic = False, Default = \"True", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ZIP_DIRECTORY_FOOTER_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h06054b50", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ZIP_DIRECTORY_FOOTER_SIZE, Type = Double, Dynamic = False, Default = \"22", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ZIP_DIRECTORY_HEADER_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h02014b50", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ZIP_DIRECTORY_HEADER_SIZE, Type = Double, Dynamic = False, Default = \"46", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ZIP_ENTRY_FOOTER_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h08074b50", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ZIP_ENTRY_FOOTER_SIZE, Type = Double, Dynamic = False, Default = \"16", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ZIP_ENTRY_HEADER_SIGNATURE, Type = Double, Dynamic = False, Default = \"&h04034b50", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ZIP_ENTRY_HEADER_SIZE, Type = Double, Dynamic = False, Default = \"30", Scope = Private
	#tag EndConstant


	#tag Structure, Name = ZipDirectoryFooter, Flags = &h21
		Signature As UInt32
		  ThisDisk As UInt16
		  FirstDisk As UInt16
		  ThisRecordCount As UInt16
		  TotalRecordCount As UInt16
		  DirectorySize As UInt32
		  Offset As UInt32
		CommentLength As UInt16
	#tag EndStructure

	#tag Structure, Name = ZipDirectoryHeader, Flags = &h21
		Signature As UInt32
		  Version As UInt16
		  VersionNeeded As UInt16
		  Flag As UInt16
		  Method As UInt16
		  ModTime As UInt16
		  ModDate As UInt16
		  CRC32 As UInt32
		  CompressedSize As UInt32
		  UncompressedSize As UInt32
		  FilenameLength As UInt16
		  ExtraLength As UInt16
		  CommentLength As UInt16
		  DiskNumber As UInt16
		  InternalAttributes As UInt16
		  ExternalAttributes As UInt32
		Offset As UInt32
	#tag EndStructure

	#tag Structure, Name = ZipEntryFooter, Flags = &h21
		Signature As UInt32
		  CRC32 As UInt32
		  CompressedSize As UInt32
		UncompressedSize As UInt32
	#tag EndStructure

	#tag Structure, Name = ZipEntryHeader, Flags = &h21
		Signature As UInt32
		  Version As UInt16
		  Flag As UInt16
		  Method As UInt16
		  ModTime As UInt16
		  ModDate As UInt16
		  CRC32 As UInt32
		  CompressedSize As UInt32
		  UncompressedSize As UInt32
		  FilenameLength As UInt16
		ExtraLength As UInt16
	#tag EndStructure


End Module
#tag EndModule
