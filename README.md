# image

##Overview

A Dart library to encode and decode various image formats.

The library has no reliance on `dart:io`, so it can be used for both server and
web applications. The image library currently supports the following decoders:

- PNG
- JPG 

And the following encoders:

- PNG
- JPG
- TGA

##Sample

Load a jpeg, resize it, and save it as a png.

    import 'dart:io' as Io;
    import 'package:image/image.dart';
    main() {
      Io.File file = new Io.File('res/cat-eye04.jpg');
      var bytes = file.readAsBytesSync();
      if (bytes == null) {
        return;
      }
    
      var image = new JpegDecoder().decode(bytes);
    
      var thumbnail = image.resized(image.width ~/ 2, image.height ~/ 2);
    
      var png = new PngEncoder().encode(thumbnail);
    
      Io.File fp = new Io.File('out/thumbnail-cat-eye04.png');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(png);
    }

