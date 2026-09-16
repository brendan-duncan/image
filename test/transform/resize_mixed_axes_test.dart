import 'package:image/image.dart';
import 'package:test/test.dart';

Image pattern({bool palette = false, int blue = 40}) {
  final image = Image(width: 8, height: 8, withPalette: palette);
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      if (palette) {
        final index = y * 8 + x;
        image.palette!.setRgb(index, 10 + x * 20, 10 + y * 20, blue);
        image.setPixelIndex(x, y, index);
      } else {
        image.setPixelRgb(x, y, 10 + x * 20, 10 + y * 20, blue);
      }
    }
  }
  return image;
}

void expectNearest(Image image, int width, int height, {int blue = 40}) {
  expect(image.width, width);
  expect(image.height, height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixel = image.getPixel(x, y);
      expect([
        pixel.r,
        pixel.g,
        pixel.b
      ], [
        10 + ((x * 8) ~/ width) * 20,
        10 + ((y * 8) ~/ height) * 20,
        blue
      ], reason: 'output pixel ($x, $y)');
    }
  }
}

void main() {
  group('resize mixed axes', () {
    for (final size in [(16, 4), (4, 16), (16, 3), (3, 16)]) {
      for (final palette in [false, true]) {
        test('${size.$1}x${size.$2}, palette=$palette', () {
          final src = pattern(palette: palette);
          final dst = resize(src, width: size.$1, height: size.$2);
          expectNearest(dst, size.$1, size.$2);
          expect(dst.hasPalette, palette);
          // As with other enlargements, use the returned image, not src.
          expect(identical(src, dst), isFalse);
          expectNearest(src, 8, 8);
        });
      }
    }

    test('preserves every animation frame and its duration', () {
      final src = pattern()
        ..loopCount = 3
        ..frameDuration = 100
        ..addFrame(pattern(blue: 200)..frameDuration = 300);
      final dst = resize(src, width: 16, height: 4);
      expect(dst.numFrames, 2);
      expect(dst.loopCount, 3);
      expect(dst.frames.map((f) => f.frameDuration), [100, 300]);
      expectNearest(dst.frames[0], 16, 4);
      expectNearest(dst.frames[1], 16, 4, blue: 200);
    });

    for (final interpolation in Interpolation.values) {
      test('constant image with ${interpolation.name}', () {
        final src = Image(width: 8, height: 8)..clear(ColorRgb8(40, 80, 120));
        final dst =
            resize(src, width: 16, height: 3, interpolation: interpolation);
        expect([dst.width, dst.height], [16, 3]);
        for (final pixel in dst) {
          expect([pixel.r, pixel.g, pixel.b], [40, 80, 120]);
        }
        expect([src.width, src.height], [8, 8]);
      });
    }

    test('same size and pure downscale retain the existing in-place path', () {
      final src = pattern();
      expect(identical(resize(src, width: 8, height: 8), src), isTrue);
      final dst = resize(src, width: 4, height: 4);
      expect(identical(dst, src), isTrue);
      expectNearest(dst, 4, 4);
    });
  });
}
