#tag Window
Begin Window DemoWindow
   BackColor       =   &hFFFFFF
   Backdrop        =   ""
   CloseButton     =   True
   Composite       =   False
   Frame           =   0
   FullScreen      =   False
   HasBackColor    =   False
   Height          =   9.8e+1
   ImplicitInstance=   True
   LiveResize      =   True
   MacProcID       =   0
   MaxHeight       =   32000
   MaximizeButton  =   False
   MaxWidth        =   32000
   MenuBar         =   ""
   MenuBarVisible  =   True
   MinHeight       =   64
   MinimizeButton  =   True
   MinWidth        =   64
   Placement       =   2
   Resizeable      =   True
   Title           =   "zlib Demo"
   Visible         =   True
   Width           =   3.55e+2
   Begin PushButton GZipFileBtn
      AutoDeactivate  =   True
      Bold            =   ""
      ButtonStyle     =   0
      Cancel          =   ""
      Caption         =   "GZip a file"
      Default         =   ""
      Enabled         =   True
      Height          =   22
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   ""
      Left            =   20
      LockBottom      =   ""
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   ""
      LockTop         =   True
      Scope           =   0
      TabIndex        =   0
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0
      TextUnit        =   0
      Top             =   14
      Underline       =   ""
      Visible         =   True
      Width           =   97
   End
   Begin PushButton DeflateFileBtn
      AutoDeactivate  =   True
      Bold            =   ""
      ButtonStyle     =   0
      Cancel          =   ""
      Caption         =   "DEFLATE a file"
      Default         =   ""
      Enabled         =   True
      Height          =   22
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   ""
      Left            =   20
      LockBottom      =   ""
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   ""
      LockTop         =   True
      Scope           =   0
      TabIndex        =   1
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0
      TextUnit        =   0
      Top             =   37
      Underline       =   ""
      Visible         =   True
      Width           =   97
   End
   Begin CheckBox UseRawChkBx
      AutoDeactivate  =   True
      Bold            =   ""
      Caption         =   "Raw DEFLATE"
      DataField       =   ""
      DataSource      =   ""
      Enabled         =   True
      Height          =   20
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   ""
      Left            =   20
      LockBottom      =   ""
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   ""
      LockTop         =   True
      Scope           =   0
      State           =   0
      TabIndex        =   2
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0
      TextUnit        =   0
      Top             =   58
      Underline       =   ""
      Value           =   False
      Visible         =   True
      Width           =   100
   End
   Begin PushButton GUnZipFileBtn
      AutoDeactivate  =   True
      Bold            =   ""
      ButtonStyle     =   0
      Cancel          =   ""
      Caption         =   "GUnZip a file"
      Default         =   ""
      Enabled         =   True
      Height          =   22
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   ""
      Left            =   129
      LockBottom      =   ""
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   ""
      LockTop         =   True
      Scope           =   0
      TabIndex        =   3
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0
      TextUnit        =   0
      Top             =   14
      Underline       =   ""
      Visible         =   True
      Width           =   97
   End
   Begin PushButton InflateFileBtn
      AutoDeactivate  =   True
      Bold            =   ""
      ButtonStyle     =   0
      Cancel          =   ""
      Caption         =   "INFLATE a file"
      Default         =   ""
      Enabled         =   True
      Height          =   22
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   ""
      Left            =   129
      LockBottom      =   ""
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   ""
      LockTop         =   True
      Scope           =   0
      TabIndex        =   4
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0
      TextUnit        =   0
      Top             =   37
      Underline       =   ""
      Visible         =   True
      Width           =   97
   End
   Begin CheckBox UseRawChkBx1
      AutoDeactivate  =   True
      Bold            =   ""
      Caption         =   "Raw INFLATE"
      DataField       =   ""
      DataSource      =   ""
      Enabled         =   True
      Height          =   20
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   ""
      Left            =   129
      LockBottom      =   ""
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   ""
      LockTop         =   True
      Scope           =   0
      State           =   0
      TabIndex        =   5
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0
      TextUnit        =   0
      Top             =   58
      Underline       =   ""
      Value           =   False
      Visible         =   True
      Width           =   100
   End
   Begin PushButton ZipDirBtn
      AutoDeactivate  =   True
      Bold            =   ""
      ButtonStyle     =   0
      Cancel          =   ""
      Caption         =   "Zip a folder"
      Default         =   ""
      Enabled         =   True
      Height          =   22
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   ""
      Left            =   238
      LockBottom      =   ""
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   ""
      LockTop         =   True
      Scope           =   0
      TabIndex        =   6
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0
      TextUnit        =   0
      Top             =   14
      Underline       =   ""
      Visible         =   True
      Width           =   97
   End
   Begin PushButton UnzipFileBtn
      AutoDeactivate  =   True
      Bold            =   ""
      ButtonStyle     =   0
      Cancel          =   ""
      Caption         =   "Unzip a file"
      Default         =   ""
      Enabled         =   True
      Height          =   22
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   ""
      Left            =   238
      LockBottom      =   ""
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   ""
      LockTop         =   True
      Scope           =   0
      TabIndex        =   7
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0
      TextUnit        =   0
      Top             =   37
      Underline       =   ""
      Visible         =   True
      Width           =   97
   End
End
#tag EndWindow

#tag WindowCode
#tag EndWindowCode

#tag Events GZipFileBtn
	#tag Event
		Sub Action()
		  Dim source As FolderItem = GetOpenFolderItem("")
		  If source = Nil Then Return
		  Dim destination As FolderItem = GetSaveFolderItem(FileTypes1.ApplicationXGzip, source.Name + ".gz")
		  If destination = Nil Then Return
		  If Not zlib.GZip(source, destination) Then Call MsgBox("Whoops", 16, "Error!") Else MsgBox("Success!")
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events DeflateFileBtn
	#tag Event
		Sub Action()
		  Dim source As FolderItem = GetOpenFolderItem("")
		  If source = Nil Then Return
		  Dim destination As FolderItem = GetSaveFolderItem(FileTypes1.ApplicationXCompress, source.Name + ".z")
		  If destination = Nil Then Return
		  Dim encoding As Integer
		  If UseRawChkBx.Value Then
		    encoding = zlib.RAW_ENCODING
		  Else
		    encoding = zlib.DEFLATE_ENCODING
		  End If
		  If Not zlib.Deflate(source, destination, zlib.Z_DEFAULT_COMPRESSION, False, encoding) Then Call MsgBox("Whoops", 16, "Error!") Else MsgBox("Success!")
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events GUnZipFileBtn
	#tag Event
		Sub Action()
		  Dim source As FolderItem = GetOpenFolderItem(FileTypes1.ApplicationXGzip)
		  If source = Nil Then Return
		  Dim name As String = source.Name
		  If Right(name, 3) = ".gz" Then name = Left(name, name.Len - 3)
		  Dim destination As FolderItem = GetSaveFolderItem("", name)
		  If destination = Nil Then Return
		  If Not zlib.GUnZip(source, destination) Then Call MsgBox("Whoops", 16, "Error!") Else MsgBox("Success!")
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events InflateFileBtn
	#tag Event
		Sub Action()
		  Dim source As FolderItem = GetOpenFolderItem("")
		  If source = Nil Then Return
		  Dim name As String = source.Name
		  If Right(name, 2) = ".z" Then name = Left(name, name.Len - 2)
		  Dim destination As FolderItem = GetSaveFolderItem("", name)
		  If destination = Nil Then Return
		  Dim encoding As Integer
		  If UseRawChkBx1.Value Then
		    encoding = zlib.RAW_ENCODING
		  Else
		    encoding = zlib.DEFLATE_ENCODING
		  End If
		  If Not zlib.Inflate(source, destination, False, Nil, encoding) Then Call MsgBox("Whoops", 16, "Error!") Else MsgBox("Success!")
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events ZipDirBtn
	#tag Event
		Sub Action()
		  Dim source As FolderItem = SelectFolder()
		  If source = Nil Then Return
		  Dim destination As FolderItem = GetSaveFolderItem(FileTypes1.ApplicationZip, source.Name + ".zip")
		  If destination = Nil Then Return
		  If Not zlib.WriteZip(source, destination) Then Call MsgBox("Whoops", 16, "Error!") Else MsgBox("Success!")
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events UnzipFileBtn
	#tag Event
		Sub Action()
		  Dim source As FolderItem = GetOpenFolderItem(FileTypes1.ApplicationZip)
		  If source = Nil Then Return
		  Dim destination As FolderItem = SelectFolder()
		  If destination = Nil Then Return
		  If destination.Count <> 0 And MsgBox("The target directory is not empty. Proceed with extraction?", 4 + 48, "Destination is not empty") <> 6 Then Return
		  Dim extracted() As FolderItem = zlib.ReadZip(source, destination)
		  If UBound(extracted) = -1 And source.Length <> 22 Then
		    Call MsgBox("Whoops", 16, "Error!")
		  Else
		    MsgBox("Extracted " + Format(UBound(extracted) + 1, "###,##0") + " items to " + destination.AbsolutePath)
		  End If
		  
		End Sub
	#tag EndEvent
#tag EndEvents
