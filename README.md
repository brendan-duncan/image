# image

##Overview

A Dart library to encode and decode various image formats.

The library has no reliance on `dart:io`, so it can be used for both server and
web applications. The image library currently supports the following decoders:

- PNG
- JPG
- TGA

And the following encoders:

- PNG
- JPG
- TGA

##Sample

Load a jpeg, resize it, and save it as a png:

    import 'dart:io' as Io;
    import 'package:image/image.dart';
    void main() {
      // Read a jpeg image from file.
      Io.File file = new Io.File('res/cat-eye04.jpg');    
      Image image = readJpg(ile.readAsBytesSync());

      // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
      Image thumbnail = resize(120);
    
      // Save the thumbnail as a PNG.
      Io.File fp = new Io.File('out/thumbnail-cat-eye04.png');
      fp.createSync(recursive: true);
      fp.writeAsBytesSync(writePng(thumbnail));
    }

