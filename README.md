##Introduction
**RB-zlib** is a zlib [binding](http://en.wikipedia.org/wiki/Language_binding) for Realbasic and Xojo projects. It is designed and tested using Realstudio 2011r4.3 on Windows 7. 

[zlib](http://www.zlib.net/) is the reference implementation for the [deflate](https://en.wikipedia.org/wiki/DEFLATE) compression algorithm. Deflate is the algorithm used by the gzip container format, the the zip archive format, and HTTP compression.

##Hilights
* Read and write compressed file or memory streams using a simple [BinaryStream work-alike](https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream).
* Read and write [tape archive](https://github.com/charonn0/RB-zlib/wiki/zlib.TapeArchive) (.tar) files 
* Read and write [gzip](https://github.com/charonn0/RB-zlib/wiki/zlib.GZStream) (.gz) files with seek/rewind
* Read [zip archives](https://github.com/charonn0/RB-zlib/wiki/zlib.ZipArchive) (.zip)
* Supports gzip, deflate, and raw deflate compressed streams

##Getting started
This project provides several different ways to use zlib. 

###Utility methods
The easiest way to use this project are the utility methods in the zlib module: 

* [**`Deflate`**](https://github.com/charonn0/RB-zlib/wiki/zlib.Deflate)
* [**`Inflate`**](https://github.com/charonn0/RB-zlib/wiki/zlib.Inflate)
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

where `source` is a `MemoryBlock`, `FolderItem`, or an object which implements the `Readable` interface; and `destination` (when provided) is a `FolderItem` or an object which implements the `Writeable` interface. Methods which do not have a `Destination` parameter return output as a `MemoryBlock` instead. Refer to the [examples](https://github.com/charonn0/RB-zlib/wiki#more-examples) below for demonstrations of some of these functions.

Additional optional arguments may be passed, to control the compression level, strategy, dictionary, and encoding. For example, `GZip` and `GUnZip` are just wrappers around `Deflate` and `Inflate` with options that specify the gzip format.

###ZStream class
The second way to use zlib is with the [`ZStream`](https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream) class. The `ZStream` is a `BinaryStream` work-alike, and implements both the `Readable` and `Writeable` interfaces. Anything [written](https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Write) to a `ZStream` is compressed and emitted to the output stream (another `Writeable`); [reading](https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Read) from a `ZStream` decompresses data from the input stream (another `Readable`).

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

###Inflater and Deflater classes
The third and final way to use this project is through the [Inflater](https://github.com/charonn0/RB-zlib/wiki/zlib.Inflater) and [Deflater](https://github.com/charonn0/RB-zlib/wiki/zlib.Deflater) classes. These classes provide a low-level wrapper to the zlib API. All compression and decompression done using the `ZStream` class or the utility methods is ultimately carried out by an instance of `Deflater` and `Inflater`, respectively.

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

This example performs an HTTP request that asks for compression, and decompresses the response:

```vbnet
  Dim h As New HTTPSocket
  h.SetRequestHeader("Accept-Encoding", "gzip, deflate")
  Dim page As String = h.Get("http://www.example.com", 10)
  If h.PageHeaders.CommaSeparatedValues("Content-Encoding") = "gzip" Then
    page = zlib.GUnZip(page)
  ElseIf h.PageHeaders.CommaSeparatedValues("Content-Encoding") = "deflate" Then
    page = zlib.Inflate(page) ' assume DEFLATE_ENCODING; some servers send RAW_ENCODING
  End If
```

##How to incorporate zlib into your Realbasic/Xojo project
###Import the `zlib` module
1. Download the RB-zlib project either in [ZIP archive format](https://github.com/charonn0/RB-zlib/archive/master.zip) or by cloning the repository with your Git client.
2. Open the RB-zlib project in REALstudio or Xojo. Open your project in a separate window.
3. Copy the `zlib` module into your project and save.

###Ensure the zlib shared library is installed
zlib is installed by default on most Unix-like operating systems, including OS X and most Linux distributions. 

Windows does not have it installed by default, you will need to ship the DLL with your application. You can use pre-built DLL available [here](http://zlib.net/zlib128-dll.zip) (Win32x86), or you can [build them yourself from source](http://zlib.net/zlib-1.2.8.tar.gz). 

RB-zlib will raise a PlatformNotSupportedException when used if all required DLLs/SOs/DyLibs are not available at runtime. 
