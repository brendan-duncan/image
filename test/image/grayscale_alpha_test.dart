import 'dart:io';

import 'package:image/image.dart';
import 'package:test/test.dart';

/// A two channel image is grayscale+alpha: channel 0 is the gray sample and
/// channel 1 is alpha. `r`, `g` and `b` all read and write the gray sample,
/// and `a` reads and writes alpha, for every format.
const _formats = [
  Format.uint1,
  Format.uint2,
  Format.uint4,
  Format.uint8,
  Format.uint16,
  Format.uint32,
  Format.int8,
  Format.int16,
  Format.int32,
  Format.float16,
  Format.float32,
  Format.float64,
];

/// A gray and an alpha value that are distinct in [format], so that writing
/// one where the other belongs is visible.
({num gray, num alpha}) _samples(Format format) {
  switch (format) {
    case Format.uint1:
      return (gray: 0, alpha: 1);
    case Format.float16:
    case Format.float32:
    case Format.float64:
      return (gray: 0.25, alpha: 1.0);
    default:
      return (gray: 1, alpha: 2);
  }
}

Image _grayAlpha(Format format, {int width = 8, int height = 8}) {
  final image =
      Image(width: width, height: height, format: format, numChannels: 2);
  final s = _samples(format);
  for (final p in image) {
    p
      ..r = s.gray
      ..a = s.alpha;
  }
  return image;
}

void _expectGrayAlpha(Image image, Format format, String reason) {
  final s = _samples(format);
  for (final p in image) {
    expect(p.r, equals(s.gray), reason: '$reason: gray at ${p.x},${p.y}');
    expect(p.a, equals(s.alpha), reason: '$reason: alpha at ${p.x},${p.y}');
  }
}

/// A new, empty [Color] of [format] with [numChannels] channels.
Color _color(Format format, int numChannels) {
  switch (format) {
    case Format.uint1:
      return ColorUint1(numChannels);
    case Format.uint2:
      return ColorUint2(numChannels);
    case Format.uint4:
      return ColorUint4(numChannels);
    case Format.uint8:
      return ColorUint8(numChannels);
    case Format.uint16:
      return ColorUint16(numChannels);
    case Format.uint32:
      return ColorUint32(numChannels);
    case Format.int8:
      return ColorInt8(numChannels);
    case Format.int16:
      return ColorInt16(numChannels);
    case Format.int32:
      return ColorInt32(numChannels);
    case Format.float16:
      return ColorFloat16(numChannels);
    case Format.float32:
      return ColorFloat32(numChannels);
    case Format.float64:
      return ColorFloat64(numChannels);
  }
}

void main() {
  group('Image', () {
    group('grayscale+alpha', () {
      for (final format in _formats) {
        group(format.name, () {
          final s = _samples(format);

          test('r, g and b are the gray sample; a is channel 1', () {
            final image = _grayAlpha(format, width: 1, height: 1);
            final p = image.getPixel(0, 0);
            expect(p.r, equals(s.gray));
            expect(p.g, equals(s.gray));
            expect(p.b, equals(s.gray));
            expect(p.a, equals(s.alpha));
            // Indexed access stays raw, so it shows the storage order.
            expect(p.toList(), equals([s.gray, s.alpha]));
          });

          test('setRgba writes gray and alpha', () {
            final image =
                Image(width: 1, height: 1, format: format, numChannels: 2);
            image.getPixel(0, 0).setRgba(s.gray, 0, 0, s.alpha);
            expect(image.getPixel(0, 0).toList(), equals([s.gray, s.alpha]));
          });

          test('setPixelRgba writes gray and alpha', () {
            final image =
                Image(width: 1, height: 1, format: format, numChannels: 2)
                  ..setPixelRgba(0, 0, s.gray, 0, 0, s.alpha);
            expect(image.getPixel(0, 0).toList(), equals([s.gray, s.alpha]));
          });

          test('setRgb leaves alpha alone', () {
            final image = _grayAlpha(format, width: 1, height: 1);
            image.getPixel(0, 0).setRgb(0, s.alpha, s.alpha);
            expect(image.getPixel(0, 0).toList(), equals([0, s.alpha]));
          });

          test('setPixelRgb leaves alpha alone', () {
            final image = _grayAlpha(format, width: 1, height: 1)
              ..setPixelRgb(0, 0, 0, s.alpha, s.alpha);
            expect(image.getPixel(0, 0).toList(), equals([0, s.alpha]));
          });

          test('luminance is the gray sample', () {
            final image = _grayAlpha(format, width: 1, height: 1);
            expect(image.getPixel(0, 0).luminance, equals(s.gray));
          });

          for (final interpolation in Interpolation.values) {
            test('copyResize preserves alpha (${interpolation.name})', () {
              final resized = copyResize(_grayAlpha(format),
                  width: 4, interpolation: interpolation);
              _expectGrayAlpha(resized, format, 'copyResize');
            });
          }

          test('getChannel agrees with r, g, b and a', () {
            final p = _grayAlpha(format, width: 1, height: 1).getPixel(0, 0);
            expect(p.getChannel(Channel.red), equals(p.r));
            expect(p.getChannel(Channel.green), equals(p.g));
            expect(p.getChannel(Channel.blue), equals(p.b));
            expect(p.getChannel(Channel.alpha), equals(p.a));
            expect(p.getChannel(Channel.luminance), equals(s.gray));
          });

          test('resize preserves alpha', () {
            final resized = resize(_grayAlpha(format), width: 4);
            _expectGrayAlpha(resized, format, 'resize');
          });

          test('copyRotate preserves alpha', () {
            final rotated = copyRotate(_grayAlpha(format), angle: 90);
            _expectGrayAlpha(rotated, format, 'copyRotate');
          });

          test('copyCrop preserves alpha', () {
            final cropped =
                copyCrop(_grayAlpha(format), x: 1, y: 1, width: 4, height: 4);
            _expectGrayAlpha(cropped, format, 'copyCrop');
          });

          test('copyFlip preserves alpha', () {
            final flipped = copyFlip(_grayAlpha(format),
                direction: FlipDirection.horizontal);
            _expectGrayAlpha(flipped, format, 'copyFlip');
          });

          test('a 2 channel Color reads as gray+alpha', () {
            final c = _color(format, 2)
              ..r = s.gray
              ..a = s.alpha;
            expect(c.r, equals(s.gray));
            expect(c.g, equals(s.gray));
            expect(c.b, equals(s.gray));
            expect(c.a, equals(s.alpha));
            expect(c.luminance, equals(s.gray));
            expect(c.getChannel(Channel.green), equals(s.gray));
            expect(c.getChannel(Channel.alpha), equals(s.alpha));
            expect(c.toList(), equals([s.gray, s.alpha]));
          });

          test('Color.setRgba writes gray and alpha', () {
            final c = _color(format, 2)..setRgba(s.gray, 0, 0, s.alpha);
            expect(c.toList(), equals([s.gray, s.alpha]));
          });

          test('Color.setRgb leaves alpha alone', () {
            final c = _color(format, 2)
              ..a = s.alpha
              ..setRgb(0, s.alpha, s.alpha);
            expect(c.toList(), equals([0, s.alpha]));
          });
        });
      }

      test('clear fills alpha, not the background green', () {
        final image = Image(width: 4, height: 4, numChannels: 2)
          ..clear(ColorRgba8(12, 34, 56, 200));
        for (final p in image) {
          expect(p.r, equals(12));
          expect(p.a, equals(200));
        }
      });

      test('copyResize letterbox padding keeps the background alpha', () {
        final resized = copyResize(_grayAlpha(Format.uint8, height: 4),
            width: 8,
            height: 8,
            maintainAspect: true,
            backgroundColor: ColorRgba8(0, 0, 0, 255));
        // The padded rows are background, which is opaque black.
        expect(resized.getPixel(0, 0).a, equals(255));
        expect(resized.getPixel(0, 0).r, equals(0));
      });

      test('ConstColorRg8 keeps its own red+green meaning', () {
        // The named const colors declare what their channels are, so a
        // 2 channel one is not reinterpreted as grayscale+alpha.
        const c = ConstColorRg8(10, 20);
        expect(c.length, equals(2));
        expect(c.r, equals(10));
        expect(c.g, equals(20));
        expect(c.a, equals(255));
      });

      test('a wider color converts to gray+alpha, not red+green', () {
        final c = ColorRgba8(10, 200, 30, 128).convert(numChannels: 2);
        expect(c.length, equals(2));
        expect(c.a, equals(128));
        expect(c.r, equals(ColorRgba8(10, 200, 30, 128).luminance.floor()));
      });

      test('cubic resampling keeps float samples', () {
        // getPixelCubic used to truncate to int, flooring a float format
        // image, whose channels run 0-1, to black.
        for (final nc in [2, 3, 4]) {
          final image = Image(
              width: 8, height: 8, format: Format.float32, numChannels: nc);
          for (final p in image) {
            p
              ..r = 0.25
              ..g = 0.25
              ..b = 0.25;
          }
          final resized =
              copyResize(image, width: 4, interpolation: Interpolation.cubic);
          expect(resized.getPixel(0, 0).r, closeTo(0.25, 1e-6),
              reason: 'numChannels $nc');
        }
      });

      test('bmp keeps the alpha of a grayscale+alpha image', () {
        final image = Image(width: 4, height: 4, numChannels: 2);
        for (final p in image) {
          p
            ..r = 100
            ..a = 200;
        }
        final decoded = decodeBmp(encodeBmp(image))!;
        final p = decoded.getPixel(0, 0);
        expect(p.r, equals(100));
        expect(p.a, equals(200));
      });

      test('png grayscale+alpha round trips', () {
        final png =
            decodePng(File('test/_data/png/png_LA.png').readAsBytesSync())!;
        expect(png.numChannels, equals(2));

        final encoded = encodePng(png);
        final decoded = decodePng(encoded)!;
        expect(decoded.numChannels, equals(2));
        for (final p in png) {
          final p2 = decoded.getPixel(p.x, p.y);
          expect(p2.r, equals(p.r), reason: 'gray at ${p.x},${p.y}');
          expect(p2.a, equals(p.a), reason: 'alpha at ${p.x},${p.y}');
        }

        // The source is mostly transparent; if alpha were reading the gray
        // sample the image would come back opaque.
        var transparent = 0;
        for (final p in png) {
          if (p.a == 0) {
            transparent++;
          }
        }
        expect(transparent, greaterThan(0));
        expect(transparent, lessThan(png.width * png.height));
      });
    });
  });
}
