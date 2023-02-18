## Introduction
[zlib](http://www.zlib.net/) is the reference implementation for the [deflate](https://en.wikipedia.org/wiki/DEFLATE) compression algorithm. Deflate is the algorithm used by the [gzip](https://tools.ietf.org/html/rfc1952) container format, the [zip](https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT) archive format, and [HTTP compression](https://tools.ietf.org/html/rfc7694).

**RB-zlib** is a zlib [binding](http://en.wikipedia.org/wiki/Language_binding) for Realbasic and Xojo projects.

The minimum supported zlib version is 1.2.8. The minimum supported Xojo version is RS2009R3. 

## Highlights
* Read and write compressed file or memory streams using a simple [BinaryStream work-alike](https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream).
* [Read](https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipReader) and [write](https://github.com/charonn0/RB-zlib/wiki/PKZip.ZipWriter) zip archives (.zip)
* [Read](https://github.com/charonn0/RB-zlib/wiki/USTAR.TarReader) and [write](https://github.com/charonn0/RB-zlib/wiki/USTAR.TarWriter) tape archives (.tar), with or without gzip compression.
* Supports gzip, deflate, and raw deflate compressed streams
* Supports Windows, Linux, and OS X.
* 64-bit ready.

## Getting started
The following section covers using zlib for general purpose compression. Refer to the [PKZip](https://github.com/charonn0/RB-zlib/wiki/PKZip) and [USTAR](https://github.com/charonn0/RB-zlib/wiki/USTAR) modules for information on working with archives.

### Utility methods
The zlib module provides several utility methods for basic compression or decompression of data:

* [**`Deflate`**](https://github.com/charonn0/RB-zlib/wiki/zlib.Deflate)
* [**`Inflate`**](https://github.com/charonn0/RB-zlib/wiki/zlib.Inflate)
* [**`GZip`**](https://github.com/charonn0/RB-zlib/wiki/zlib.GZip)
* [**`GUnZip`**](https://github.com/charonn0/RB-zlib/wiki/zlib.GUnZip)

All of these methods are overloaded with several useful variations on input and output parameters. All variations follow either this signature:

```realbasic
 function(source, destination, options[...]) As Boolean
```
or this signature:
```realbasic
 function(source, options[...]) As MemoryBlock
```

where `source` is a `MemoryBlock`, `FolderItem`, or an object which implements the `Readable` interface; and `destination` (when provided) is a `FolderItem` or an object which implements the `Writeable` interface. Methods that do not have a `Destination` parameter return output as a `MemoryBlock` instead. Refer to the [examples](https://github.com/charonn0/RB-zlib/wiki#more-examples) below for demonstrations of some of these functions.

Additional optional arguments may be passed, to control the compression level, strategy, dictionary, and encoding. For example, `GZip` and `GUnZip` are just wrappers around `Deflate` and `Inflate` with options that specify the gzip format.

### ZStream class
The second way to compress or decompress data is with the [`ZStream`](https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream) class. The `ZStream` is a `BinaryStream` work-alike and implements both the `Readable` and `Writeable` interfaces. Anything [written](https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Write) to a `ZStream` is compressed and emitted to the output stream (another `Writeable`); [reading](https://github.com/charonn0/RB-zlib/wiki/zlib.ZStream.Read) from a `ZStream` decompresses data from the input stream (another `Readable`).

Instances of `ZStream` can be created from MemoryBlocks, FolderItems, and objects that implement the `Readable` and/or `Writeable` interfaces. For example, creating an in-memory compression stream from a zero-length MemoryBlock and writing a string to it:

```realbasic
  Dim output As New MemoryBlock(0)
  Dim z As New zlib.ZStream(output) ' zero-length creates a compressor
  z.Write("Hello, world!")
  z.Close
```
The string will be processed through the compressor and written to the `output` MemoryBlock. To create a decompressor pass a MemoryBlock whose size is > 0 (continuing from above):

```realbasic
  z = New zlib.ZStream(output) ' output contains the compressed string
  MsgBox(z.ReadAll) ' read the decompressed string
```

### Inflater and Deflater classes
The third and final way to use zlib is through the [Inflater](https://github.com/charonn0/RB-zlib/wiki/zlib.Inflater) and [Deflater](https://github.com/charonn0/RB-zlib/wiki/zlib.Deflater) classes. These classes provide a low-level wrapper to the zlib API. All compression and decompression done using the `ZStream` class or the utility methods is ultimately carried out by an instance of `Deflater` and `Inflater`, respectively.

```realbasic
  Dim d As New zlib.Deflater()
  Dim data As MemoryBlock = d.Deflate("H")
  data = data + d.Deflate("el")
  data = data + d.Deflate("lo", zlib.Z_FINISH)
  
  Dim i As New zlib.Inflater()
  data = i.Inflate(data)
  MsgBox(data)
```

## More examples
This example compresses and decompresses a MemoryBlock using deflate compression:
```realbasic
  Dim data As MemoryBlock = "Potentially very large MemoryBlock goes here!"
  Dim comp As MemoryBlock = zlib.Deflate(data)
  Dim dcmp As MemoryBlock = zlib.Inflate(comp)
```

This example compresses and decompresses a MemoryBlock using GZip:
```realbasic
  Dim data As MemoryBlock = "Potentially very large MemoryBlock goes here!"
  Dim comp As MemoryBlock = zlib.GZip(data)
  Dim dcmp As MemoryBlock = zlib.GUnZip(comp)
```

This example gzips a file:

```realbasic
  Dim src As FolderItem = GetOpenFolderItem("") ' a file to be gzipped
  Dim dst As FolderItem = src.Parent.Child(src.Name + ".gz")
  If zlib.GZip(src, dst) Then 
    MsgBox("Compression succeeded!")
  Else
    MsgBox("Compression failed!")
  End If
```

This example opens an existing gzip file and decompresses it into a `MemoryBlock`:
```realbasic
  Dim f As FolderItem = GetOpenFolderItem("") ' the gzip file to open
  Dim data As MemoryBlock = zlib.GUnZip(f)
  If data <> Nil Then
    MsgBox("Decompression succeeded!")
  Else
    MsgBox("Decompression failed!")
  End If
```

This example extracts a zip archive into a directory:
```realbasic
  Dim src As FolderItem = GetOpenFolderItem("") ' a zip file to extract
  Dim dst As FolderItem = SelectFolder() ' the destination directory
  Dim extracted() As FolderItem ' the list of extracted files/folders
  extracted = PKZip.ReadZip(src, dst)
```

This example performs an HTTP request that asks for compression, and decompresses the response:

```realbasic
  Dim h As New URLConnection
  h.RequestHeader("Accept-Encoding") = "gzip, deflate"
  Dim page As String = h.SendSync("GET", "http://www.example.com", 10)
  If h.ResponseHeader("Content-Encoding") = "gzip" Then
    page = zlib.GUnZip(page)
  ElseIf h.ResponseHeader("Content-Encoding") = "deflate" Then
    page = zlib.Inflate(page) ' assume DEFLATE_ENCODING; some servers send RAW_ENCODING
  End If
```

This example performs a hand-rolled HTTP request using a TCPSocket, and demonstrates how the ZStream can be used with any object that implements the `Readable` and/or `Writeable` interfaces:

```realbasic
  Static CRLF As String = EndOfLine.Windows
  Dim sock As New TCPSocket
  sock.Address = "www.example.com"
  sock.Port = 80
  sock.Connect()
  Do Until sock.IsConnected
    sock.Poll
  Loop Until sock.LastErrorCode <> 0
  sock.Write("GET / HTTP/1.0" + CRLF + "Accept-Encoding: gzip" + CRLF + "Connection: close" + CRLF + "Host: www.example.com" + CRLF + CRLF)
  Do
    sock.Poll
  Loop Until Not sock.IsConnected
  
  Dim headers As String = sock.Read(InStrB(sock.Lookahead, CRLF + CRLF) + 3)
  Dim z As zlib.ZStream = zlib.ZStream.Open(sock)
  Dim webpage As String = z.ReadAll ' read/decompress from the socket
  z.Close
```

## How to incorporate zlib into your Realbasic/Xojo project
### Import the `zlib`, `USTAR`, and `PKZip` modules
1. Download the RB-zlib project either in [ZIP archive format](https://github.com/charonn0/RB-zlib/archive/master.zip) or by cloning the repository with your Git client.
2. Open the RB-zlib project in REALstudio or Xojo. Open your project in a separate window.
3. Copy the `zlib`, `USTAR`, and `PKZip` modules into your project and save.

### Ensure the zlib shared library is installed
zlib is installed by default on most Unix-like operating systems, including OS X and most Linux distributions, however at least zlib version 1.2.8 is needed.

Windows does not have it installed by default, you will need to ship the DLL with your application. You can use pre-built DLL available [here](http://zlib.net/zlib128-dll.zip) (Win32x86), or you can [build them yourself from source](http://zlib.net/zlib-1.2.8.tar.gz). 

RB-zlib will raise a PlatformNotSupportedException when used if all required DLLs/SOs/DyLibs are not available at runtime. 

The PKZip and USTAR modules may be used independently of the zlib module for reading and writing uncompressed archives. To do so set the `PKZip.USE_ZLIB` and/or `USTAR.USE_ZLIB` constants to `False`.
