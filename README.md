##Introduction
**RB-zlib** is a [zlib](http://www.zlib.net/) [binding](http://en.wikipedia.org/wiki/Language_binding) for Realbasic and Xojo projects. It is designed and tested on Windows 7. 

##Examples
This example compresses and decompresses a string in memory:
```vbnet
 Dim compressed As String = zlib.Compress("InputData")
 Dim decompressed As String = zlib.Uncompress(compressed)
```

This example creates gzips a file:

```vbnet
  Dim f As FolderItem = GetSaveFolderItem("") ' a file to be gzipped
  If f <> Nil Then
    Dim bs As BinaryStream = BinaryStream.Open(f)
    Dim gz As zlib.GZStream = zlib.GZStream.Create(f.Parent.Child(f.Name + ".gz"))
    gz.Level = 9 ' set the compression level as desired
    While Not bs.EOF
      gz.Write(bs.Read(1024))
    Wend
    bs.Close
    gz.Close
  End If
```

This example opens an existing gzip file and decompresses it into a `MemoryBlock`:
```vbnet
  Dim f As FolderItem = GetOpenFolderItem("") ' the gzip file to open
  If f <> Nil Then
    Dim gz As zlib.GZStream = zlib.GZStream.Open(f)
    Dim uncompressed As New MemoryBlock(0)
    Dim bs As BinaryStream = New BinaryStream(uncompressed)
    While Not gz.EOF
      bs.Write(gz.Read(1024))
    Wend
    bs.Close
    gz.Close
  End If
```
