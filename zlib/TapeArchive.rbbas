#tag Class
Protected Class TapeArchive
	#tag Method, Flags = &h0
		Function AppendFile(File As FolderItem) As Boolean
		  Dim header As FileHeader
		  header.Name = File.Name
		  header.Length = Oct(File.Length)
		  header.Checksum = Encodings.ASCII.Chr(32) + Encodings.ASCII.Chr(32) + Oct(GetCheckSum(header))
		  Me.Reset
		  While Me.MoveNext()
		    App.YieldToNextThread
		  Wend
		  Me.Pad()
		  Dim mb As New MemoryBlock(512)
		  mb.StringValue(0, header.Size) = header.StringValue(TargetLittleEndian)
		  mArchive.Write(mb)
		  Dim bs As BinaryStream = BinaryStream.Open(File)
		  Dim sz As Integer = bs.Length
		  mArchive.Write(bs.Read(sz))
		  bs.Close
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
		      'Me.Pad()
		      'mArchive.Write(Encodings.ASCII.Chr(0))
		      Me.Pad()
		      mArchive.Write(Encodings.ASCII.Chr(0))
		      Me.Pad()
		    End If
		    mArchive.Close
		    mArchive = Nil
		    mIndex = -1
		    mHeader.StringValue(TargetLittleEndian) = ""
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(TARFile As FolderItem)
		  mArchiveFile = TARFile
		  If mArchiveFile.Exists Then
		    mArchive = BinaryStream.Open(mArchiveFile, True)
		    Me.Reset()
		  Else
		    mArchive = BinaryStream.Create(mArchiveFile, True)
		  End If
		  
		End Sub
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

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  Me.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Flush()
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
		        chksum = chksum + UInt32(32 * 8) ' spaces
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
		Function MoveNext(ExtractTo As Writeable = Nil) As Boolean
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
		  If Val("&o" + header.Checksum.Trim) <> GetCheckSum(header) Then 
		    Raise New IOException
		  End If
		  mHeader = header
		  mIndex = mIndex + 1
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Pad()
		  Dim sizetoadd As UInt64 = 512 - (mArchive.Length Mod 512)
		  If sizetoadd <= 0 Then Return
		  Dim pos As UInt64 = mArchive.Position
		  Dim len As UInt64 = mArchive.Length
		  mArchive.Position = len
		  For i As Integer = 0 To sizetoadd
		    mArchive.Write(Encodings.ASCII.Chr(0))
		  Next
		  mArchive.Position = pos
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Reset()
		  mArchive.Position = 0
		  mIndex = -1
		  Call MoveNext()
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mArchive As BinaryStream
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mArchiveFile As FolderItem
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
	#tag EndViewBehavior
End Class
#tag EndClass
