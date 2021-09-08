#tag Class
Protected Class ZipReader
	#tag Method, Flags = &h0
		Sub Close()
		  ' Releases all resources. The ZipReader may not be used after calling this method.
		  
		  If mStream <> Nil And (mData <> Nil Or mDataFile <> Nil) Then mStream.Close
		  mStream = Nil
		  mData = Nil
		  mDataFile = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(ZipStream As BinaryStream, Force As Boolean = False)
		  ' Construct a ZipReader from the ZipStream.
		  ' If Force=True then less strict techniques are used:
		  '  * The zip data is assumed to start at offset 0
		  '  * The central directory is ignored
		  '  * Invalid entries are skipped by scanning forward until the next entry is found (slow)
		  '  * Checksum mismatches will not cause MoveNext() to return False (LastError is updated correctly, though)
		  ' Forcible reading can yield a performance boost on well-formed archives.
		  
		  mStream = ZipStream
		  mStream.LittleEndian = True
		  mForced = Force
		  If Not Me.Reset(0) Then Raise New ZipException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(ZipStream As FolderItem, Force As Boolean = False)
		  ' Construct a ZipReader from the ZipStream file.
		  ' If Force=True then less strict techniques are used:
		  '  * The zip data is assumed to start at offset 0
		  '  * The central directory is ignored
		  '  * Invalid entries are skipped by scanning forward until the next entry is found (slow)
		  '  * Checksum mismatches will not cause MoveNext() to return False (LastError is updated correctly, though)
		  ' Forcible reading can yield a performance boost on well-formed archives.
		  
		  mDataFile = ZipStream
		  Me.Constructor(BinaryStream.Open(ZipStream), Force)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(ZipData As MemoryBlock, Force As Boolean = False)
		  ' Construct a ZipReader from the ZipData.
		  ' If Force=True then less strict techniques are used:
		  '  * The zip data is assumed to start at offset 0
		  '  * The central directory is ignored
		  '  * Invalid entries are skipped by scanning forward until the next entry is found (slow)
		  '  * Checksum mismatches will not cause MoveNext() to return False (LastError is updated correctly, though)
		  ' Forcible reading can yield a performance boost on well-formed archives.
		  
		  mData = ZipData
		  Me.Constructor(New BinaryStream(mData), Force)
		End Sub
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

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  Me.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function FindDirectoryFooter(Stream As BinaryStream) As Boolean
		  Stream.Position = Max(0, Stream.Length - MAX_COMMENT_SIZE - MIN_ARCHIVE_SIZE)
		  Dim last As UInt64
		  ' a zip archive can contain other zip archives, in which case it's possible
		  ' for there to be more than one Central Directory Footer in the file. We only
		  ' want the "outermost" directory footer, i.e. the last one.
		  Do Until Stream.EOF
		    If Not SeekSignature(Stream, ZIP_DIRECTORY_FOOTER_SIGNATURE) Then
		      If last = 0 And Stream.Length >= MIN_ARCHIVE_SIZE + MAX_COMMENT_SIZE Then Return False
		      Stream.Position = last
		      Return True
		    Else
		      last = Stream.Position
		      Stream.Position = Stream.Position + 4
		    End If
		  Loop Until Stream.Position + MAX_COMMENT_SIZE + MIN_ARCHIVE_SIZE <= Stream.Length
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function FindEntryFooter() As Boolean
		  ' Read the zip entry footer if it exists
		  ' The footer is appended if the zip creator was not able to seek backwards in the stream
		  ' to fill in the compressed size and CRC32 fields of the zip entry header.
		  
		  If BitAnd(mCurrentEntry.Flag, FLAG_DESCRIPTOR) = FLAG_DESCRIPTOR And mCurrentEntry.CompressedSize = 0 Then ' descriptor follows
		    Dim datastart As UInt64 = mStream.Position
		    Dim footer As ZipEntryFooter
		    If Not ReadEntryFooter(mStream, footer) Then
		      mLastError = ERR_INVALID_ENTRY
		      Return False
		    End If
		    mCurrentEntry.CompressedSize = footer.CompressedSize
		    mCurrentEntry.UncompressedSize = footer.UncompressedSize
		    mCurrentEntry.CRC32 = footer.CRC32
		    mStream.Position = datastart
		  End If
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function GetDirectoryFooter() As Boolean
		  ' Locates the end-of-central-directory footer and archive comment.
		  ' Returns True if the footer is found and appears to be sane.
		  
		  If Not FindDirectoryFooter(mStream) Then Return False
		  If Not ReadDirectoryFooter(mStream, mDirectoryFooter) Then Return False
		  mArchiveComment = mStream.Read(mDirectoryFooter.CommentLength)
		  mIsEmpty = (mStream.Length = MIN_ARCHIVE_SIZE + mDirectoryFooter.CommentLength)
		  Return mDirectoryFooter.Offset > CType(MIN_ARCHIVE_SIZE, UInt32) Or mIsEmpty
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MoveNext(ExtractTo As Writeable) As Boolean
		  ' Extract the current item and then read the metadata of the next item, if any.
		  ' If ExtractTo is Nil then the current item is skipped.
		  ' Returns True if the current item was extracted and the next item is ready. Check LastError
		  ' for details if this method returns False; in particulur the error ERR_END_ARCHIVE(-202)
		  ' means that extraction was successful but there are no further entries.
		  
		  If Not mForced And mStream.Position >= mDirectoryFooter.Offset Then
		    mLastError = ERR_END_ARCHIVE
		    Return False
		  End If
		  
		  Return ReadEntry(ExtractTo) And ReadHeader()
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
		  
		  If Footer.Signature = ZIP_DIRECTORY_FOOTER_SIGNATURE And _
		    Stream.Position + Footer.CommentLength = Stream.Length And _
		    Footer.TotalRecordCount >= Footer.ThisRecordCount And _
		    Footer.ThisDisk >= Footer.FirstDisk And _
		    Stream.Position - MIN_ARCHIVE_SIZE - Footer.DirectorySize = Footer.Offset Then
		    Return True
		  End If
		  
		  
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

	#tag Method, Flags = &h1
		Protected Function ReadEntry(WriteTo As Writeable) As Boolean
		  ' Decompress the current item into the WriteTo parameter.
		  ' Returns True on success; check LastError if it returns False.
		  ' On successful return, the mStream property will be positioned to
		  ' read the headers of the next entry.
		  
		  If WriteTo = Nil Or mCurrentEntry.CompressedSize = 0 Then
		    SkipEntryData()
		    Return True
		  End If
		  
		  Dim zipstream As Readable = GetDecompressor(mCurrentEntry.Method, mStream)
		  If zipstream = Nil Then
		    mLastError = ERR_UNSUPPORTED_COMPRESSION
		    SkipEntryData()
		    Return False Or mForced
		  End If
		  
		  ' read the compressed data
		  Dim startpos As UInt64 = mStream.Position
		  Dim CRC As UInt32
		  Do Until mStream.Position - startpos >= mCurrentEntry.CompressedSize
		    Dim offset As UInt64 = mStream.Position - startpos
		    Dim sz As Integer = Min(mCurrentEntry.CompressedSize - offset, CHUNK_SIZE)
		    Dim data As MemoryBlock = zipstream.Read(sz)
		    If data.Size > 0 Then
		      If ValidateChecksums Then CRC = PKZip.CRC32(data, CRC)
		      WriteTo.Write(data)
		    End If
		  Loop Until zipstream.EOF
		  SkipEntryData(mStream.Position - startpos) ' skip the footer
		  
		  If ValidateChecksums And (CRC <> mCurrentEntry.CRC32) Then
		    mLastError = ERR_CHECKSUM_MISMATCH
		    Return False Or mForced
		  End If
		  
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function ReadEntryFooter(Stream As BinaryStream, ByRef Footer As ZipEntryFooter) As Boolean
		  If Not SeekSignature(Stream, ZIP_ENTRY_FOOTER_SIGNATURE) Then Return False
		  
		  Footer.Signature = Stream.ReadUInt32
		  Footer.CRC32 = Stream.ReadUInt32
		  Footer.CompressedSize = Stream.ReadUInt32
		  Footer.UncompressedSize = Stream.ReadUInt32
		  
		  Return Footer.Signature = ZIP_ENTRY_FOOTER_SIGNATURE And Footer.CompressedSize > 0
		  
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

	#tag Method, Flags = &h1
		Protected Function ReadHeader() As Boolean
		  ' Read the next entry's header into the CurrentName, CurrentSize, etc. properties.
		  ' Returns True on success; check LastError if it returns False.
		  ' On successful return, the mStream property will be positioned to
		  ' read the file data of the (now) current item.
		  
		  Dim doitanyway As Boolean = mForced And (mStream.Length - mStream.Position >= MIN_ARCHIVE_SIZE)
		  If mStream.Position >= mDirectoryFooter.Offset And Not doitanyway Then
		    mLastError = ERR_END_ARCHIVE
		    Return False
		  End If
		  
		  mIndex = mIndex + 1
		  If Not ReadEntryHeader(mStream, mCurrentEntry) Then
		    mCurrentEntry.StringValue(True) = ""
		    If mForced Then mLastError = ERR_END_ARCHIVE Else mLastError = ERR_INVALID_ENTRY
		    Return False
		  End If
		  
		  mCurrentName = mStream.Read(mCurrentEntry.FilenameLength)
		  If BitAnd(mCurrentEntry.Flag, FLAG_NAME_ENCODING) = FLAG_NAME_ENCODING Then ' UTF8 names
		    mCurrentName = DefineEncoding(mCurrentName, Encodings.UTF8).Trim
		  Else ' CP437 names
		    mCurrentName = DefineEncoding(mCurrentName, Encodings.DOSLatinUS).Trim
		  End If
		  
		  mCurrentExtra = mStream.Read(mCurrentEntry.ExtraLength)
		  
		  Return FindEntryFooter()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function RepairZip(ZipFile As FolderItem, RecoveryFile As FolderItem, Optional LogFile As FolderItem) As Boolean
		  ' This method attempts to forcibly extract the contents of the archive specified by ZipFile.
		  ' Corrupt or damaged files within the archive will be extracted as zero-length files with the
		  ' appropriate path and name. If the RevoveryFile points to a file then the recovered files
		  ' will be re-Zipped as a new archive in that file. If the RecoveryFile is a directory then
		  ' the recovered contents will be extracted to that directory.
		  
		  Dim root As FolderItem
		  Dim cleanup As Boolean
		  Dim ok As Boolean = True
		  Dim reccount, errcount As Integer
		  Dim log As TextOutputStream
		  If LogFile <> Nil Then log = TextOutputStream.Create(LogFile)
		  If log <> Nil Then log.WriteLine("Beginning recovery of: " + ZipFile.AbsolutePath_)
		  If RecoveryFile.Directory Then
		    root = RecoveryFile
		    If log <> Nil Then log.WriteLine("Extract to " + root.AbsolutePath_)
		  Else
		    Static uniq As Integer = Ticks
		    root = SpecialFolder.Temporary.Child(ZipFile.Name + "_extract" + Hex(uniq))
		    uniq = uniq + 1
		    cleanup = True
		    root.CreateAsFolder
		    If log <> Nil Then log.WriteLine("Recover to " + RecoveryFile.AbsolutePath_)
		  End If
		  
		  Dim items() As FolderItem
		  Try
		    Dim bs As BinaryStream = BinaryStream.Open(ZipFile)
		    Dim zr As ZipReader
		    Try
		      zr = New ZipReader(bs, True)
		    Catch err
		      If log <> Nil Then log.WriteLine("Repair is impossible: " + err.Message)
		      Return False
		    End Try
		    
		    Dim writer As ZipWriter
		    If Not RecoveryFile.Directory Then writer = New ZipWriter
		    
		    Do Until zr.LastError = ERR_END_ARCHIVE
		      If log <> Nil Then log.WriteLine("Attempting: " + zr.CurrentName + "(" + Str(zr.CurrentIndex) + "/" + Str(zr.mStream.Position) + ")")
		      Dim f As FolderItem = CreateRelativePath(root, zr.CurrentName)
		      Dim out As BinaryStream
		      If Not f.Directory Then out = BinaryStream.Create(f, True)
		      items.Insert(0, f)
		      Try
		        Call zr.ReadEntry(out)
		        reccount = reccount + 1
		      Catch err
		        If log <> Nil Then log.WriteLine(" Error: " + ReplaceLineEndings(err.Message, " " + EndOfLine))
		        errcount = errcount + 1
		      Finally
		        If out <> Nil Then out.Close
		      End Try
		      If writer <> Nil Then Call writer.AppendEntry(f, root)
		      If Not (SeekSignature(bs, ZIP_ENTRY_HEADER_SIGNATURE) And zr.ReadHeader) Then Exit Do
		    Loop
		    
		    If log <> Nil Then
		      log.WriteLine("---Completed: " + Format(reccount + errcount, "###,###,##0") + _
		      " processed(" + Format(reccount, "###,###,##0") + " OK, " + Format(errcount, "###,###,##0") + " errors.)---")
		    End If
		    
		    If writer <> Nil Then writer.Commit(RecoveryFile, True)
		    ok = True
		  Catch Err
		    ok = False
		  Finally
		    If cleanup Then
		      Do Until UBound(items) = -1
		        items.Pop.Delete
		      Loop
		      root.Delete
		      If log <> Nil Then log.Close
		    End If
		  End Try
		  Return ok
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Reset(Index As Integer) As Boolean
		  ' Repositions the "current" item to the specified Index. The first item is
		  ' at index zero. Pass -1 to perform a consistency check on the file
		  ' structure; this check verifies that the file appears to be a properly
		  ' formatted zip file, but doesn't verify the integrity of the files stored
		  ' within (See PKZip.TestZip for that.)
		  
		  mIndex = -1
		  mCurrentExtra = Nil
		  mCurrentEntry.StringValue(True) = ""
		  mCurrentName = ""
		  
		  If Not mForced Then ' normal mode
		    ' locate the end-of-directory header
		    If Not GetDirectoryFooter() Then
		      mLastError = ERR_NOT_ZIPPED
		      Return False
		    End If
		    
		    ' read the offset of the central directory
		    mStream.Position = mDirectoryFooter.Offset
		    If Not mIsEmpty Then
		      ' read the first directory header
		      Dim header As ZipDirectoryHeader
		      If Not ReadDirectoryHeader(mStream, header) Then
		        mLastError = ERR_NOT_ZIPPED
		        Return False
		      End If
		      mStream.Position = header.Offset ' move to offset of first entry
		    End If
		    
		  Else ' forced mode
		    ' start at the beginning and scan forward until we find something
		    ' that looks like an entry
		    mStream.Position = 0
		    If Not SeekSignature(mStream, ZIP_ENTRY_HEADER_SIGNATURE) Then
		      mLastError = ERR_NOT_ZIPPED
		      Return False
		    End If
		  End If
		  
		  ' skip each entry until we reach the specified Index
		  Do
		    If Not Me.MoveNext(Nil) Then Return ((Index = -1 Or mIsEmpty) And mLastError = ERR_END_ARCHIVE)
		  Loop Until mIndex >= Index And Index > -1
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub SkipEntryData(BytesReadSoFar As UInt32 = 0)
		  ' Skips the remaining portion of the file data plus footer (if present), aligning
		  ' the stream to read the headers of the next entry.
		  
		  mStream.Position = mStream.Position + mCurrentEntry.CompressedSize - BytesReadSoFar
		  If BitAnd(mCurrentEntry.Flag, FLAG_DESCRIPTOR) = FLAG_DESCRIPTOR Then
		    mStream.Position = mStream.Position + ZIP_ENTRY_FOOTER_SIZE
		  End If
		End Sub
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mArchiveComment
			End Get
		#tag EndGetter
		ArchiveComment As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' Returns the compression level that was used on the current item. Some archivers do not
			  ' fill in this information.
			  
			  Dim bit1, bit2 As Boolean
			  bit1 = (BitAnd(mCurrentEntry.Flag, 1) = 1)
			  bit2 = (BitAnd(mCurrentEntry.Flag, 2) = 2)
			  
			  Select Case True
			  Case bit1 And bit2
			    Return 1 ' fastest
			  Case Not bit1 And bit2
			    Return 3 ' fast
			  Case Not bit1 And Not bit2
			    Return 6 ' normal
			  Case bit1 And Not bit2
			    Return 9 ' best
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
			  ' Returns the number of entries purported to exist in the archive (this can be wrong.)
			  
			  Return mDirectoryFooter.ThisRecordCount
			End Get
		#tag EndGetter
		Count As UInt32
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
			  Return mCurrentEntry.Method
			End Get
		#tag EndGetter
		CurrentMethod As UInt32
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
			  If mIndex > -1 Then Return mCurrentEntry.CompressedSize Else Return 0
			End Get
		#tag EndGetter
		CurrentSize As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mIndex > -1 Then Return mCurrentEntry.UncompressedSize Else Return 0
			End Get
		#tag EndGetter
		CurrentUncompressedSize As UInt32
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  ' The most recent error while reading the archive. Check this value if MoveNext() or Reset() return False.
			  
			  Return mLastError
			End Get
		#tag EndGetter
		LastError As Int32
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mArchiveComment As String
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
		Private mData As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDataFile As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDirectoryFooter As ZipDirectoryFooter
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mForced As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mIndex As Integer = -1
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mIsEmpty As Boolean
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mLastError As Int32
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mStream As BinaryStream
	#tag EndProperty

	#tag Property, Flags = &h0
		ValidateChecksums As Boolean = True
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="ArchiveComment"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
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
