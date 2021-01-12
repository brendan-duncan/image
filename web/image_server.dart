// @dart=2.11
import 'dart:io';
import 'package:image/image.dart';

void main(List<String> argv) {
  if (argv.isEmpty) {
    print('Usage: image_server <image_file>');
    return;
  }

  var filename = argv[0];

  var file = File(filename);
  if (!file.existsSync()) {
    print('File does not exist: ${filename}');
    return;
  }

  var fileBytes = file.readAsBytesSync();

  var decoder = findDecoderForData(fileBytes);
  if (decoder == null) {
    print('Could not find format decoder for: ${filename}');
    return;
  }

  var image = decoder.decodeImage(fileBytes);

  // ... do something with image ...

  // Save the image as a PNG
  var png = PngEncoder().encodeImage(image);
  // Write the PNG to disk
  File(filename + '.png').writeAsBytesSync(png);
}
