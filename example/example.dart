import 'package:image/image.dart' as DIL;

void main() async {
  final cmd = DIL.Command()
    // Read a WebP image from a file.
    ..decodeWebPFile('test.webp')
    // Resize the image so its width is 120 and height maintains aspect ratio.
    ..copyResize(width: 120)
    // Save the image to a PNG file.
    ..writeToFile('thumbnail.png');

  // Execute the image commands asynchronously
  await cmd.executeAsync();
}
