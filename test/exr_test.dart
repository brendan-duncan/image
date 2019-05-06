import 'dart:io' as Io;
import 'package:image/image.dart';

void main() {
  List<int> bytes = Io.File('test/res/exr/grid.exr').readAsBytesSync();

  ExrDecoder dec = ExrDecoder();
  dec.startDecode(bytes);
  Image img = dec.decodeFrame(0);

  List<int> png = PngEncoder().encodeImage(img);
  new Io.File('out/exr/grid.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);
}
