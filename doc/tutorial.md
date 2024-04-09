# Tutorial

## Load an image, resize it, and save it as a thumbnail jpeg

```dart
import 'package:image/image.dart' as img;
void main() {
  // Read a jpeg image from file.
  final image = img.decodeJpg(File('test.jpg').readAsBytesSync());
  // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
  final thumbnail = img.copyResize(image, width: 120);
  // Save the thumbnail to a jpeg file.
  encodeToJpgFile('out/thumbnail-test.png', thumbnail);
}
```

## Load and process an image in a separate isolate thread

```dart
import 'package:image/image.dart' as img;
void main() async {
  // The Command API lets you define sequences of image commands to execute, and supports executing
  // in a separate Isolate thread.
  await (img.Command()
  // Decode the PNG image file
  ..decodeImageFile('test.png')
  // Resize the image to a width of 120 and a height that maintains the aspect ratio
  ..copyResize(width: 120)
  // Apply a blur to the image 
  ..gaussianBlur(radius: 5)
  // Save the resized image to a PNG image file 
  ..writeToFile('thumbnail.png'))
  // executeThread will run the commands in an Isolate thread
  .executeThread();
}
```

## Read an Image from an HTML Canvas element

```dart
import 'dart:html';
import 'package:image/image.dart' as img;

// Read a Canvas into an Image.
// The returned Image will be accessing the data of the canvas directly, so any changes you
// make to the pixels of Image will apply to the canvas.
img.Image getImageFromCanvas(CanvasElement canvas) {
  var imageData = canvas.context2D.getImageData(0, 0, canvas.width, canvas.height);
  // Create an Image from the canvas image data.
  return img.Image.fromBytes(width: canvas.width, height: canvas.height, bytes: imageData.data, numChannels: 4);
}
```

## Write an Image to an HTML Canvas element

```dart
import 'dart:html';
import 'package:image/image.dart' as img;

// Draw an Image onto a Canvas by getting writing the bytes to ImageData that can be
// copied to the Canvas.
void drawImageOntoCanvas(Html.CanvasElement canvas, img.Image image) {
  var imageData = canvas.context2D.createImageData(image.width, image.height);
  imageData.data.setRange(0, imageData.data.length, image.toUint8List());
  // Draw the buffer onto the canvas.
  canvas.context2D.putImageData(imageData, 0, 0);
}
```

## Create an image, draw some text, save it as a PNG

```dart
import 'package:image/image.dart' as img;
void main() async {
  await (img.Command()
  // Create an image, with the default uint8 format and default number of channels, 3. 
  ..createImage(width: 256, height: 256)
  // Fill the image with a solid color (blue)
  ..fill(color: img.ColorRgb8(0, 0, 255)))
  // Draw some text using the built-in 24pt Arial font
  ..drawString('Hello World', font: img.arial24, x: 0, y: 0)
  // Draw a red line
  ..drawLine(x1: 0, y1: 0, x2: 256, y2: 256, color: img.ColorRgb8(255, 0, 0), thickness: 3)
  // Blur the image
  ..gaussianBlur(radius: 10)
  // Save the image to disk as a PNG.
  ..writeToFile('test.png'))
  // Execute the command sequence.
  .execute();
}
```

## Map the grayscale of an image to its alpha channel, converting it to RGBA if necessary

```dart
import 'package:image/image.dart' as img;
img.Image grayscaleAlpha(img.Image image) {
  // Convert the image to RGBA (if it doesn't already have an alpha channel.
  final rgba = image.convert(numChannels: 4);
  // Map the luminance (grayscale) of the image to the alpha channel.
  return remapColors(rgba, alpha: img.Channel.luminance);
}
```

## Save the frames from a GIF animation to PNG files

```dart
import 'package:image/image.dart' as img;
void main() async {
  final anim = await img.decodeGifFile('animated.gif');
  // The frames property stores the frames of the animation. If the image didn't have any animation,
  // frames would have a single element, the image itself.
  for (final frame in anim.frames) {
    img.encodePngFile('animated_${frame.index}.png');
  }
}
}
```

## Load a directory of images, auto-trim the first image, and apply the trim to all subsequent images.

```dart
import 'package:image/image.dart' as img;
void main(List<String> argv) {
  final path = argv[0];
  final dir = Directory(path);
  final files = dir.listSync();
  List<int> trimRect;
  for (final f in files) {
    if (f is! File) {
      continue;
    }
    final bytes = f.readBytesSync();
    final image = img.decodeImage(bytes);
    if (image == null) {
      continue;
    }
    if (trimRect == null) {
      trimRect = img.findTrim(image, mode: img.TrimMode.transparent);
    }
    final trimmed = img.copyCrop(image, x: trimRect[0], y: trimRect[1], 
                             width: trimRect[2], height: trimRect[3]);

    String name = f.uri.pathSegments.last;
    img.encodeImageFile('$path/trimmed-$name', trimmed);
  }
}
```

## Split images into pieces

```dart
import 'package:image/image.dart' as img;

List<img.Image> splitImage(img.Image inputImage, int horizontalPieceCount, int verticalPieceCount) {
  img.Image image = inputImage;

  final pieceWidth = (image.width / horizontalPieceCount).round();
  final pieceHeight = (image.height / verticalPieceCount).round();
  final pieceList = List<imglib.Image>.empty(growable: true);

  for (var y = 0; y < image.height; y += pieceHeight) {
    for (var x = 0; x < image.width; x += pieceWidth) {
      pieceList.add(img.copyCrop(image, x: x, y: y, width: pieceWidth, height: pieceHeight));
    }
  }
  
  return pieceList;
}
```

