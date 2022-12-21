import 'dart:io';
import 'package:image/image_io.dart' as DIL;

Future<void> main() async {
  // Decode and process an image file in a separate thread (isolate) to avoid
  // stalling the main UI thread.

  // Read an image from file (webp in this case).
  // decodeImage will identify the format of the image and use the appropriate
  // decoder.
  final image = await DIL.decodeImageFileAsync('test.webp');
  if (image != null) {
    final thumbnail = await DIL.copyResizeAsync(image, width: 120);
    await File('thumbnail.png').writeAsBytes(DIL.encodePng(thumbnail));
  }
}
