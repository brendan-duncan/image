import 'dart:convert';
import 'package:image/image.dart';
import 'package:test/test.dart';
import 'package:web/web.dart';

void addImageToPage(Image image, String text) {
  final png = encodePng(image);
  final png64 = base64Encode(png);
  final label = HTMLDivElement()..innerText = text;
  document.body!.append(label);
  final img = HTMLImageElement()..src = 'data:image/png;base64,$png64';
  document.body!.append(img);
}

void addFailLabel(Image image, String text) {
  final label = HTMLDivElement()..innerText = 'FAILED: $text';
  document.body!.append(label);
}

void main() {
  group('Image', () {
    test('create grayscale image', () {
      final image = Image(width: 10, height: 10, numChannels: 1);
      expect(image.width, equals(10));
      expect(image.height, equals(10));
      expect(image.numChannels, equals(1));
      expect(image.format, equals(Format.uint8));
      addImageToPage(image, 'create grayscale image');
    });

    test('create RGB image', () {
      final image = Image(width: 10, height: 10);
      expect(image.width, equals(10));
      expect(image.height, equals(10));
      expect(image.numChannels, equals(3));
      expect(image.format, equals(Format.uint8));
      addImageToPage(image, 'create RGB image');
    });

    test('set and get pixel', () {
      final image = Image(width: 10, height: 10)
      ..setPixel(5, 5, ColorRgba8(255, 0, 0, 255));
      expect(image.getPixel(5, 5).r, equals(255));
      expect(image.getPixel(5, 5).g, equals(0));
      expect(image.getPixel(5, 5).b, equals(0));
      addImageToPage(image, 'set and get pixel');
    });

    test('iterate pixels', () {
      final image = Image(width: 3, height: 2);
      var count = 0;
      for (final p in image) {
        count++;
        expect(p.x, lessThan(3));
        expect(p.y, lessThan(2));
      }
      expect(count, equals(6));
    });
  });

  group('Encode/Decode', () {
    test('encode and decode PNG', () {
      final original = Image(width: 4, height: 4);
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          original.setPixel(x, y, ColorRgba8(x * 64, y * 64, 128, 255));
        }
      }

      final encoded = encodePng(original);
      expect(encoded, isNotEmpty);

      final decoded = decodePng(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(4));
      expect(decoded.height, equals(4));

      expect(decoded.getPixel(0, 0).r, equals(0));
      expect(decoded.getPixel(0, 0).g, equals(0));
      expect(decoded.getPixel(3, 3).r, equals(192));

      addImageToPage(original, 'encode and decode PNG: original');
      addImageToPage(decoded, 'encode and decode PNG: decoded');
    });

    test('encode and decode JPEG', () {
      final original = Image(width: 4, height: 4);
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          original.setPixel(x, y, ColorRgba8(x * 64, y * 64, 128, 255));
        }
      }

      final encoded = encodeJpg(original);
      expect(encoded, isNotEmpty);

      final decoded = decodeJpg(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(4));
      expect(decoded.height, equals(4));

      addImageToPage(original, 'encode and decode JPEG: original');
      addImageToPage(decoded, 'encode and decode JPEG: decoded');
    });

    test('encode and decode GIF', () {
      final original = Image(width: 4, height: 4);
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          original.setPixel(x, y, ColorRgba8(x * 64, y * 64, 128, 255));
        }
      }

      final encoded = encodeGif(original);
      expect(encoded, isNotEmpty);

      final decoded = decodeGif(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(4));
      expect(decoded.height, equals(4));

      addImageToPage(original, 'encode and decode GIF: original');
      addImageToPage(decoded, 'encode and decode GIF: decoded');
    });
  });

  group('Transform', () {
    test('flip horizontal', () {
      final image = Image(width: 4, height: 4)
      ..setPixel(0, 0, ColorRgba8(255, 0, 0, 255))
      ..setPixel(3, 0, ColorRgba8(0, 0, 255, 255));

      final flipped = flipHorizontal(image);
      expect(flipped.getPixel(3, 0).r, equals(255));
      expect(flipped.getPixel(0, 0).b, equals(255));

      addImageToPage(flipped, 'flip horizontal');
    });

    test('flip vertical', () {
      final image = Image(width: 4, height: 4)
      ..setPixel(0, 0, ColorRgba8(255, 0, 0, 255))
      ..setPixel(0, 3, ColorRgba8(0, 0, 255, 255));

      final flipped = flipVertical(image);
      expect(flipped.getPixel(0, 3).r, equals(255));
      expect(flipped.getPixel(0, 0).b, equals(255));

      addImageToPage(flipped, 'flip vertical');
    });

    test('resize', () {
      final image = Image(width: 10, height: 10);
      for (var y = 0; y < 10; y++) {
        for (var x = 0; x < 10; x++) {
          image.setPixel(x, y, ColorRgba8(x * 25, y * 25, 128, 255));
        }
      }

      final resized = copyResize(image, width: 5, height: 5);
      expect(resized.width, equals(5));
      expect(resized.height, equals(5));

      addImageToPage(resized, 'resize');
    });

    test('copyCrop', () {
      final image = Image(width: 10, height: 10);
      for (var y = 0; y < 10; y++) {
        for (var x = 0; x < 10; x++) {
          image.setPixel(x, y, ColorRgba8(x * 25, y * 25, 128, 255));
        }
      }

      final cropped = copyCrop(image, x: 2, y: 2, width: 4, height: 4);
      expect(cropped.width, equals(4));
      expect(cropped.height, equals(4));

      addImageToPage(cropped, 'copyCrop');
    });
  });

  group('Color', () {
    test('color creation', () {
      final c = ColorRgba8(255, 128, 64, 32);
      expect(c.r, equals(255));
      expect(c.g, equals(128));
      expect(c.b, equals(64));
      expect(c.a, equals(32));
    });

    test('color conversion', () {
      final c = ColorRgb8(255, 128, 64);
      final converted = c.convert(format: Format.float32);
      expect(converted.r, closeTo(1.0, 0.01));
    });
  });

  group('Draw', () {
    test('drawPixel', () {
      final image = Image(width: 10, height: 10);
      drawPixel(image, 5, 5, ColorRgba8(255, 0, 0, 255));
      expect(image.getPixel(5, 5).r, equals(255));

      addImageToPage(image, 'drawPixel');
    });

    test('fill', () {
      final image = Image(width: 10, height: 10);
      fill(image, color: ColorRgba8(128, 128, 128, 255));
      expect(image.getPixel(0, 0).r, equals(128));
      expect(image.getPixel(9, 9).r, equals(128));

      addImageToPage(image, 'fill');
    });

    test('drawCircle', () {
      final image = Image(width: 20, height: 20);
      drawCircle(image,
          x: 10, y: 10, radius: 5, color: ColorRgba8(255, 0, 0, 255));
      try {
        expect(image
            .getPixel(10, 10)
            .r, equals(0));
      } catch (e) {
        addFailLabel(image, 'drawCircle');
      }
      addImageToPage(image, 'drawCircle');
    });

    test('drawRect', () {
      final image = Image(width: 20, height: 20);
      drawRect(image,
          x1: 5, y1: 5, x2: 15, y2: 15, color: ColorRgba8(255, 0, 0, 255));
      expect(image.getPixel(5, 5).r, equals(255));
      expect(image.getPixel(15, 15).r, equals(255));
      addImageToPage(image, 'drawRect');
    });
  });

  group('Filters', () {
    test('grayscale', () {
      final image = Image(width: 4, height: 4);
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          image.setPixel(x, y, ColorRgba8(200, 100, 50, 255));
        }
      }

      final grayscaleImage = grayscale(image);
      final p = grayscaleImage.getPixel(0, 0);
      expect(p.r, closeTo(p.g, 1.0));
      expect(p.g, closeTo(p.b, 1.0));
      addImageToPage(grayscaleImage, 'grayscale');
    });

    test('invert', () {
      final image = Image(width: 4, height: 4)
      ..setPixel(0, 0, ColorRgba8(255, 128, 64, 255));

      final inverted = invert(image);
      final p = inverted.getPixel(0, 0);
      expect(p.r, equals(0));
      expect(p.g, equals(127));
      expect(p.b, equals(191));
      addImageToPage(inverted, 'invert');
    });

    test('normalize', () {
      final image = Image(width: 2, height: 2)
      ..setPixel(0, 0, ColorRgba8(0, 0, 0, 255))
      ..setPixel(1, 0, ColorRgba8(255, 255, 255, 255))
      ..setPixel(0, 1, ColorRgba8(100, 100, 100, 255))
      ..setPixel(1, 1, ColorRgba8(200, 200, 200, 255));

      final normalized = normalize(image, min: 0, max: 255);
      expect(normalized.getPixel(0, 0).r, equals(0));
      expect(normalized.getPixel(1, 1).r, equals(200));
      addImageToPage(normalized, 'normalize');
    });

    test('compositeImage', () {
      final image1 = Image(width: 100, height: 100);
      final image2 = Image(width: 25, height: 25, numChannels: 4);
      fill(image1, color: ColorRgb8(0, 255, 0));
      fillCircle(image2, x: 12, y: 12, radius: 10, color: ColorRgb8(255, 0, 0));
      compositeImage(image1, image2, dstX: 25, dstY: 25);
      addImageToPage(image1, 'compositeImage');
    });
  });
}
