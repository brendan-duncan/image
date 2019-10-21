import 'dart:io';
import 'package:image/image.dart';

void main() {
  List<int> bytes = File('test/res/exr/grid.exr').readAsBytesSync();

  ExrDecoder dec = ExrDecoder();
  dec.startDecode(bytes);
  Image img = dec.decodeFrame(0);

  List<int> png = PngEncoder().encodeImage(img);
  File('out/exr/grid.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(png);
}
