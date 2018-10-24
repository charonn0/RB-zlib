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
      Top             =   37
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
      TabIndex        =   5
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
   Begin CheckBox UseBZip2ChkBx
      AutoDeactivate  =   True
      Bold            =   ""
      Caption         =   "Use BZip2"
      DataField       =   ""
      DataSource      =   ""
      Enabled         =   True
      Height          =   20
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   ""
      Left            =   238
      LockBottom      =   ""
      LockedInPosition=   False
      LockLeft        =   ""
      LockRight       =   ""
      LockTop         =   ""
      Scope           =   0
      State           =   0
      TabIndex        =   7
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0
      TextUnit        =   0
      Top             =   58
      Underline       =   ""
      Visible         =   True
      Width           =   100
   End
   Begin Timer CompletionTimer
      Height          =   32
      Index           =   -2147483648
      Left            =   -48
      LockedInPosition=   False
      Mode            =   0
      Period          =   1
      Scope           =   0
      TabPanelIndex   =   0
      Top             =   -14
      Width           =   32
   End
   Begin PushButton ZipRepairBtn
      AutoDeactivate  =   True
      Bold            =   ""
      ButtonStyle     =   0
      Cancel          =   ""
      Caption         =   "Repair zip"
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
      TabIndex        =   7
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0
      TextUnit        =   0
      Top             =   59
      Underline       =   ""
      Visible         =   True
      Width           =   97
   End
End
#tag EndWindow

#tag WindowCode
	#tag Event
		Function CancelClose(appQuitting as Boolean) As Boolean
		  #pragma Unused appQuitting
		  If mWorker <> Nil And mWorker.State <> Thread.NotRunning Then
		    If MsgBox("Would you like to cancel the current operation?", 4 + 32, "Operation incomplete") <> 6 Then Return True
		    mWorker.Kill
		    mWorker = Nil
		  End If
		End Function
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Sub RunDeflate(Sender As Thread)
		  #pragma Unused Sender
		  Dim encoding As Integer
		  If mOption Then
		    encoding = zlib.RAW_ENCODING
		  Else
		    encoding = zlib.DEFLATE_ENCODING
		  End If
		  mResult = zlib.Deflate(mSource, mDestination, zlib.Z_DEFAULT_COMPRESSION, False, encoding)
		  CompletionTimer.Mode = Timer.ModeSingle
		  
		Exception err As zlib.zlibException
		  mResult = False
		  mErrorCode = err.ErrorNumber
		  mErrorMsg = err.Message
		  CompletionTimer.Mode = Timer.ModeSingle
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RunGUnZip(Sender As Thread)
		  #pragma Unused Sender
		  mResult = zlib.GUnZip(mSource, mDestination)
		  CompletionTimer.Mode = Timer.ModeSingle
		  
		Exception err As zlib.zlibException
		  mResult = False
		  mErrorCode = err.ErrorNumber
		  mErrorMsg = err.Message
		  CompletionTimer.Mode = Timer.ModeSingle
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RunGZip(Sender As Thread)
		  #pragma Unused Sender
		  mResult = zlib.GZip(mSource, mDestination)
		  CompletionTimer.Mode = Timer.ModeSingle
		  
		Exception err As zlib.zlibException
		  mResult = False
		  mErrorCode = err.ErrorNumber
		  mErrorMsg = err.Message
		  CompletionTimer.Mode = Timer.ModeSingle
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RunInflate(Sender As Thread)
		  #pragma Unused Sender
		  Dim encoding As UInt32
		  If mOption Then
		    encoding = zlib.RAW_ENCODING
		  Else
		    encoding = zlib.DEFLATE_ENCODING
		  End If
		  mResult = zlib.Inflate(mSource, mDestination, False, Nil, encoding)
		  CompletionTimer.Mode = Timer.ModeSingle
		  
		Exception err As zlib.zlibException
		  mResult = False
		  mErrorCode = err.ErrorNumber
		  mErrorMsg = err.Message
		  CompletionTimer.Mode = Timer.ModeSingle
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RunUnZip(Sender As Thread)
		  #pragma Unused Sender
		  mUnzipped = PKZip.ReadZip(mSource, mDestination)
		  mResult = UBound(mUnzipped) > -1 Or mSource.Length = 22
		  CompletionTimer.Mode = Timer.ModeSingle
		  
		Exception err As zlib.zlibException
		  mResult = False
		  mErrorCode = err.ErrorNumber
		  mErrorMsg = err.Message
		  CompletionTimer.Mode = Timer.ModeSingle
		  
		Exception err As BZip2.BZip2Exception
		  mResult = False
		  mErrorCode = err.ErrorNumber
		  mErrorMsg = err.Message
		  CompletionTimer.Mode = Timer.ModeSingle
		  
		Exception err As PKZip.ZipException
		  mResult = False
		  mErrorCode = err.ErrorNumber
		  mErrorMsg = err.Message
		  CompletionTimer.Mode = Timer.ModeSingle
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RunZip(Sender As Thread)
		  #pragma Unused Sender
		  If Not mOption Then
		    mResult = PKZip.WriteZip(mSource, mDestination)
		  Else
		    mResult = PKZip.WriteZip(mSource, mDestination, False, BZip2.BZ_DEFAULT_COMPRESSION, PKZip.METHOD_BZIP2)
		  End If
		  CompletionTimer.Mode = Timer.ModeSingle
		  
		Exception err As zlib.zlibException
		  mResult = False
		  mErrorCode = err.ErrorNumber
		  mErrorMsg = err.Message
		  CompletionTimer.Mode = Timer.ModeSingle
		  
		Exception err As BZip2.BZip2Exception
		  mResult = False
		  mErrorCode = err.ErrorNumber
		  mErrorMsg = err.Message
		  CompletionTimer.Mode = Timer.ModeSingle
		Exception err As PKZip.ZipException
		  mResult = False
		  mErrorCode = err.ErrorNumber
		  mErrorMsg = err.Message
		  CompletionTimer.Mode = Timer.ModeSingle
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RunZipRepair(Sender As Thread)
		  #pragma Unused Sender
		  mResult = PKZip.RepairZip(mSource, mDestination, SpecialFolder.Desktop.Child(mSource.Name + "_repair_log.txt"))
		  CompletionTimer.Mode = Timer.ModeSingle
		  
		Exception err As zlib.zlibException
		  mResult = False
		  mErrorCode = err.ErrorNumber
		  mErrorMsg = err.Message
		  CompletionTimer.Mode = Timer.ModeSingle
		  
		Exception err As BZip2.BZip2Exception
		  mResult = False
		  mErrorCode = err.ErrorNumber
		  mErrorMsg = err.Message
		  CompletionTimer.Mode = Timer.ModeSingle
		  
		Exception err As PKZip.ZipException
		  mResult = False
		  mErrorCode = err.ErrorNumber
		  mErrorMsg = err.Message
		  CompletionTimer.Mode = Timer.ModeSingle
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mDestination As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mErrorCode As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mErrorMsg As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mOption As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mResult As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSource As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mUnzipped() As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mWorker As Thread
	#tag EndProperty


#tag EndWindowCode

#tag Events GZipFileBtn
	#tag Event
		Sub Action()
		  If mWorker <> Nil Then Return
		  mSource = GetOpenFolderItem("")
		  If mSource = Nil Then Return
		  mDestination = GetSaveFolderItem(FileTypes1.ApplicationXGzip, mSource.Name + ".gz")
		  If mDestination = Nil Then Return
		  Self.Title = "zlib Demo - GZipping..."
		  mWorker = New Thread
		  AddHandler mWorker.Run, WeakAddressOf RunGZip
		  mWorker.Run
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events DeflateFileBtn
	#tag Event
		Sub Action()
		  If mWorker <> Nil Then Return
		  mSource = GetOpenFolderItem("")
		  If mSource = Nil Then Return
		  mDestination = GetSaveFolderItem(FileTypes1.ApplicationXCompress, mSource.Name + ".z")
		  If mDestination = Nil Then Return
		  mOption = UseRawChkBx.Value
		  Self.Title = "zlib Demo - Deflating..."
		  mWorker = New Thread
		  AddHandler mWorker.Run, WeakAddressOf RunDeflate
		  mWorker.Run
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events GUnZipFileBtn
	#tag Event
		Sub Action()
		  If mWorker <> Nil Then Return
		  mSource = GetOpenFolderItem(FileTypes1.ApplicationXGzip)
		  If mSource = Nil Then Return
		  Dim name As String = mSource.Name
		  If Right(name, 3) = ".gz" Then name = Left(name, name.Len - 3)
		  mDestination = GetSaveFolderItem("", name)
		  If mDestination = Nil Then Return
		  Self.Title = "zlib Demo - GUnZipping..."
		  mWorker = New Thread
		  AddHandler mWorker.Run, WeakAddressOf RunGUnZip
		  mWorker.Run
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events InflateFileBtn
	#tag Event
		Sub Action()
		  If mWorker <> Nil Then Return
		  mSource = GetOpenFolderItem("")
		  If mSource = Nil Then Return
		  Dim name As String = mSource.Name
		  If Right(name, 2) = ".z" Then name = Left(name, name.Len - 2)
		  mDestination = GetSaveFolderItem("", name)
		  If mDestination = Nil Then Return
		  mOption = UseRawChkBx.Value
		  Self.Title = "zlib Demo - Inflating..."
		  mWorker = New Thread
		  AddHandler mWorker.Run, WeakAddressOf RunInflate
		  mWorker.Run
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events ZipDirBtn
	#tag Event
		Sub Action()
		  If mWorker <> Nil Then Return
		  mSource = SelectFolder()
		  If mSource = Nil Then Return
		  mDestination = GetSaveFolderItem(FileTypes1.ApplicationZip, mSource.Name + ".zip")
		  If mDestination = Nil Then Return
		  Self.Title = "zlib Demo - Zipping..."
		  mOption = UseBZip2ChkBx.Value
		  mWorker = New Thread
		  AddHandler mWorker.Run, WeakAddressOf RunZip
		  mWorker.Run
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events UnzipFileBtn
	#tag Event
		Sub Action()
		  If mWorker <> Nil Then Return
		  mSource = GetOpenFolderItem(FileTypes1.ApplicationZip)
		  If mSource = Nil Then Return
		  mDestination = SelectFolder()
		  If mDestination = Nil Then Return
		  If mDestination.Count <> 0 And MsgBox("The target directory is not empty. Proceed with extraction?", 4 + 48, "Destination is not empty") <> 6 Then Return
		  Self.Title = "zlib Demo - Unzipping..."
		  mWorker = New Thread
		  AddHandler mWorker.Run, WeakAddressOf RunUnzip
		  mWorker.Run
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events UseBZip2ChkBx
	#tag Event
		Sub Open()
		  Me.Enabled = BZip2.IsAvailable
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events CompletionTimer
	#tag Event
		Sub Action()
		  If UBound(mUnzipped) = -1 Then
		    If Not mResult Then Call MsgBox("Error number " + Str(mErrorCode) + ": " + mErrorMsg, 16, "Error") Else MsgBox("Success!")
		    
		  Else
		    MsgBox("Extracted " + Format(UBound(mUnzipped) + 1, "###,##0") + " items to " + mDestination.AbsolutePath)
		  End If
		  mWorker = Nil
		  ReDim mUnzipped(-1)
		  Self.Title = "zlib Demo"
		  mErrorCode = 0
		  mErrorMsg = ""
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events ZipRepairBtn
	#tag Event
		Sub Action()
		  If mWorker <> Nil Then Return
		  mSource = GetOpenFolderItem(FileTypes1.ApplicationZip)
		  If mSource = Nil Then Return
		  mDestination = GetSaveFolderItem(FileTypes1.ApplicationZip, mSource.Name + "_repared.zip")
		  If mDestination = Nil Then Return
		  Self.Title = "zlib Demo - Repairing..."
		  mWorker = New Thread
		  AddHandler mWorker.Run, WeakAddressOf RunZipRepair
		  mWorker.Run
		End Sub
	#tag EndEvent
#tag EndEvents
