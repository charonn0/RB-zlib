#tag Class
Protected Class TapeArchive
	#tag Method, Flags = &h0
		Function AppendDirectory(DirectoryName As String) As Boolean
		  Me.Reset()
		  Dim name, path() As String
		  path = Split(DirectoryName, "/")
		  name = path(0)
		  path.Remove(0)
		  Do Until Not Me.MoveNext()
		    If CurrentName = DirectoryName Then Return False
		  Loop
		  Me.Pad()
		  Dim header As FileHeader
		  header.Name = DirectoryName
		  header.TypeFlag = Asc("5")
		  header.Checksum = Encodings.ASCII.Chr(32) + Encodings.ASCII.Chr(32) + Oct(GetCheckSum(header))
		  Dim mb As New MemoryBlock(512)
		  mb.StringValue(0, header.Size) = header.StringValue(TargetLittleEndian)
		  mArchive.Write(mb)
		  Me.Pad()
		  mIndex = mIndex + 1
		  mDirty = True
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function AppendFile(File As FolderItem) As Boolean
		  Dim bs As BinaryStream = BinaryStream.Open(File)
		  Return Me.AppendFile(File.Name, bs)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function AppendFile(FileName As String, FileData As Readable) As Boolean
		  Me.Reset(True)
		  Me.Pad()
		  Dim hpos As Integer = mArchive.Position
		  
		  mArchive.Write(Chr(0))
		  Me.Pad
		  
		  Dim i As Integer
		  Do Until FileData.EOF
		    Dim data As String = FileData.Read(4096)
		    mArchive.Write(data)
		    i = i + data.LenB
		  Loop
		  
		  mArchive.Position = hpos
		  Dim header As FileHeader
		  header.Name = FileName
		  header.Length = Oct(i)
		  header.TypeFlag = Asc("7")
		  header.Checksum = Encodings.ASCII.Chr(32) + Encodings.ASCII.Chr(32) + Oct(GetCheckSum(header))
		  Dim mb As New MemoryBlock(512)
		  mb.StringValue(0, header.Size) = header.StringValue(TargetLittleEndian)
		  mArchive.Write(mb)
		  mArchive.Position = mArchive.Length
		  Me.Pad()
		  mIndex = mIndex + 1
		  mDirty = True
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Close()
		  If mArchive <> Nil Then
		    If mDirty Then
		      Me.Flush
		      'Me.Flush
		      ''Me.Pad()
		      ''mArchive.Write(Encodings.ASCII.Chr(0))
		      'Me.Pad()
		      'mArchive.Write(Encodings.ASCII.Chr(0))
		      'Me.Pad()
		    End If
		    mArchive.Close
		    mArchive = Nil
		    mIndex = -1
		    mHeader.StringValue(TargetLittleEndian) = ""
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(TARStream As BinaryStream)
		  mArchive = TARStream
		  Me.Reset
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Create(TARFile As FolderItem, OverWrite As Boolean = False) As zlib.TapeArchive
		  Dim bs As BinaryStream
		  bs = BinaryStream.Create(TARFile, OverWrite)
		  Return New zlib.TapeArchive(bs)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CurrentIndex() As Integer
		  Return mIndex
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CurrentName() As String
		  If mIndex > -1 Then Return mHeader.Name.Trim
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CurrentSize() As Integer
		  If mIndex > -1 Then Return Val("&o" + mHeader.Length.Trim) Else Return -1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CurrentType() As zlib.TapeArchive.EntryType
		  If mIndex > -1 Then
		    Dim c As String = Encodings.ASCII.Chr(mHeader.TypeFlag)
		    Select Case c
		    Case "1"
		      Return EntryType(1)
		    Case "2"
		      Return EntryType(2)
		    Case "3"
		      Return EntryType(3)
		    Case "4"
		      Return EntryType(4)
		    Case "5"
		      Return EntryType(5)
		    Case "6"
		      Return EntryType(6)
		    Case "7"
		      Return EntryType(7)
		    End Select
		  End If
		  Return EntryType(0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  Me.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Flush()
		  'Dim header As FileHeader
		  'header.Name = ""
		  'header.Length = Oct(0)
		  'header.Checksum = Encodings.ASCII.Chr(32) + Encodings.ASCII.Chr(32) + Oct(GetCheckSum(header))
		  Me.Pad()
		  Dim mb As New MemoryBlock(1024)
		  'mb.StringValue(0, header.Size) = header.StringValue(TargetLittleEndian)
		  mArchive.Write(mb)
		  'Me.Pad()
		  
		  mArchive.Flush
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Shared Function GetCheckSum(TarHeader As FileHeader) As UInt32
		  Dim tmpmb As MemoryBlock = TarHeader.StringValue(TargetLittleEndian)
		  Dim chksum As UInt32
		  For i as Integer = 0 To 499
		    Try
		      If i = 148 Then
		        i = 156
		        chksum = chksum + UInt32(32 * 8) ' 8 spaces
		      End If
		      Dim b As UInt8 = tmpmb.UInt8Value(i)
		      chksum = chksum + b
		    Catch Err As OutOfBoundsException
		      Exit For
		    End Try
		  Next
		  Return chksum
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MoveNext(ExtractTo As FolderItem) As Boolean
		  Dim bs As BinaryStream
		  If ExtractTo <> Nil Then bs = BinaryStream.Open(ExtractTo, False)
		  Return Me.MoveNext(bs)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MoveNext(ExtractTo As Writeable = Nil) As Boolean
		  ' Advances to the next file in the archive. If there are no more files then this method returns False.
		  ' If ExtractTo is not Nil then the current file is written to that object *before* advancing.
		  
		  If ExtractTo <> Nil And mIndex > -1 Then
		    Dim sz As Integer = Val("&o" + mHeader.Length.Trim)
		    Dim blk As Integer = ((sz \ 512) * 512) + 512
		    Dim mb As MemoryBlock = mArchive.Read(blk)
		    ExtractTo.Write(mb.StringValue(0, sz))
		  ElseIf mIndex <> -1 Then
		    Dim sz As Integer = Val("&o" + mHeader.Length.Trim)
		    mArchive.Position = mArchive.Position + ((sz \ 512) * 512) + 512
		  End If
		  Dim lastpos As UInt64 = mArchive.Position
		  Dim mb As MemoryBlock = mArchive.Read(512)
		  Dim header As FileHeader
		  Try
		    #pragma BreakOnExceptions Off
		    header.StringValue(TargetLittleEndian) = mb.StringValue(0, header.Size)
		    #pragma BreakOnExceptions On
		    If header.Name.Trim = "" Then
		      mArchive.Position = lastpos
		      Return False
		    End If
		  Catch Err As OutOfBoundsException ' no more entries
		    mArchive.Position = lastpos
		    Return False
		  End Try
		  If ValidateChecksums And Not CurrentType = EntryType.Directory Then
		    Dim chksm As Integer = Val("&o" + header.Checksum.Trim)
		    Dim hsum As Integer = GetCheckSum(header)
		    If chksm <> hsum Then
		      Dim err As New IOException
		      err.Message = "Invalid header checksum for entry " + Str(mIndex + 1, "###,###,##0") + _
		      ". Expected '" + Oct(chksm) + "' but got '" + Oct(hsum) + "'."
		      Raise err
		    End If
		  End If
		  mHeader = header
		  mIndex = mIndex + 1
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Open(TARFile As FolderItem, ReadWrite As Boolean = True) As zlib.TapeArchive
		  Dim bs As BinaryStream = BinaryStream.Open(TARFile, ReadWrite)
		  If bs <> Nil Then Return New zlib.TapeArchive(bs)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Pad()
		  Dim sizetoadd As UInt64 = mArchive.Length Mod 512
		  If sizetoadd = 0 Then Return
		  sizetoadd = 512 - sizetoadd
		  Dim mb As New MemoryBlock(sizetoadd)
		  mArchive.Write(mb)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Reset(MoveToEnd As Boolean = False)
		  mArchive.Position = 0
		  mIndex = -1
		  Do Until Not Me.MoveNext()
		  Loop Until Not MoveToEnd
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mArchive As BinaryStream
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDirty As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mHeader As FileHeader
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mIndex As Integer = -1
	#tag EndProperty

	#tag Property, Flags = &h0
		ValidateChecksums As Boolean = True
	#tag EndProperty


	#tag Structure, Name = FileHeader, Flags = &h1
		Name As String*100
		  Mode As String*8
		  UID As String*8
		  GUID As String*8
		  Length As String*12
		  Time As String*12
		  Checksum As String*8
		  TypeFlag As Byte
		  LinkName As String*100
		  Magic As String*6
		  Version As String*2
		  uname As String*32
		  gname As String*32
		  devmajor As String*8
		  devminor As String*8
		Prefix As String*155
	#tag EndStructure


	#tag Enum, Name = EntryType, Type = Integer, Flags = &h0
		Normal=0
		  HardLink
		  SymLink
		  CharacterSpecial
		  BlockSpecial
		  Directory
		  FIFO
		Contiguous
	#tag EndEnum


	#tag ViewBehavior
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
