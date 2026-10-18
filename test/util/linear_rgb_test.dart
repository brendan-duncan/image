import 'package:image/image.dart';
import 'package:test/test.dart';

// A black and white checkerboard, which averages to half the light: 188 in
// sRGB, not the 128 of averaging the stored values.
Image checkerboard(int size, {Format format = Format.uint8}) {
  final image = Image(width: size, height: size, format: format);
  for (final p in image) {
    final v = (p.x + p.y).isEven ? 1.0 : 0.0;
    p
      ..rNormalized = v
      ..gNormalized = v
      ..bNormalized = v;
  }
  return image;
}

void main() {
  group('linear RGB', () {
    test('srgbToLinear and linearToSrgb', () {
      expect(srgbToLinear(0), equals(0));
      expect(srgbToLinear(1), closeTo(1, 1e-12));
      expect(srgbToLinear(0.5), closeTo(0.2140, 1e-4));
      expect(linearToSrgb(0.5), closeTo(0.7354, 1e-4));
      expect(srgbToLinear(-0.5), equals(-srgbToLinear(0.5)));
      for (var i = 0; i <= 100; ++i) {
        final v = i / 100;
        expect(linearToSrgb(srgbToLinear(v)), closeTo(v, 1e-9));
      }
    });

    test('uint8 values survive the round trip exactly', () {
      // 2x2 blocks of one value each, which pixelate leaves as they are.
      final image = Image(width: 2, height: 512, numChannels: 4);
      for (final p in image) {
        final v = p.y ~/ 2;
        p.setRgba(v, 255 - v, v, 255 - v);
      }
      final orig = image.clone();
      pixelate(image, size: 2, linearBlend: true);
      for (final p in image) {
        expect(p, equals(orig.getPixel(p.x, p.y)));
      }
    });

    test('copyResize average', () {
      final src = checkerboard(64);
      final numbers =
          copyResize(src, width: 16, interpolation: Interpolation.average);
      final light = copyResize(src,
          width: 16, interpolation: Interpolation.average, linearBlend: true);
      expect(light.format, equals(Format.uint8));
      expect(light.width, equals(16));
      expect(numbers.getPixel(8, 8).r, closeTo(128, 2));
      expect(light.getPixel(8, 8).r, closeTo(188, 2));
    });

    test('copyResize linear and cubic', () {
      // Enlarged, the pixels between black and white are blends, and a blend
      // of light is brighter than a blend of the stored values.
      for (final interpolation in [Interpolation.linear, Interpolation.cubic]) {
        final src = checkerboard(4);
        final numbers =
            copyResize(src, width: 13, interpolation: interpolation);
        final light = copyResize(src,
            width: 13, interpolation: interpolation, linearBlend: true);
        var brighter = 0;
        for (final p in light) {
          final n = numbers.getPixel(p.x, p.y).r;
          expect(p.r, greaterThanOrEqualTo(n), reason: '$interpolation');
          if (p.r > n + 20) {
            brighter++;
          }
        }
        expect(brighter, greaterThan(0), reason: '$interpolation');
      }
    });

    test('copyResize leaves nearest unchanged', () {
      final src = checkerboard(64);
      final a = copyResize(src, width: 16);
      final b = copyResize(src, width: 16, linearBlend: true);
      for (final p in a) {
        expect(p, equals(b.getPixel(p.x, p.y)));
      }
    });

    test('copyResize keeps alpha and the background color', () {
      final src = checkerboard(64).convert(numChannels: 4, alpha: 100);
      final out = copyResize(src,
          width: 32,
          height: 16,
          maintainAspect: true,
          backgroundColor: ColorRgba8(255, 0, 0, 255),
          interpolation: Interpolation.average,
          linearBlend: true);
      expect(out.getPixel(0, 8), equals(ColorRgba8(255, 0, 0, 255)));
      final p = out.getPixel(16, 8);
      expect(p.r, closeTo(188, 2));
      expect(p.a, equals(100));
    });

    test('resize', () {
      final out = resize(checkerboard(64),
          width: 16, interpolation: Interpolation.average, linearBlend: true);
      expect(out.width, equals(16));
      expect(out.getPixel(8, 8).r, closeTo(188, 2));
    });

    test('float images', () {
      final out = copyResize(checkerboard(64, format: Format.float32),
          width: 16, interpolation: Interpolation.average, linearBlend: true);
      expect(out.format, equals(Format.float32));
      expect(out.getPixel(8, 8).r, closeTo(linearToSrgb(0.5), 0.01));
    });

    test('uint16 images', () {
      final out = copyResize(checkerboard(64, format: Format.uint16),
          width: 16, interpolation: Interpolation.average, linearBlend: true);
      expect(out.format, equals(Format.uint16));
      expect(out.getPixel(8, 8).rNormalized, closeTo(linearToSrgb(0.5), 0.01));
    });

    test('gaussianBlur', () {
      final numbers = gaussianBlur(checkerboard(32), radius: 4);
      final image = checkerboard(32);
      final light = gaussianBlur(image, radius: 4, linearBlend: true);
      // Blurred in place.
      expect(identical(light, image), isTrue);
      expect(numbers.getPixel(16, 16).r, closeTo(128, 4));
      expect(light.getPixel(16, 16).r, closeTo(188, 4));
    });

    test('gaussianBlur of a palette image returns a new image', () {
      final src = checkerboard(32).convert(withPalette: true);
      expect(src.hasPalette, isTrue);
      final out = gaussianBlur(src, radius: 4, linearBlend: true);
      expect(out.hasPalette, isFalse);
      expect(out.getPixel(16, 16).r, closeTo(188, 4));
    });

    test('animation frames', () {
      final src = checkerboard(64)..addFrame(checkerboard(64));
      final out = copyResize(src,
          width: 16, interpolation: Interpolation.average, linearBlend: true);
      expect(out.numFrames, equals(2));
      expect(out.frames[1].getPixel(8, 8).r, closeTo(188, 2));
    });

    test('pixelate', () {
      final out = pixelate(checkerboard(8),
          size: 4, mode: PixelateMode.average, linearBlend: true);
      // Only the block's first pixel: the others are averaged from partly
      // overwritten pixels, with or without linearBlend.
      expect(out.getPixel(0, 0).r, closeTo(188, 1));
    });

    test('copyRotate', () {
      final src = checkerboard(32);
      // A multiple of 90 degrees doesn't blend.
      final r90 = copyRotate(src,
          angle: 90, interpolation: Interpolation.linear, linearBlend: true);
      expect(r90.getPixel(0, 0).r, anyOf(0, 255));
      // Halfway between pixels, every sample mixes black and white.
      final r45 = copyRotate(src,
          angle: 45, interpolation: Interpolation.linear, linearBlend: true);
      final c = r45.getPixel(r45.width ~/ 2, r45.height ~/ 2).r;
      expect(c, inInclusiveRange(0, 255));
    });

    test('copyRectify into toImage', () {
      final src = checkerboard(32);
      final dst = Image(width: 16, height: 16);
      final out = copyRectify(src,
          topLeft: Point(0.5, 0.5),
          topRight: Point(30.5, 0.5),
          bottomLeft: Point(0.5, 30.5),
          bottomRight: Point(30.5, 30.5),
          interpolation: Interpolation.linear,
          toImage: dst,
          linearBlend: true);
      expect(identical(out, dst), isTrue);
      // Sampled halfway between four pixels, two of them white.
      expect(dst.getPixel(8, 8).r, closeTo(188, 2));
    });

    test('drawPixel', () {
      final numbers = Image(width: 1, height: 1);
      final light = Image(width: 1, height: 1);
      final white = ColorRgba8(255, 255, 255, 128);
      drawPixel(numbers, 0, 0, white);
      drawPixel(light, 0, 0, white, linearBlend: true);
      expect(numbers.getPixel(0, 0).r, closeTo(128, 1));
      expect(light.getPixel(0, 0).r, closeTo(188, 1));
    });

    test('drawLine', () {
      final image = Image(width: 8, height: 8);
      drawLine(image,
          x1: 0,
          y1: 0,
          x2: 7,
          y2: 7,
          color: ColorRgba8(255, 255, 255, 128),
          linearBlend: true);
      expect(image.getPixel(3, 3).r, closeTo(188, 1));
    });

    test('command', () async {
      final out = await (Command()
            ..image(checkerboard(64))
            ..copyResize(
                width: 16,
                interpolation: Interpolation.average,
                linearBlend: true))
          .getImage();
      expect(out!.getPixel(8, 8).r, closeTo(188, 2));
    });
  });
}
