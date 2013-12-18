import 'dart:io' as Io;
import 'package:dart_image/dart_image.dart';

/**
 * Load a JPEG file and save out a resized thumbnail.
 */
main() {
  var jpegDecode = new JpegDecoder();
  var jpegEncode = new JpegEncoder(100);
  var pngDecode = new PngDecoder();
  var pngEncode = new PngEncoder();

  Io.File file = new Io.File('res/abstract.jpg');
  //Io.File file = new Io.File('res/cat-eye04.jpg');
  file.openSync();
  var bytes = file.readAsBytesSync();

  var image = jpegDecode.decode(bytes);

  var thumbnail = image.resized(image.width ~/ 2, image.height ~/ 2);


  var jpeg = jpegEncode.encode(thumbnail);

  //Io.File fp = new Io.File('res/thumbnail-abstract.jpg');
  Io.File fp = new Io.File('res/thumbnail-cat-eye04.jpg');
  fp.createSync(recursive: true);
  fp.writeAsBytesSync(jpeg);

  file = new Io.File('res/trees.png');
  file.openSync();
  bytes = file.readAsBytesSync();
  if (bytes == null) {
    return;
  }

  image = pngDecode.decode(bytes);

  jpeg = jpegEncode.encode(image);
  fp = new Io.File('res/out-trees.jpg');
  fp.createSync(recursive: true);
  fp.writeAsBytesSync(jpeg);


  file = new Io.File('res/alpha_edge.png');
  file.openSync();
  bytes = file.readAsBytesSync();
  if (bytes == null) {
    return;
  }
  image = pngDecode.decode(bytes);

  jpeg = jpegEncode.encode(image);
  fp = new Io.File('res/out-alpha_edge.jpg');
  fp.createSync(recursive: true);
  fp.writeAsBytesSync(jpeg);

  var png = pngEncode.encode(image);
  fp = new Io.File('res/out-alpha_edge.png');
  fp.createSync(recursive: true);
  fp.writeAsBytesSync(png);

  file = new Io.File('res/out-alpha_edge.png');
  file.openSync();
  bytes = file.readAsBytesSync();
  if (bytes == null) {
    return;
  }
  image = pngDecode.decode(bytes);
}
