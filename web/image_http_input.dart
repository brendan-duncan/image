import 'dart:html' as Html;

import 'package:image/image.dart';
import 'package:crypto/crypto.dart';

Html.InputElement fileInput;

void main() {
  // There are at least two ways to get a file into an html dart app:
  // using a file Input element, or an AJAX HttpRequest.

  // This example demonstrats using a file Input element.
  fileInput = Html.querySelector("#file");

  fileInput.addEventListener("change", onFileChanged);
}

/**
 * Called when the user has selected a file.
 */
void onFileChanged(Html.Event event) {
  Html.FileList files = fileInput.files;
  var file = files.item(0);

  Html.FileReader reader = new Html.FileReader();
  reader.addEventListener("load", onFileLoaded);
  reader.readAsArrayBuffer(file);
}

/**
 * Called when the file has been read.
 */
void onFileLoaded(Html.ProgressEvent event) {
  Html.FileReader reader = event.currentTarget;

  var bytes = reader.result;

  // Find a decoder that is able to decode the given file contents.
  Decoder decoder = findDecoderForData(bytes);
  if (decoder == null) {
    print('Could not find format decoder for file');
    return;
  }

  // If a decoder was found, decode the file contents into an image.
  Image image = decoder.decodeImage(bytes);

  // If the image was able to be decoded, we can display it in a couple
  // different ways.  We could encode it to a format that can be displayed
  // by an IMG image element (like PNG or JPEG); or we could draw it into
  // a canvas.
  if (image != null) {
    // Add a separator to the html page
    Html.document.body.append(new Html.ParagraphElement());

    // Draw the image into a canvas.  First create a canvas at the correct
    // resolution.
    var c = new Html.CanvasElement();
    Html.document.body.append(c);
    c.width = image.width;
    c.height = image.height;

    // Create a buffer that the canvas can draw.
    Html.ImageData d = c.context2D.createImageData(c.width, c.height);
    // Fill the buffer with our image data.
    d.data.setRange(0, d.data.length, image.getBytes());
    // Draw the buffer onto the canvas.
    c.context2D.putImageData(d, 0, 0);


    // OR we could use an IMG element to display the image.
    // This requires encoding it to a common format (like PNG), base64 encoding
    // the encoded image, and using a data url for the img src.

    var img = new Html.ImageElement();
    Html.document.body.append(img);
    // encode the image to a PNG
    var png = encodePng(image);
    // base64 encode the png
    var png64 = CryptoUtils.bytesToBase64(png);
    // set the img src as a data url
    img.src = 'data:image/png;base64,${png64}';
  }
}
