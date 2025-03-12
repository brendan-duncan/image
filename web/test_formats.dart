import 'dart:async';
import 'dart:js_interop';
import 'package:http/http.dart' as http;
import 'package:image/image.dart';
import 'package:web/web.dart';

/// Decode and display various image formats. This is used as a visual
/// unit-test to identify problems that may occur after the translation to
/// javascript.
void main() async {
  // An img on the html page is used to establish the path to the images
  // directory. It's removed after we get the path since we'll be populating
  // the page with our own decoded images.
  final img = document.querySelectorAll('img').item(0) as HTMLImageElement;
  final path = img.src.substring(0, img.src.lastIndexOf('/'));
  img.remove();

  // The list of images we'll be decoding, representing a wide range
  // of formats and sub-formats.
  final images = [
    '1_webp_ll.webp',
    '1.webp',
    '3_webp_a.webp',
    'trees.png',
    'cars.gif',
    'animated_lossy.webp',
    'animated.png',
  ];

  for (final name in images) {
    // Use an http request to get the image file from disk.
    final response = await http.get(Uri.parse('$path/$name'));
    if (response.statusCode == 200) {
      // Convert the text to binary byte list.
      final bytes = response.bodyBytes;

      final label = HTMLDivElement();
      document.body!.append(label);
      label.textContent = name;

      // Create a canvas to put our decoded image into.
      final canvas = HTMLCanvasElement();
      document.body!.append(canvas);

      // Finds the best decoder for the image.
      final image = decodeNamedImage(name, bytes);
      if (image == null) {
        return;
      }

      // Canvas only supports rgba8, so make sure the image is in that
      // format.
      final rgba8 =
          image.convert(format: Format.uint8, numChannels: 4, alpha: 255);

      canvas
        ..width = rgba8.width
        ..height = rgba8.height;

      // Create a buffer that the canvas can draw.
      final canvasData =
          canvas.context2D.createImageData(canvas.width.toJS, canvas.height);

      // If it's a single image, dump the decoded image into the canvas.
      if (rgba8.numFrames == 1) {
        // TODO: how do you do this with package:web?
        // Fill the buffer with our image data.
        //canvasData.data
        //.setRange(0, canvasData.data.length, rgba8.toUint8List());
        // Draw the buffer onto the canvas.
        canvas.context2D.putImageData(canvasData, 0, 0);

        return;
      }

      // A multi-frame animation, use a timer to draw frames.
      var f = 0;
      Timer.periodic(const Duration(milliseconds: 40), (t) {
        //final frame = rgba8.frames[f++];
        if (f >= rgba8.numFrames) {
          f = 0;
        }

        // TODO: how do you do this with package:web?
        // Fill the buffer with our image data.
        //canvasData.data
        //.setRange(0, canvasData.data.length, frame.toUint8List());

        // Draw the buffer onto the canvas.
        canvas.context2D.putImageData(canvasData, 0, 0);
      });
    }
  }
}
