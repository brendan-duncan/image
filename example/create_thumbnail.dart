import 'dart:io' as Io;
import '../lib/gd.dart' as Gd;

/**
 * Load a JPEG file and save out a resized thumbnail.
 */
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
