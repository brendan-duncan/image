import 'dart:html' as Html;
import 'dart:async' as Async;
import 'package:image/image.dart';

/**
 * Decode and display various image formats.  This is used as a visual
 * unit-test to indentify problems that may occur after the translation to
 * javascript.
 */
void main() {
  // An img on the html page is used to establish the path to the images
  // directory.  It's removed after we get the path since we'll be populating
  // the page with our own decoded images.
  Html.ImageElement img = Html.querySelectorAll('img')[0];
  String path = img.src.substring(0, img.src.lastIndexOf('/'));
  img.remove();

  // The list of images we'll be decoding, representing a wide range
  // of formats and sub-formats.
  List<String> images = ['1.webp', '1_webp_ll.webp', '3_webp_a.webp',
                         'puppies.jpg', 'cars.gif', 'trees.png',
                         'BladeRunner_lossy.webp'];

  for (String name in images) {
    // Use an AJAX request to get the image file from disk.
    var req = new Html.HttpRequest();
    req.open('GET', path + '/' + name);
    req.overrideMimeType('text\/plain; charset=x-user-defined');
    req.onLoadEnd.listen((e) {
      if (req.status == 200) {
        // Convert the text to binary byte list.
        var bytes = req.responseText.split('').map((e){
          return new String.fromCharCode(e.codeUnitAt(0) & 0xff);
        }).join('').codeUnits;

        var label = new Html.DivElement();
        Html.document.body.append(label);
        label.text = name;

        // Create a canvas to put our decoded image into.
        var c = new Html.CanvasElement();
        Html.document.body.append(c);

        // Find the best decoder for the image.  Currently, the extension
        // of the file name is used.  A better method would actually look
        // at the bytes of the file to find the correct format.
        Decoder decoder = getDecoderForNamedImage(name);
        if (decoder == null) {
          return;
        }

        // Some of the files are animated, so always decode to animation.
        // Single image files will decode to a single framed animation.
        Animation anim = decoder.decodeAnimation(bytes);
        if (anim == null) {
          return;
        }

        // If it's a single image, dump the decoded image into the canvas.
        if (anim.length == 1) {
          Image image = anim.frames[0].image;
          c.width = image.width;
          c.height = image.height;

          // Create a buffer that the canvas can draw.
          Html.ImageData d = c.context2D.createImageData(c.width, c.height);
          // Fill the buffer with our image data.
          d.data.setRange(0, d.data.length, image.getBytes());
          // Draw the buffer onto the canvas.
          c.context2D.putImageData(d, 0, 0);

          return;
        }

        // A multi-frame animation, use a timer to draw frames.
        // TODO this is currently not using the timing information in the
        // [Animation], and using a hard-coded delay instead.

        // Setup the canvas size to the size of the first image.
        c.width = anim.frames[0].image.width;
        c.height = anim.frames[0].image.height;
        // Create a buffer that the canvas can draw.
        Html.ImageData d = c.context2D.createImageData(c.width, c.height);

        int frame = 0;
        new Async.Timer.periodic(new Duration(milliseconds: 80), (t) {
          Image image = anim.frames[frame++].image;
          if (frame >= anim.numFrames) {
            frame = 0;
          }

          // Fill the buffer with our image data.
          d.data.setRange(0, d.data.length, image.getBytes());
          // Draw the buffer onto the canvas.
          c.context2D.putImageData(d, 0, 0);
        });
      }
   });
   req.send('');
  }
}
