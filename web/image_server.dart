import 'dart:io' as Io;
import 'package:image/image.dart';

void main(List<String> argv) {
  if (argv.length < 1) {
    print('Usage: image_server <image_file>');
    return;
  }

  String filename = argv[0];

  Io.File file = Io.File(filename);
  if (!file.existsSync()) {
    print('File does not exist: ${filename}');
    return;
  }

  List<int> fileBytes = file.readAsBytesSync();

  Decoder decoder = findDecoderForData(fileBytes);
  if (decoder == null) {
    print('Could not find format decoder for: ${filename}');
    return;
  }

  Image image = decoder.decodeImage(fileBytes);

  // ... do something with image ...

  // Save the image as a PNG
  List<int> png = PngEncoder().encodeImage(image);
  // Write the PNG to disk
  new Io.File(filename + '.png').writeAsBytesSync(png);
}
