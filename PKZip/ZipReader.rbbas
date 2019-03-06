#tag Class
Protected Class ZipReader
	#tag Method, Flags = &h0
		Sub Close()
		  ' Releases all resources. The ZipReader may not be used after calling this method.
		  
		  If mStream <> Nil Then mStream.Close
		  mStream = Nil
		  mData = Nil
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
		  ' Forible reading can yield a performance boost on well-formed archives.
		  
		  mStream = ZipStream
		  mStream.LittleEndian = True
		  mForced = Force
		  If Not Me.Reset(0) Then Raise New ZipException(mLastError)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(ZipStream As FolderItem, Force As Boolean = False)
		  Me.Constructor(BinaryStream.Open(ZipStream), Force)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(ZipData As MemoryBlock, Force As Boolean = False)
		  mData = ZipData
		  Me.Constructor(New BinaryStream(mData), Force)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Count() As UInt32
		  Return mDirectoryFooter.ThisRecordCount
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  Me.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function FindDirectoryFooter() As Boolean
		  If Not FindDirectoryFooter(mStream) Then Return False
		  If Not ReadDirectoryFooter(mStream, mDirectoryFooter) Then Return False
		  mArchiveComment = mStream.Read(mDirectoryFooter.CommentLength)
		  mIsEmpty = (mStream.Length = MIN_ARCHIVE_SIZE + mDirectoryFooter.CommentLength)
		  Return mDirectoryFooter.Offset > MIN_ARCHIVE_SIZE Or mIsEmpty
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
		    If Not FindEntryFooter(mStream, footer) Then
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

	#tag Method, Flags = &h0
		Function LastError() As Int32
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MoveNext(ExtractTo As Writeable) As Boolean
		  ' Extract the current item. If ExtractTo is Nil then the current item is skipped.
		  ' Returns True if the item was extracted and the next item is ready. Check LastError
		  ' for details if this method returns False; in particulur the error ERR_END_ARCHIVE
		  ' means that extraction was successful but there are no further entries.
		  
		  Return ReadEntry(ExtractTo) And ReadHeader()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ReadEntry(Destination As Writeable) As Boolean
		  If Destination = Nil Or mCurrentEntry.CompressedSize = 0 Then
		    ' skip the current item
		    mStream.Position = mStream.Position + mCurrentEntry.CompressedSize
		    Return True
		  End If
		  
		  Dim zipstream As Readable = GetDecompressor(mCurrentEntry.Method, mStream)
		  If zipstream = Nil Then
		    mLastError = ERR_UNSUPPORTED_COMPRESSION
		    mStream.Position = mStream.Position + mCurrentEntry.CompressedSize
		    Return False Or mForced
		  End If
		  
		  ' read the compressed data
		  Dim p As UInt64 = mStream.Position
		  Dim CRC As UInt32
		  Do Until mStream.Position - p >= mCurrentEntry.CompressedSize
		    Dim offset As UInt64 = mStream.Position - p
		    Dim sz As Integer = Min(mCurrentEntry.CompressedSize - offset, CHUNK_SIZE)
		    Dim data As MemoryBlock = zipstream.Read(sz)
		    If data.Size > 0 Then
		      If ValidateChecksums Then CRC = PKZip.CRC32(data, CRC)
		      Destination.Write(data)
		    End If
		  Loop Until zipstream.EOF
		  If BitAnd(mCurrentEntry.Flag, FLAG_DESCRIPTOR) = FLAG_DESCRIPTOR Then
		    mStream.Position = mStream.Position + ZIP_ENTRY_FOOTER_SIZE
		  End If
		  
		  If ValidateChecksums And (CRC <> mCurrentEntry.CRC32) Then
		    mLastError = ERR_CHECKSUM_MISMATCH
		    Return False Or mForced
		  End If
		  
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ReadHeader() As Boolean
		  ' read the next entry header
		  Dim doitanyway As Boolean = mForced And (mStream.Length - mStream.Position >= MIN_ARCHIVE_SIZE)
		  If mStream.Position >= mDirectoryFooter.Offset And Not doitanyway Then
		    mLastError = ERR_END_ARCHIVE
		    Return False
		  End If
		  
		  mIndex = mIndex + 1
		  If Not ReadEntryHeader(mStream, mCurrentEntry) Then
		    If Not mForced Then
		      mLastError = ERR_INVALID_ENTRY
		    Else
		      mLastError = ERR_END_ARCHIVE
		    End If
		    Return False
		  End If
		  mCurrentName = mStream.Read(mCurrentEntry.FilenameLength).Trim
		  If BitAnd(mCurrentEntry.Flag, FLAG_NAME_ENCODING) = FLAG_NAME_ENCODING Then ' UTF8 names
		    mCurrentName = DefineEncoding(mCurrentName, Encodings.UTF8)
		  Else ' CP437 names
		    mCurrentName = DefineEncoding(mCurrentName, Encodings.DOSLatinUS)
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
		  If log <> Nil Then log.WriteLine("Beginning recovery of: " + ZipFile.AbsolutePath)
		  If RecoveryFile.Directory Then
		    root = RecoveryFile
		    If log <> Nil Then log.WriteLine("Extract to " + root.AbsolutePath)
		  Else
		    Static uniq As Integer = Ticks
		    root = SpecialFolder.Temporary.Child(ZipFile.Name + "_extract" + Hex(uniq))
		    uniq = uniq + 1
		    cleanup = True
		    root.CreateAsFolder
		    If log <> Nil Then log.WriteLine("Recover to " + RecoveryFile.AbsolutePath)
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
		      Dim f As FolderItem = CreateTree(root, zr.CurrentName)
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
		    
		    If writer <> Nil Then
		      writer.Commit(RecoveryFile, True)
		      ok = (writer.LastError = 0)
		    Else
		      ok = True
		    End If
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
		  mIndex = -1
		  mCurrentExtra = Nil
		  mCurrentEntry.StringValue(True) = ""
		  mCurrentName = ""
		  
		  If mForced Then
		    mStream.Position = 0
		    If Not SeekSignature(mStream, ZIP_ENTRY_HEADER_SIGNATURE) Then
		      mLastError = ERR_NOT_ZIPPED
		      Return False
		    End If
		  Else
		    If Not FindDirectoryFooter() Then
		      mLastError = ERR_NOT_ZIPPED
		      Return False
		    End If
		    
		    mStream.Position = mDirectoryFooter.Offset
		    If Not mIsEmpty Then
		      Dim header As ZipDirectoryHeader
		      If Not ReadDirectoryHeader(mStream, header) Then
		        mLastError = ERR_NOT_ZIPPED
		        Return False
		      End If
		      mStream.Position = header.Offset ' move to offset of first entry
		    End If
		  End If
		  
		  Do
		    If Not Me.MoveNext(Nil) Then Return ((Index = -1 Or mIsEmpty) And mLastError = ERR_END_ARCHIVE)
		  Loop Until mIndex >= Index And Index > -1
		  Return True
		End Function
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
