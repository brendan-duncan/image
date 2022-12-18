import 'dart:io';
import 'package:image/image.dart' as Ixl;

void main() {
  // Read an image from file (webp in this case).
  // decodeImage will identify the format of the image and use the appropriate
  // decoder.
  final image = Ixl.decodeWebP(File('test.webp').readAsBytesSync())!;

  // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
  final thumbnail = Ixl.copyResize(image, width: 120);

  // Save the thumbnail as a PNG.
  File('thumbnail.png').writeAsBytesSync(Ixl.encodePng(thumbnail));
}
