import 'dart:io';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

// decodeImageLargest returns the biggest icon stored in each .ico file.
const _expectedLargest = <String, List<int>>{
  'microsoft-favicon.ico': [128, 128],
  'orf-favicon.ico': [64, 64],
  'wikipedia-favicon.ico': [48, 48],
};

void main() {
  group('Format', () {
    group('ico', () {
      test('encode palette', () async {
        var img = await decodePngFile('test/_data/png/buck_8.png');
        img = copyResize(img!, width: 256);
        img = vignette(img);
        final ico = IcoEncoder().encode(img);
        File('$testOutputPath/ico/buck_8.ico')
          ..createSync(recursive: true)
          ..writeAsBytesSync(ico);

        // The encoded ICO decodes back to the same dimensions.
        final decoded = IcoDecoder().decodeImageLargest(ico);
        expect(decoded, isNotNull);
        expect(decoded!.width, equals(img.width));
        expect(decoded.height, equals(img.height));
      });

      test('encode', () {
        final image = Image(width: 64, height: 64)
          ..clear(ColorRgb8(100, 200, 255));

        // Encode the image to ICO
        final ico = IcoEncoder().encode(image);
        File('$testOutputPath/ico/encode.ico')
          ..createSync(recursive: true)
          ..writeAsBytesSync(ico);

        // A solid image round-trips through ICO with its size and color.
        final decoded = IcoDecoder().decodeImageLargest(ico)!;
        expect(decoded.width, equals(64));
        expect(decoded.height, equals(64));
        final p = decoded.getPixel(0, 0);
        expect([p.r, p.g, p.b], equals([100, 200, 255]));

        final image2 = Image(width: 64, height: 64)
          ..clear(ColorRgb8(100, 255, 200));

        final ico2 = IcoEncoder().encodeImages([image, image2]);
        File('$testOutputPath/ico/encode2.ico')
          ..createSync(recursive: true)
          ..writeAsBytesSync(ico2);
        // A multi-image ICO still decodes to one of its 64x64 entries.
        final decoded2 = IcoDecoder().decodeImageLargest(ico2)!;
        expect(decoded2.width, equals(64));
        expect(decoded2.height, equals(64));

        final image3 = Image(width: 32, height: 64)
          ..clear(ColorRgb8(255, 100, 200));

        final ico3 = IcoEncoder().encodeImages([image, image2, image3]);
        File('$testOutputPath/ico/encode3.ico')
          ..createSync(recursive: true)
          ..writeAsBytesSync(ico3);
        expect(IcoDecoder().decodeImageLargest(ico3), isNotNull);
      });

      final dir = Directory('test/_data/ico');
      if (!dir.existsSync()) {
        return;
      }

      for (final file in dir.listSync().whereType<File>()) {
        if (!file.path.endsWith('.ico')) {
          continue;
        }

        final name = file.uri.pathSegments.last;
        test('decode $name', () {
          final bytes = file.readAsBytesSync();
          final image = IcoDecoder().decodeImageLargest(bytes)!;
          final i8 = image.convert(format: Format.uint8);
          File('$testOutputPath/ico/$name.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(encodePng(i8));

          // The largest stored icon has the expected dimensions.
          final size = _expectedLargest[name];
          if (size != null) {
            expect(image.width, equals(size[0]), reason: '$name width');
            expect(image.height, equals(size[1]), reason: '$name height');
          }
        });
      }
    });
  });
}
