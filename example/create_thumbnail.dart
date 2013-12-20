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

  // Sequential JPEG
  Io.File file = new Io.File('res/cat-eye04.jpg');
  file.openSync();
  var bytes = file.readAsBytesSync();
  var image = jpegDecode.decode(bytes);
  var thumbnail = image.resized(image.width ~/ 2, image.height ~/ 2);
  var jpeg = jpegEncode.encode(thumbnail);
  Io.File fp = new Io.File('res/thumbnail-cat-eye04.jpg');
  fp.createSync(recursive: true);
  fp.writeAsBytesSync(jpeg);

  // Progressive JPEG
  file = new Io.File('res/abstract.jpg');
  file.openSync();
  bytes = file.readAsBytesSync();
  image = jpegDecode.decode(bytes);
  thumbnail = image.resized(image.width ~/ 2, image.height ~/ 2);
  jpeg = jpegEncode.encode(thumbnail);
  fp = new Io.File('res/thumbnail-abstract.jpg');
  fp.createSync(recursive: true);
  fp.writeAsBytesSync(jpeg);


  // PNG 24-bit
  file = new Io.File('res/trees.png');
  file.openSync();
  bytes = file.readAsBytesSync();
  image = pngDecode.decode(bytes);
  jpeg = jpegEncode.encode(image);
  fp = new Io.File('res/out-trees.jpg');
  fp.createSync(recursive: true);
  fp.writeAsBytesSync(jpeg);

  // PNG 32-bit
  file = new Io.File('res/alpha_edge.png');
  file.openSync();
  bytes = file.readAsBytesSync();
  image = pngDecode.decode(bytes);

  // Output to PNG
  var png = pngEncode.encode(image);
  fp = new Io.File('res/out-alpha_edge.png');
  fp.createSync(recursive: true);
  fp.writeAsBytesSync(png);
}
