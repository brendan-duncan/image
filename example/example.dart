import 'dart:io' as Io;
import 'package:image/image.dart';
void main() {
  // Read an image from file (webp in this case).
  // decodeImage will identify the format of the image and use the appropriate
  // decoder.
  Image image = decodeImage(new Io.File('test.webp').readAsBytesSync());

  // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
  Image thumbnail = copyResize(image, 120);

  // Save the thumbnail as a PNG.
  new Io.File('thumbnail.png')
        ..writeAsBytesSync(encodePng(thumbnail));
}
