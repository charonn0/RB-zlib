##Introduction
**RB-zlib** is a [zlib](http://www.zlib.net/) [binding](http://en.wikipedia.org/wiki/Language_binding) for Realbasic and Xojo projects. It is designed and tested on Windows 7. RB-zlib can compress and decompress file and memory streams using any combination of options and compression format. In addition, support for [zip](https://github.com/charonn0/RB-zlib/wiki/zlib.ZipArchive) and [TAR](https://github.com/charonn0/RB-zlib/wiki/zlib.TapeArchive) archives is available.

###Compression formats
zlib offers three compression formats: DEFLATE, which is a deflate-compressed stream with headers; RAW which is a deflate-compressed stream without headers; and GZIP, which is a deflate-compressed stream with gzip-stye headers.

###Utility methods
This project provides several different ways to use zlib. The easiest are the utility methods in the zlib module: 

* [**`Inflate`**](https://github.com/charonn0/RB-zlib/wiki/zlib.Inflate)
* [**`Deflate`**](https://github.com/charonn0/RB-zlib/wiki/zlib.Deflate)
* [**`GZip`**](https://github.com/charonn0/RB-zlib/wiki/zlib.GZip)
* [**`GUnZip`**](https://github.com/charonn0/RB-zlib/wiki/zlib.GUnZip)

All of these methods are overloaded with several useful variations on input and output parameters. All variations follow either this signature:

```vbnet
 function(source, destination, options[...]) As Boolean
```
or this signature:
```vbnet
 function(source, options[...]) As MemoryBlock
```

where `source` is a `MemoryBlock`, `FolderItem`, or an object which implements the `Readable` interface; and `destination` (when provided) is a `FolderItem` or an object which implements the `Writeable` interface. Methods which do not have a `Destination` parameter return output as a `MemoryBlock` instead.

Additional optional arguments may be passed, to control the compression level, strategy, dictionary, and encoding. For example, `GZip` and `GUnZip` are just wrappers around `Deflate` and `Inflate` with options that specify the gzip format.

###ZStream class
The other way to use zlib is with the [`ZStream`](https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream) class. The `ZStream` is a `BinaryStream` work-alike, and implements both the `Readable` and `Writeable` interfaces. Anything [written](https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Write) to a `ZStream` is compressed and emitted to the output stream (another `Writeable`); [reading](https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Read) from a `ZStream` decompresses data from the input stream (another `Readable`).

Instances of `ZStream` can be created from MemoryBlocks, FolderItems, and objects that implement the `Readable` and/or `Writeable` interfaces. For example, creating an in-memory compression stream from a zero-length MemoryBlock and writing a string to it:

```vbnet
  Dim output As New MemoryBlock(0)
  Dim z As New zlib.ZStream(output) ' zero-length creates a compressor
  z.Write("Hello, world!")
  z.Close
```
The string will be processed through the compressor and written to the `output` MemoryBlock. To create a decompressor pass a MemoryBlock whose size is > 0 (continuing from above):

```vbnet
  z = New zlib.ZStream(output) ' output contains the compressed string
  MsgBox(z.ReadAll) ' read the decompressed string
```

##More examples
This example compresses and decompresses a MemoryBlock using deflate compression:
```vbnet
  Dim data As MemoryBlock = "Potentially very large MemoryBlock goes here!"
  Dim comp As MemoryBlock = zlib.Deflate(data)
  Dim dcmp As MemoryBlock = zlib.Inflate(comp)
```

This example compresses and decompresses a MemoryBlock using GZip:
```vbnet
  Dim data As MemoryBlock = "Potentially very large MemoryBlock goes here!"
  Dim comp As MemoryBlock = zlib.GZip(data)
  Dim dcmp As MemoryBlock = zlib.GUnZip(comp)
```

This example gzips a file:

```vbnet
  Dim src As FolderItem = GetOpenFolderItem("") ' a file to be gzipped
  Dim dst As FolderItem = src.Parent.Child(src.Name + ".gz")
  If zlib.GZip(src, dst) Then 
    MsgBox("Compression succeeded!")
  Else
    MsgBox("Compression failed!")
  End If
```

This example opens an existing gzip file and decompresses it into a `MemoryBlock`:
```vbnet
  Dim f As FolderItem = GetOpenFolderItem("") ' the gzip file to open
  Dim data As MemoryBlock = zlib.GUnZip(f)
  If data <> Nil Then
    MsgBox("Decompression succeeded!")
  Else
    MsgBox("Decompression failed!")
  End If
```

This example extracts a zip archive into a directory:
```vbnet
  Dim src As FolderItem = GetOpenFolderItem("") ' a zip file to extract
  Dim dst As FolderItem = SelectFolder() ' the destination directory
  Dim extracted() As FolderItem ' the list of extracted files/folders
  extracted = zlib.ReadZip(src, dst)
```
