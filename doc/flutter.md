# Interfacing With Flutter

The term **Image** is highly overused, and despite the fact that both this library and Flutter have **Image** classes
(in fact, Flutter has multiple different classes called Image), they are very different classes.

NOTE: I will be releasing an extension library that will simplify working with this library and Flutter.

## Convert a Dart Image Library Image to a Flutter UI Image
```dart
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

Future<ui.Image> convertImageToFlutterUi(img.Image image) async {
  if (image.format != img.Format.uint8 || image.numChannels != 4) {
    final cmd = img.Command()
      ..image(image)
      ..convert(format: img.Format.uint8, numChannels: 4);
    final rgba8 = await cmd.getImageThread();
    if (rgba8 != null) {
      image = rgba8;
    }
  }

  ui.ImmutableBuffer buffer = await
  ui.ImmutableBuffer.fromUint8List(image.toUint8List());

  ui.ImageDescriptor id = ui.ImageDescriptor.raw(
      buffer,
      height: image.height,
      width: image.width,
      pixelFormat: ui.PixelFormat.rgba8888);

  ui.Codec codec = await id.instantiateCodec(
      targetHeight: image.height,
      targetWidth: image.width);

  ui.FrameInfo fi = await codec.getNextFrame();
  ui.Image uiImage = fi.image;

  return uiImage;
}
```

## Convert a Flutter UI Image to the Dart Image Library
```dart
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

Future<img.Image> convertFlutterUiToImage(ui.Image uiImage) async {
  final uiBytes = await uiImage.toByteData();

  final image = img.Image.fromBytes(width: id.width, height: id.height,
      bytes: uiBytes!.buffer,
      numChannels: 4);

  return image;
}
```

## Convert a Flutter Asset to the Dart Image Library
```dart
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

Future<img.Image?> decodeAsset(String path) async {
  final data = await rootBundle.load(path);

  // Utilize flutter's built-in decoder to decode asset images as it will be
  // faster than the dart decoder.
  final buffer = await ui.ImmutableBuffer.fromUint8List(
      data.buffer.asUint8List());

  final id = await ui.ImageDescriptor.encoded(buffer);
  final codec = await id.instantiateCodec(
      targetHeight: id.height,
      targetWidth: id.width);

  final fi = await codec.getNextFrame();

  final uiImage = fi.image;
  final uiBytes = await uiImage.toByteData();

  final image = img.Image.fromBytes(width: id.width, height: id.height,
      bytes: uiBytes!.buffer, numChannels: 4);

  return image;
}
```
