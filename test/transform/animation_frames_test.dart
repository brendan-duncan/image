import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

final _operations = <String, Image Function(Image)>{
  'trim': (image) => trim(image, mode: TrimMode.transparent),
  'copyCropCircle': copyCropCircle,
  'copyRotate 90': (image) => copyRotate(image, angle: 90),
  'copyRotate 180': (image) => copyRotate(image, angle: 180),
  'copyRotate 270': (image) => copyRotate(image, angle: 270),
  'copyRotate 30': (image) => copyRotate(image, angle: 30),
  'copyRotate 30 linear': (image) =>
      copyRotate(image, angle: 30, interpolation: Interpolation.linear),
  'copyRotate 30 linearBlend': (image) => copyRotate(image,
      angle: 30, interpolation: Interpolation.linear, linearBlend: true),
  'copyResizeCropSquare': (image) => copyResizeCropSquare(image, size: 40),
  'copyResizeCropSquare linear with radius': (image) => copyResizeCropSquare(
      image,
      size: 40,
      interpolation: Interpolation.linear,
      radius: 5),
  'copyFlip': (image) => copyFlip(image, direction: FlipDirection.horizontal),
  'copyExpandCanvas': (image) => copyExpandCanvas(image,
      padding: 3, backgroundColor: ColorRgba8(9, 99, 199, 255)),
  'copyRectify': (image) => copyRectify(image,
      topLeft: Point(1, 1),
      topRight: Point(50, 2),
      bottomLeft: Point(2, 50),
      bottomRight: Point(50, 50)),
  'copyRectify linear': (image) => copyRectify(image,
      topLeft: Point(1, 1),
      topRight: Point(50, 2),
      bottomLeft: Point(2, 50),
      bottomRight: Point(50, 50),
      interpolation: Interpolation.linear),
  'bakeOrientation': (image) =>
      bakeOrientation(image..exif.imageIfd.orientation = 6),
  'copyCrop': (image) => copyCrop(image, x: 5, y: 5, width: 40, height: 30),
  'copyCrop with radius': (image) =>
      copyCrop(image, x: 5, y: 5, width: 40, height: 30, radius: 4),
  'copyResize linear': (image) =>
      copyResize(image, width: 33, interpolation: Interpolation.linear),
  'resize': (image) => resize(image, width: 33),
  'grayscale': grayscale,
  'invert': invert,
  'gaussianBlur': (image) => gaussianBlur(image, radius: 2),
  'pixelate': (image) => pixelate(image, size: 3),
  'sepia': sepia,
};

Image _animation(String name) {
  final image = decodeTestImage(name);
  for (var index = 0; index < image.numFrames; index++) {
    image.frames[index].frameDuration = 30 + index * 10;
  }

  return image;
}

void main() {
  group('Transform animation frames', () {
    for (final name in [
      'gif/animated.gif',
      'gif/palette_remap.gif',
      'gif/anim_palette.gif',
      'png/apng/test_apng1.png',
    ]) {
      for (final operation in _operations.entries) {
        test(
            '${operation.key} keeps duration and content of every frame of '
            '$name', () {
          final source = _animation(name);
          final result = operation.value(source.clone());

          expect(result.frames.map((frame) => frame.frameDuration),
              source.frames.map((frame) => frame.frameDuration));

          // trim takes rectangle from first frame, so frame trimmed without
          // other frames can have another rectangle
          if (operation.key == 'trim') {
            return;
          }

          for (var index = 0; index < source.numFrames; index++) {
            final single = Image.from(source.frames[index], noAnimation: true);
            final expected = operation.value(single);
            final frame = result.frames[index];

            expect([
              frame.width,
              frame.height,
              frame.numChannels
            ], [
              expected.width,
              expected.height,
              expected.numChannels
            ], reason: 'frame $index');
            expect(
                differingPixels(Image.from(frame, noAnimation: true), expected),
                0,
                reason: 'frame $index');
          }
        });
      }
    }

    test('copyCropCircle leaves pixels outside image transparent', () {
      final source = Image(width: 20, height: 12, numChannels: 4)
        ..clear(ColorRgba8(200, 100, 50, 255));

      final corner = copyCropCircle(source, centerX: 3, centerY: 3, radius: 8);
      final inside = corner.getPixel(8, 8);
      final outside = corner.getPixel(2, 8);

      expect([corner.width, corner.height], [16, 16]);
      expect([inside.r, inside.g, inside.b, inside.a], [200, 100, 50, 255]);
      expect(outside.a, 0);
    });

    test('copyExpandCanvas fills padding of every frame', () {
      final source = _animation('png/apng/test_apng1.png');
      final expanded = copyExpandCanvas(source,
          padding: 4, backgroundColor: ColorRgba8(9, 99, 199, 255));

      for (final frame in expanded.frames) {
        final corner = frame.getPixel(1, 1);
        expect([corner.r, corner.g, corner.b, corner.a], [9, 99, 199, 255]);
      }
    });

    for (final format in [
      Format.uint8,
      Format.uint16,
      Format.uint32,
      Format.int8,
      Format.int16,
      Format.int32,
      Format.float16,
      Format.float32,
      Format.float64,
    ]) {
      test('pixel alpha of 3-channel ${format.name} palette is opaque', () {
        final image = Image(
            width: 2, height: 1, withPalette: true, paletteFormat: format);
        final palette = image.palette!..setRgb(0, 1, 1, 1);

        expect(palette.numChannels, 3);
        expect(palette.getAlpha(0), palette.maxChannelValue);
        expect(image.getPixel(0, 0).a, palette.maxChannelValue);
      });
    }

    test('pixel alpha of 16-bit palette TIFF is opaque', () {
      final source = decodeTestImage('tiff/CNSW_crop.tif');

      expect(source.palette!.numChannels, 3);
      for (final pixel in source) {
        if (pixel.a != 65535) {
          fail('alpha ${pixel.a} at ${pixel.x},${pixel.y}');
        }
      }
    });
  });
}
