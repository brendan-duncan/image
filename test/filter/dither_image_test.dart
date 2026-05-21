import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('ditherImage', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;

      var id = ditherImage(i0, kernel: DitherKernel.atkinson);
      File('$testOutputPath/filter/dither_Atkinson.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(id));

      id = ditherImage(i0);
      File('$testOutputPath/filter/dither_FloydSteinberg.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(id));

      id = ditherImage(i0, kernel: DitherKernel.falseFloydSteinberg);
      File('$testOutputPath/filter/dither_FalseFloydSteinberg.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(id));

      id = ditherImage(i0, kernel: DitherKernel.stucki);
      File('$testOutputPath/filter/dither_Stucki.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(id));

      id = ditherImage(i0, kernel: DitherKernel.none);
      File('$testOutputPath/filter/dither_None.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(id));
    });

    test('ditherImage preserves dimensions', () {
      final src = horizontalGradient(32, 32);
      final result = ditherImage(src);
      // Dithering must not resize the image.
      expect(result.width, equals(32));
      expect(result.height, equals(32));
    });

    test('ditherImage limits distinct colors to palette size', () {
      // The quantizer palette has at most numberOfColors entries; the dithered
      // result can only contain colors drawn from that palette.
      final src = quadrantImage(32, 32);
      final quantizer = NeuralQuantizer(src, numberOfColors: 8);
      final result = ditherImage(src, quantizer: quantizer);
      // Collect distinct (r,g,b) triples from the result (via its palette).
      final colors = <String>{};
      for (final p in result) {
        // getPixel on an indexed image resolves through the palette.
        final resolved = result.getPixel(p.x, p.y);
        colors.add('${resolved.r.round()},${resolved.g.round()},'
            '${resolved.b.round()}');
      }
      // Must use no more distinct colors than the palette size.
      expect(colors.length, lessThanOrEqualTo(8),
          reason: 'dithered result has ${colors.length} colors, expected <=8');
    });

    test('ditherImage(kernel:none) limits colors to palette size', () {
      // With DitherKernel.none getIndexImage is used — strict palette mapping.
      final src = quadrantImage(32, 32);
      final quantizer = NeuralQuantizer(src, numberOfColors: 4);
      final result = ditherImage(
        src,
        quantizer: quantizer,
        kernel: DitherKernel.none,
      );
      // Dimensions must be preserved.
      expect(result.width, equals(32));
      expect(result.height, equals(32));
      final colors = <String>{};
      for (final p in result) {
        final resolved = result.getPixel(p.x, p.y);
        colors.add('${resolved.r.round()},${resolved.g.round()},'
            '${resolved.b.round()}');
      }
      expect(colors.length, lessThanOrEqualTo(4),
          reason: 'indexed result has ${colors.length} colors, expected <=4');
    });
  });
}
