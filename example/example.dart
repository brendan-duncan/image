import 'dart:io';
import 'package:image/image.dart';

void main() {
  // Read an image from file (webp in this case).
  // decodeImage will identify the format of the image and use the appropriate
  // decoder.
  Image image = decodeImage(new File('test.webp').readAsBytesSync());

  // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
  Image thumbnail = copyResize(image, width: 120);

  // Save the thumbnail as a PNG.
  new File('thumbnail.png').writeAsBytesSync(encodePng(thumbnail));
}
