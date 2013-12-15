#dart_image - Image and graphics library for server side applications.

The image library aims to provide server-side programs the ability to load,
manipulate, and save various image file formats.

Simple usage example to load a jpeg, resize it, and save it as a jpeg.

    import 'dart:io' as Io;
    import 'package:dart_image/dart_image.dart';
    main() {
      Io.File file = new Io.File('res/cat-eye04.jpg');
      file.openSync();
      var bytes = file.readAsBytesSync();
      if (bytes == null) {
        return;
      }
    
      var jpegDecode = new JpegDecoder();
      var image = jpegDecode.decode(bytes);
    
      var thumbnail = image.resized(image.width ~/ 2, image.height ~/ 2);
    
      var jpegEncode = new JpegEncoder(100);
      var jpeg = jpegEncode.encode(thumbnail);
    
      Io.File fp = new Io.File('res/thumbnail-cat-eye04.jpg');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(jpeg);
    }
