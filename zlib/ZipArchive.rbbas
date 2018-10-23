#tag Class
Protected Class ZipArchive
	#tag Method, Flags = &h0
		Sub Close()
		  If mArchiveStream <> Nil Then mArchiveStream.Close
		  mArchiveStream = Nil
		  mIndex = -1
		  mDirectoryFooter.Offset = 0
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(ArchiveStream As BinaryStream, Force As Boolean = False)
		  mArchiveStream = ArchiveStream
		  mArchiveStream.LittleEndian = True
		  mForced = Force
		  If Not Me.Reset(0) Then Raise New zlibException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function ConvertDate(NewDate As Date) As Pair
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
		Private Shared Function ConvertDate(Dt As UInt16, tm As UInt16) As Date
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

	#tag Method, Flags = &h0
		Function Count() As Integer
		  Return mDirectoryFooter.ThisRecordCount
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Create(ZipFile As FolderItem, Items() As FolderItem, RootDirectory As FolderItem = Nil, Overwrite As Boolean = False, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, ArchiveComment As String = "") As Boolean
		  Dim stream As BinaryStream = BinaryStream.Create(ZipFile, Overwrite)
		  stream.LittleEndian = True
		  
		  Dim dir As New MemoryBlock(0)
		  Dim dirstream As New BinaryStream(dir)
		  
		  
		  Dim c As Integer = UBound(Items)
		  For i As Integer = 0 To c
		    Dim item As FolderItem = Items(i)
		    If item.Length > &hFFFFFFFF Then Raise New zlibException(ERR_TOO_LARGE)
		    Dim name As String = GetRelativePath(RootDirectory, item)
		    name = ConvertEncoding(name, Encodings.UTF8)
		    If item.Directory Then name = name + "/"
		    Dim bs As BinaryStream
		    If item.Exists And Not item.Directory Then bs = BinaryStream.Open(item)
		    Dim dirheader As ZipDirectoryHeader
		    WriteEntryHeader(stream, name, item.Length, bs, item.ModificationDate, CompressionLevel, dirheader)
		    WriteDirectoryHeader(dirstream, dirheader, name, "", Nil)
		  Next
		  
		  dirstream.Close
		  WriteDirectory(stream, dir, c + 1, ArchiveComment)
		  
		  Dim ok As Boolean = stream.IsZipped()
		  stream.Close
		  Return ok
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Create(ZipFile As FolderItem, RootDirectory As FolderItem, Overwrite As Boolean = False, CompressionLevel As Integer = zlib.Z_DEFAULT_COMPRESSION, ArchiveComment As String = "") As Boolean
		  Dim items() As FolderItem
		  GetChildren(RootDirectory, items)
		  Return Create(ZipFile, items, RootDirectory, Overwrite, CompressionLevel, ArchiveComment)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  Me.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function FindDirectoryFooter(Stream As BinaryStream, ByRef Footer As ZipDirectoryFooter, ByRef IsEmpty As Boolean, ByRef ArchComment As String) As Boolean
		  Stream.Position = Max(0, Stream.Length - MAX_COMMENT_SIZE - MIN_ARCHIVE_SIZE)
		  Dim last As UInt64
		  ' a zip archive can contain other zip archives, in which case it's possible
		  ' for there to be more than one Central Directory Footer in the file. We only
		  ' want the "outermost" directory footer, i.e. the last one.
		  Do Until Stream.EOF
		    If Not SeekSignature(Stream, ZIP_DIRECTORY_FOOTER_SIGNATURE) Then
		      If last = 0 And Stream.Length >= MIN_ARCHIVE_SIZE + MAX_COMMENT_SIZE Then Return False
		      Stream.Position = last
		      Exit Do
		    Else
		      last = Stream.Position
		      Stream.Position = Stream.Position + 4
		    End If
		  Loop Until Stream.Position + MAX_COMMENT_SIZE + MIN_ARCHIVE_SIZE <= Stream.Length
		  
		  If Not ReadDirectoryFooter(Stream, Footer) Then Return False
		  ArchComment = Stream.Read(Footer.CommentLength)
		  IsEmpty = (Stream.Length = MIN_ARCHIVE_SIZE + Footer.CommentLength)
		  Return footer.Offset > MIN_ARCHIVE_SIZE Or IsEmpty
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function FindEntryFooter(Stream As BinaryStream, ByRef Footer As ZipEntryFooter) As Boolean
		  If Not SeekSignature(Stream, ZIP_ENTRY_FOOTER_SIGNATURE) Then Return False
		  If Not ReadEntryFooter(Stream, Footer) Then Return False
		  Return footer.CompressedSize > 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Sub GetChildren(Root As FolderItem, ByRef Results() As FolderItem)
		  Dim c As Integer = Root.Count
		  For i As Integer = 1 To c
		    Dim item As FolderItem = Root.TrueItem(i)
		    Results.Append(item)
		    If item.Directory Then GetChildren(item, Results)
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function GetRelativePath(Root As FolderItem, Item As FolderItem) As String
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

	#tag Method, Flags = &h0
		Function LastError() As Integer
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MoveNext(ExtractTo As FolderItem, Overwrite As Boolean) As Boolean
		  Dim bs As BinaryStream
		  If Not ExtractTo.Directory Then bs = BinaryStream.Create(ExtractTo, Overwrite)
		  Return Me.MoveNext(bs)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MoveNext(ExtractTo As Writeable) As Boolean
		  ' extract the current item
		  If Not ReadEntry(ExtractTo) Then Return False
		  Return ReadHeader()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(ZipFile As FolderItem) As zlib.ZipArchive
		  Return New ZipArchive(BinaryStream.Open(ZipFile))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function ReadDirectoryFooter(Stream As BinaryStream, ByRef Footer As ZipDirectoryFooter) As Boolean
		  Footer.Signature = Stream.ReadUInt32
		  Footer.ThisDisk = Stream.ReadUInt16
		  Footer.FirstDisk = Stream.ReadUInt16
		  Footer.ThisRecordCount = Stream.ReadUInt16
		  Footer.TotalRecordCount = Stream.ReadUInt16
		  Footer.DirectorySize = Stream.ReadUInt32
		  Footer.Offset = Stream.ReadUInt32
		  Footer.CommentLength = Stream.ReadUInt16
		  
		  Return Footer.Signature = ZIP_DIRECTORY_FOOTER_SIGNATURE
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function ReadDirectoryHeader(Stream As BinaryStream, ByRef Header As ZipDirectoryHeader) As Boolean
		  Header.Signature = Stream.ReadUInt32
		  Header.Version = Stream.ReadUInt16
		  Header.VersionNeeded = Stream.ReadUInt16
		  Header.Flag = Stream.ReadUInt16
		  Header.Method = Stream.ReadUInt16
		  Header.ModTime = Stream.ReadUInt16
		  Header.ModDate = Stream.ReadUInt16
		  Header.CRC32 = Stream.ReadUInt32
		  Header.CompressedSize = Stream.ReadUInt32
		  Header.UncompressedSize = Stream.ReadUInt32
		  Header.FilenameLength = Stream.ReadUInt16
		  Header.ExtraLength = Stream.ReadUInt16
		  Header.CommentLength = Stream.ReadUInt16
		  Header.DiskNumber = Stream.ReadUInt16
		  Header.InternalAttributes = Stream.ReadUInt16
		  Header.ExternalAttributes = Stream.ReadUInt32
		  Header.Offset = Stream.ReadUInt32
		  
		  Return Header.Signature = ZIP_DIRECTORY_HEADER_SIGNATURE
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ReadEntry(Destination As Writeable) As Boolean
		  If Destination = Nil Or mCurrentEntry.CompressedSize = 0 Then
		    ' skip the current item
		    mArchiveStream.Position = mArchiveStream.Position + mCurrentEntry.CompressedSize
		    Return True
		  End If
		  
		  Dim zipstream As Readable
		  Select Case mCurrentEntry.Method
		  Case Z_DEFLATED
		    If mZipStream = Nil Then 
		      mZipStream = ZStream.Open(mArchiveStream, RAW_ENCODING)
		      mZipStream.BufferedReading = False
		    Else
		      mZipStream.Reset()
		    End If
		    zipstream = mZipStream
		  Case 0 ' store
		    zipstream = mArchiveStream
		  Else
		    mLastError = ERR_UNSUPPORTED_COMPRESSION
		    Return False
		  End Select
		  
		  ' read the compressed data
		  Dim p As UInt64 = mArchiveStream.Position
		  Dim CRC As UInt32
		  Do Until mArchiveStream.Position - p >= mCurrentEntry.CompressedSize
		    Dim offset As UInt64 = mArchiveStream.Position - p
		    Dim sz As Integer = Min(mCurrentEntry.CompressedSize - offset, CHUNK_SIZE)
		    Dim data As MemoryBlock = zipstream.Read(sz)
		    If data.Size > 0 Then
		      If ValidateChecksums Then CRC = CRC32(data, crc, data.Size)
		      Destination.Write(data)
		    End If
		  Loop Until zipstream.EOF
		  If BitAnd(mCurrentEntry.Flag, FLAG_DESCRIPTOR) = FLAG_DESCRIPTOR Then
		    mArchiveStream.Position = mArchiveStream.Position + ZIP_ENTRY_FOOTER_SIZE
		  End If
		  
		  If ValidateChecksums And (crc <> mCurrentEntry.CRC32) Then
		    mLastError = ERR_CHECKSUM_MISMATCH
		    Return False Or mForced
		  End If
		  
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function ReadEntryFooter(Stream As BinaryStream, ByRef Footer As ZipEntryFooter) As Boolean
		  Footer.Signature = Stream.ReadUInt32
		  Footer.CRC32 = Stream.ReadUInt32
		  Footer.CompressedSize = Stream.ReadUInt32
		  Footer.UncompressedSize = Stream.ReadUInt32
		  
		  Return Footer.Signature = ZIP_ENTRY_FOOTER_SIGNATURE
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function ReadEntryHeader(Stream As BinaryStream, ByRef Header As ZipEntryHeader) As Boolean
		  Header.Signature = Stream.ReadUInt32
		  Header.Version = Stream.ReadUInt16
		  Header.Flag = Stream.ReadUInt16
		  Header.Method = Stream.ReadUInt16
		  Header.ModTime = Stream.ReadUInt16
		  Header.ModDate = Stream.ReadUInt16
		  Header.CRC32 = Stream.ReadUInt32
		  Header.CompressedSize = Stream.ReadUInt32
		  Header.UncompressedSize = Stream.ReadUInt32
		  Header.FilenameLength = Stream.ReadUInt16
		  Header.ExtraLength = Stream.ReadUInt16
		  
		  Return Header.Signature = ZIP_ENTRY_HEADER_SIGNATURE
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ReadHeader() As Boolean
		  ' read the next entry header
		  Dim doitanyway As Boolean = mForced And (mArchiveStream.Length - mArchiveStream.Position >= MIN_ARCHIVE_SIZE)
		  If mArchiveStream.Position >= mDirectoryFooter.Offset And Not doitanyway Then
		    mLastError = ERR_END_ARCHIVE
		    Return False
		  End If
		  
		  mIndex = mIndex + 1
		  If Not ReadEntryHeader(mArchiveStream, mCurrentEntry) Then
		    If Not mForced Then
		      mLastError = ERR_INVALID_ENTRY
		    Else
		      mLastError = ERR_END_ARCHIVE
		    End If
		    Return False
		  End If
		  mCurrentName = mArchiveStream.Read(mCurrentEntry.FilenameLength).Trim
		  If BitAnd(mCurrentEntry.Flag, FLAG_NAME_ENCODING) = FLAG_NAME_ENCODING Then ' UTF8 names
		    mCurrentName = DefineEncoding(mCurrentName, Encodings.UTF8)
		  Else ' CP437 names
		    mCurrentName = DefineEncoding(mCurrentName, Encodings.DOSLatinUS)
		  End If
		  mCurrentExtra = mArchiveStream.Read(mCurrentEntry.ExtraLength)
		  
		  If BitAnd(mCurrentEntry.Flag, FLAG_DESCRIPTOR) = FLAG_DESCRIPTOR And mCurrentEntry.CompressedSize = 0 Then ' footer follows
		    Dim datastart As UInt64 = mArchiveStream.Position
		    Dim footer As ZipEntryFooter
		    If Not FindEntryFooter(mArchiveStream, footer) Then
		      mLastError = ERR_INVALID_ENTRY
		      Return False
		    Else
		      mCurrentEntry.CompressedSize = footer.CompressedSize
		      mCurrentEntry.UncompressedSize = footer.UncompressedSize
		      mCurrentEntry.CRC32 = footer.CRC32
		    End If
		    mArchiveStream.Position = datastart
		  End If
		  mStreamPosition = mArchiveStream.Position
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Repair(ZipFile As FolderItem, RecoveryFile As FolderItem, Optional LogFile As FolderItem) As Boolean
		  Dim root As FolderItem
		  Dim cleanup As Boolean
		  Dim ok As Boolean = True
		  Dim logstream As TextOutputStream
		  If LogFile <> Nil Then logstream = TextOutputStream.Create(LogFile)
		  If RecoveryFile.Directory Then
		    root = RecoveryFile
		  Else
		    Static uniq As Integer = Ticks
		    root = SpecialFolder.Temporary.Child(ZipFile.Name + "_extract" + Hex(uniq))
		    uniq = uniq + 1
		    cleanup = True
		    root.CreateAsFolder
		  End If
		  If logstream <> Nil Then logstream.WriteLine("Extracting to " + root.AbsolutePath)
		  Dim items() As FolderItem
		  Try
		    Dim bs As BinaryStream = BinaryStream.Open(ZipFile)
		    Dim z As ZipArchive
		    Try
		      z = New ZipArchive(bs, True)
		    Catch err
		      If logstream <> Nil Then logstream.WriteLine("  Repair is impossible: " + err.Message)
		      Return False
		    End Try
		    
		    Do Until z.LastError = ERR_END_ARCHIVE
		      If logstream <> Nil Then logstream.WriteLine("  Attempting: " + z.CurrentName)
		      Dim f As FolderItem = CreateTree(root, z.CurrentName)
		      Dim out As BinaryStream
		      If Not f.Directory Then out = BinaryStream.Create(f, True)
		      Try
		        Call z.ReadEntry(out)
		        If logstream <> Nil Then logstream.WriteLine("  OK.")
		      Catch err
		        If logstream <> Nil Then logstream.WriteLine("  Failed: " + err.Message)
		      Finally
		        If out <> Nil Then out.Close
		      End Try
		      items.Append(f)
		      If Not (SeekSignature(bs, ZIP_ENTRY_HEADER_SIGNATURE) And z.ReadHeader) Then Exit Do
		    Loop
		    If logstream <> Nil Then logstream.WriteLine("  No further entries to recover. Creating recovery archive.")
		    If Not RecoveryFile.Directory Then ok = ZipArchive.Create(RecoveryFile, items, root, True)
		  Catch Err
		    ok = False
		  Finally
		    If cleanup Then
		      Do Until UBound(items) = -1
		        items.Pop.Delete
		      Loop
		      root.Delete
		      If logstream <> Nil Then logstream.Close
		    End If
		  End Try
		  Return ok
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Reset(Index As Integer = 0) As Boolean
		  mIndex = -1
		  mCurrentExtra = Nil
		  mCurrentEntry.StringValue(True) = ""
		  mCurrentName = ""
		  Dim isempty As Boolean
		  If mForced Then
		    mArchiveStream.Position = 0
		    If Not SeekSignature(mArchiveStream, ZIP_ENTRY_HEADER_SIGNATURE) Then
		      mLastError = ERR_NOT_ZIPPED
		      Return False
		    End If
		  Else
		    If Not FindDirectoryFooter(mArchiveStream, mDirectoryFooter, isempty, mArchiveComment) Then
		      mLastError = ERR_NOT_ZIPPED
		      Return False
		    End If
		    
		    mArchiveStream.Position = mDirectoryFooter.Offset
		    If Not isempty Then
		      Dim header As ZipDirectoryHeader
		      If Not ReadDirectoryHeader(mArchiveStream, header) Then
		        mLastError = ERR_NOT_ZIPPED
		        Return False
		      End If
		      mArchiveStream.Position = header.Offset ' move to offset of first entry
		    End If
		  End If
		  
		  Do
		    If Not Me.MoveNext(Nil) Then Return ((Index = -1 Or isempty) And mLastError = ERR_END_ARCHIVE)
		  Loop Until mIndex >= Index And Index > -1
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function SeekSignature(Stream As BinaryStream, Signature As UInt32) As Boolean
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

	#tag Method, Flags = &h0
		Function Test() As Boolean
		  If Not Me.Reset(0) Then Return False
		  Dim vc As Boolean = ValidateChecksums
		  ValidateChecksums = True
		  Dim nullstream As New BinaryStream(New MemoryBlock(0))
		  nullstream.Close
		  Do
		  Loop Until Not Me.MoveNext(nullstream)
		  ValidateChecksums = vc
		  Return mLastError = ERR_END_ARCHIVE
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Sub WriteDirectory(Stream As BinaryStream, Directory As MemoryBlock, Count As UInt32, ArchiveComment As String)
		  ArchiveComment = ConvertEncoding(ArchiveComment, Encodings.UTF8)
		  Dim footer As ZipDirectoryFooter
		  footer.Signature = ZIP_DIRECTORY_FOOTER_SIGNATURE
		  footer.CommentLength = ArchiveComment.LenB
		  footer.ThisRecordCount = Count
		  footer.TotalRecordCount = Count
		  footer.Offset = stream.Position
		  Stream.Write(Directory)
		  
		  footer.DirectorySize = Stream.Position - footer.Offset
		  WriteDirectoryFooter(Stream, footer)
		  Stream.Write(ArchiveComment)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Sub WriteDirectoryFooter(Stream As BinaryStream, Footer As ZipDirectoryFooter)
		  Stream.WriteUInt32(Footer.Signature)
		  Stream.WriteUInt16(Footer.ThisDisk)
		  Stream.WriteUInt16(Footer.FirstDisk)
		  Stream.WriteUInt16(Footer.ThisRecordCount)
		  Stream.WriteUInt16(Footer.TotalRecordCount)
		  Stream.WriteUInt32(Footer.DirectorySize)
		  Stream.WriteUInt32(Footer.Offset)
		  Stream.WriteUInt16(Footer.CommentLength)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Sub WriteDirectoryHeader(Stream As BinaryStream, Header As ZipDirectoryHeader, Name As String, Comment As String, Extra As MemoryBlock)
		  If Comment.LenB > MAX_COMMENT_SIZE Then Comment = LeftB(Comment, MAX_COMMENT_SIZE)
		  If Name.LenB > MAX_NAME_SIZE Then Raise New zlibException(ERR_INVALID_NAME)
		  If Extra <> Nil And Extra.Size > MAX_EXTRA_SIZE Then Extra.Size = MAX_EXTRA_SIZE
		  
		  Header.CommentLength = Comment.LenB
		  Header.FilenameLength = Name.LenB
		  If Extra <> Nil Then Header.ExtraLength = Extra.Size Else Header.ExtraLength = 0
		  
		  Stream.WriteUInt32(Header.Signature)
		  Stream.WriteUInt16(Header.Version)
		  Stream.WriteUInt16(Header.VersionNeeded)
		  Stream.WriteUInt16(Header.Flag)
		  Stream.WriteUInt16(Header.Method)
		  Stream.WriteUInt16(Header.ModTime)
		  Stream.WriteUInt16(Header.ModDate)
		  Stream.WriteUInt32(Header.CRC32)
		  Stream.WriteUInt32(Header.CompressedSize)
		  Stream.WriteUInt32(Header.UncompressedSize)
		  Stream.WriteUInt16(Header.FilenameLength)
		  Stream.WriteUInt16(Header.ExtraLength)
		  Stream.WriteUInt16(Header.CommentLength)
		  Stream.WriteUInt16(Header.DiskNumber)
		  Stream.WriteUInt16(Header.InternalAttributes)
		  Stream.WriteUInt32(Header.ExternalAttributes)
		  Stream.WriteUInt32(Header.Offset)
		  Stream.Write(Name)
		  If Extra <> Nil Then Stream.Write(Extra)
		  Stream.Write(Comment)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Sub WriteEntryHeader(Stream As BinaryStream, Name As String, Length As UInt32, Source As Readable, ModDate As Date, CompressionLevel As Integer, ByRef DirectoryHeader As ZipDirectoryHeader)
		  DirectoryHeader.Offset = Stream.Position
		  Dim crcoff, compszoff, dataoff As UInt64
		  Stream.WriteUInt32(ZIP_ENTRY_HEADER_SIGNATURE)
		  DirectoryHeader.Signature = ZIP_DIRECTORY_HEADER_SIGNATURE
		  
		  Stream.WriteUInt16(20) ' version
		  DirectoryHeader.Version = 20
		  DirectoryHeader.VersionNeeded = 10
		  
		  If Name.Encoding = Encodings.UTF8 Then
		    DirectoryHeader.Flag = FLAG_NAME_ENCODING
		  End If
		  Stream.WriteUInt16(DirectoryHeader.Flag) ' flag
		  
		  If Length = 0 Or CompressionLevel = 0 Then
		    Stream.WriteUInt16(0) ' method=none
		    DirectoryHeader.Method = 0
		  Else
		    Stream.WriteUInt16(Z_DEFLATED) ' method=deflate
		    DirectoryHeader.Method = Z_DEFLATED
		  End If
		  Dim modtim As Pair = ConvertDate(ModDate)
		  Stream.WriteUInt16(modtim.Right) ' modtime
		  Stream.WriteUInt16(modtim.Left) ' moddate
		  DirectoryHeader.ModDate = modtim.Left
		  DirectoryHeader.ModTime = modtim.Right
		  
		  crcoff = Stream.Position
		  Stream.WriteUInt32(0) ' crc32; to be filled later
		  
		  compszoff = Stream.Position
		  Stream.WriteUInt32(0) ' compressed size; to be filled later
		  
		  DirectoryHeader.UncompressedSize = Length
		  Stream.WriteUInt32(Length) ' uncompressed size
		  
		  DirectoryHeader.FilenameLength = Name.LenB
		  Stream.WriteUInt16(Name.LenB) ' name length
		  
		  DirectoryHeader.ExtraLength = 0
		  Stream.WriteUInt16(0) ' extra length
		  
		  Stream.Write(name)
		  //Stream.Write("") ' extra
		  
		  dataoff = Stream.Position
		  Dim crc As UInt32
		  If Source <> Nil And Length > 0 Then
		    Dim z As Writeable
		    If CompressionLevel <> 0 Then
		      z = ZStream.Create(Stream, CompressionLevel, Z_DEFAULT_STRATEGY, RAW_ENCODING)
		    Else
		      z = Stream
		    End If
		    Do Until Source.EOF
		      Dim data As MemoryBlock = Source.Read(CHUNK_SIZE)
		      crc = zlib.CRC32(data, crc)
		      z.Write(data)
		    Loop
		    If z IsA ZStream Then ZStream(z).Close
		  End If
		  Dim endoff As UInt64 = Stream.Position
		  Dim compsz As UInt32 = endoff - dataoff
		  Stream.Position = compszoff
		  Stream.WriteUInt32(compsz)
		  DirectoryHeader.CompressedSize = compsz
		  Stream.Position = crcoff
		  Stream.WriteUInt32(crc)
		  DirectoryHeader.CRC32 = crc
		  Stream.Position = endoff
		End Sub
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mArchiveComment
			End Get
		#tag EndGetter
		ArchiveComment As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Select Case True
			  Case BitAnd(mCurrentEntry.Flag, 1) = 1 And BitAnd(mCurrentEntry.Flag, 2) = 2
			    Return 1 ' fastest
			  Case BitAnd(mCurrentEntry.Flag, 1) = 1 And BitAnd(mCurrentEntry.Flag, 2) <> 2
			    Return 9 ' best
			  Case BitAnd(mCurrentEntry.Flag, 1) <> 1 And BitAnd(mCurrentEntry.Flag, 2) <> 2
			    Return 6 ' normal
			  Case BitAnd(mCurrentEntry.Flag, 1) <> 1 And BitAnd(mCurrentEntry.Flag, 2) = 2
			    Return 3 ' fast
			  Case mCurrentEntry.Method = 0
			    Return 0 ' none
			  End Select
			  
			  
			End Get
		#tag EndGetter
		CompressionLevel As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mIndex > -1 Then Return mCurrentEntry.CRC32 Else Return 0
			End Get
		#tag EndGetter
		CurrentCRC32 As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mIndex > -1 Then Return mCurrentExtra
			End Get
		#tag EndGetter
		CurrentExtraData As MemoryBlock
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mIndex
			End Get
		#tag EndGetter
		CurrentIndex As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mIndex = -1 Then Return Nil
			  
			  Return ConvertDate(mCurrentEntry.ModDate, mCurrentEntry.ModTime)
			End Get
		#tag EndGetter
		CurrentModificationDate As Date
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mIndex > -1 Then Return mCurrentName
			End Get
		#tag EndGetter
		CurrentName As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mIndex > -1 Then Return mCurrentEntry.CompressedSize Else Return -1
			End Get
		#tag EndGetter
		CurrentSize As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mIndex > -1 Then Return mCurrentEntry.UncompressedSize Else Return -1
			End Get
		#tag EndGetter
		CurrentUncompressedSize As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return BitAnd(mCurrentEntry.Flag, FLAG_ENCRYPTED) = FLAG_ENCRYPTED
			End Get
		#tag EndGetter
		IsEncrypted As Boolean
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mArchiveComment As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mArchiveStream As BinaryStream
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentEntry As ZipEntryHeader
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentExtra As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentName As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDirectoryFooter As ZipDirectoryFooter
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mExtraData As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mForced As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mIndex As Integer = -1
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mLastError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mStreamPosition As UInt64
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mZipStream As zlib.ZStream
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mStreamPosition
			End Get
		#tag EndGetter
		StreamPosition As UInt64
	#tag EndComputedProperty

	#tag Property, Flags = &h0
		ValidateChecksums As Boolean = True
	#tag EndProperty


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

	#tag Constant, Name = MIN_ARCHIVE_SIZE, Type = Double, Dynamic = False, Default = \"ZIP_DIRECTORY_FOOTER_SIZE\r", Scope = Private
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


	#tag ViewBehavior
		#tag ViewProperty
			Name="CompressionLevel"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="CurrentIndex"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="CurrentName"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="IsEncrypted"
			Group="Behavior"
			Type="Boolean"
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
		#tag ViewProperty
			Name="ValidateChecksums"
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
