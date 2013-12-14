#dart_gd - Image and graphics library for server side applications.


The GD library aims to provide similar functionality for server-side programs
that the PHP GD library provides for image io and manipulation.  It can
encode/decode various image formats and provides basic image drawing and
manipulation functions.

Simple usage example to load a jpeg, resize it, and save it as a jpeg.

    import 'dart:io' as Io;
    import 'package:dart_gd/gd.dart';
    main() {
      Io.File file = new Io.File('res/cat-eye04.jpg');
      file.openSync();
      var bytes = file.readAsBytesSync();
      if (bytes == null) {
        return;
      }
    
      Gd.JpegDecoder jpegDecode = new Gd.JpegDecoder();
      Gd.Image image = jpegDecode.decode(bytes);
    
      Gd.Image thumbnail = image.resized(image.width ~/ 2, image.height ~/ 2);
    
      Gd.JpegEncoder jpegEncode = new Gd.JpegEncoder(100);
      var jpeg = jpegEncode.encode(thumbnail);
    
      Io.File fp = new Io.File('res/thumbnail-cat-eye04.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(jpeg);
    }
