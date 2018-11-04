#tag Class
Private Class MappedStream
Implements Readable,Writeable
	#tag Method, Flags = &h0
		Sub Close()
		  If mStream <> Nil Then
		    Do Until LocksLock.TrySignal
		      App.YieldToNextThread
		    Loop
		    Try
		      Dim lock As Pair = StreamLocks.Value(mStream)
		      lock = lock.Left:lock.Right - 1
		      If lock.Right <= 0 Then StreamLocks.Remove(mStream)
		      If StreamLocks.Count = 0 Then StreamLocks = Nil
		    Finally
		      LocksLock.Release
		    End Try
		  End If
		  mStream = Nil
		  If StreamLocks = Nil Then LocksLock = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Source As BinaryStream, Offset As UInt64, Length As UInt64)
		  mStream = Source
		  mStartOffset = Offset
		  mLength = Length
		  If StreamLocks = Nil Then StreamLocks = New Dictionary
		  If LocksLock = Nil Then LocksLock = New Semaphore
		  Do Until LocksLock.TrySignal
		    App.YieldToNextThread
		  Loop
		  Try
		    Dim lock As Pair = StreamLocks.Lookup(Source, New Semaphore:0)
		    lock = lock.Left:lock.Right + 1
		    StreamLocks.Value(Source) = lock
		  Finally
		    LocksLock.Release
		  End Try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  Me.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EOF() As Boolean
		  // Part of the Readable interface.
		  Return Me.Position >= Me.Length Or mStream.EOF
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Flush()
		  // Part of the Writeable interface.
		  Do Until Me.Lock()
		    App.YieldToNextThread
		  Loop
		  Try
		    mStream.Flush
		  Finally
		    Me.Unlock
		  End Try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function Lock() As Boolean
		  Do Until LocksLock.TrySignal
		    App.YieldToNextThread
		  Loop
		  Dim p As Pair
		  Try
		    p = StreamLocks.Value(mStream)
		  Finally
		    LocksLock.Release
		  End Try
		  Dim l As Semaphore = p.Left
		  Return l.TrySignal
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  // Part of the Readable interface.
		  If mLastPosition + Count > mLength Then Count = mLength - mLastPosition
		  Me.Position = mLastPosition
		  Do Until Me.Lock()
		    App.YieldToNextThread
		  Loop
		  Dim s As String
		  Try
		    s = mStream.Read(Count, encoding)
		    mLastPosition = mStream.Position - mStartOffset
		  Finally
		    Me.Unlock
		  End Try
		  Return s
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadError() As Boolean
		  // Part of the Readable interface.
		  Return mStream.ReadError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Unlock()
		  Do Until LocksLock.TrySignal
		    App.YieldToNextThread
		  Loop
		  Dim p As Pair
		  Try
		    p = StreamLocks.Value(mStream)
		  Finally
		    LocksLock.Release
		  End Try
		  Dim l As Semaphore = p.Left
		  l.Release
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(text As String)
		  // Part of the Writeable interface.
		  Me.Position = mLastPosition
		  If Not AutoExtend And mLastPosition + text.LenB > mLength Then
		    text = LeftB(text, mLength - mLastPosition)
		  End If
		  Do Until Me.Lock()
		    App.YieldToNextThread
		  Loop
		  Try
		    mStream.Write(text)
		    mLastPosition = mStream.Position - mStartOffset
		  Finally
		    Me.Unlock
		  End Try
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function WriteError() As Boolean
		  // Part of the Writeable interface.
		  Return mStream.WriteError
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		AutoExtend As Boolean = True
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mLength
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  mLength = value
			End Set
		#tag EndSetter
		Length As UInt64
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private Shared LocksLock As Semaphore
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastPosition As UInt64
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLength As UInt64
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mStartOffset As UInt64
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mStream As BinaryStream
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mLastPosition
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If value > mLength Then value = mLength
			  Do Until Me.Lock()
			    App.YieldToNextThread
			  Loop
			  Try
			    mStream.Position = StartOffset + value
			  Finally
			    Me.Unlock
			  End Try
			  mLastPosition = value
			End Set
		#tag EndSetter
		Position As UInt64
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mStartOffset
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Dim diff As UInt64 = mStartOffset - value
			  mLastPosition = mLastPosition + diff
			  mStartOffset = value
			End Set
		#tag EndSetter
		StartOffset As UInt64
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private Shared StreamLocks As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h0
		Tag As Variant
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="AutoExtend"
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
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
	#tag EndViewBehavior
End Class
#tag EndClass
