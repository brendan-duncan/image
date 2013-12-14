import 'dart:io' as Io;
import '../src/gd.dart' as Gd;

main() {
  Gd.JpegDecoder jpegDecode = new Gd.JpegDecoder();

  Io.File file = new Io.File('res/cat-eye04.jpg');
  file.openSync();
  var bytes = file.readAsBytesSync();
  if (bytes == null) {
    return;
  }
  Gd.Image image = jpegDecode.decode(bytes);

  Gd.JpegEncoder jpegEncode = new Gd.JpegEncoder(100);
  bytes = jpegEncode.encode(image);

  Io.File fp = new Io.File('res/test-cat-eye04.jpg');
  fp.createSync(recursive: true);
  fp.writeAsBytesSync(bytes);
}
