import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

// Collect distinct resolved (r,g,b) triples from an image (palette or direct).
Set<String> _distinctColors(Image img) {
  final colors = <String>{};
  for (final p in img) {
    final rp = img.getPixel(p.x, p.y);
    colors.add('${rp.r.round()},${rp.g.round()},${rp.b.round()}');
  }
  return colors;
}

void main() {
  group('Filter', () {
    test('quantize', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();

      final i0 = decodePng(bytes)!;
      final q0 = quantize(
        i0,
        numberOfColors: 32,
        method: QuantizeMethod.octree,
      );
      File('$testOutputPath/filter/quantize_octree.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(q0));

      final i0_ = decodePng(bytes)!;
      final q0_ = quantize(
        i0_,
        numberOfColors: 32,
        method: QuantizeMethod.octree,
        dither: DitherKernel.floydSteinberg,
      );
      File('$testOutputPath/filter/quantize_octree_dither.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(q0_));

      final i1 = decodePng(bytes)!;
      final q1 = quantize(i1, numberOfColors: 32);
      File('$testOutputPath/filter/quantize_neural.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(q1));

      final i2 = decodePng(bytes)!;
      final q2 = quantize(
        grayscale(i2),
        numberOfColors: 2,
        dither: DitherKernel.floydSteinberg,
      );
      File('$testOutputPath/filter/quantize_neural_dither.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(q2));

      final i3 = decodePng(File('test/_data/png/david.png').readAsBytesSync())!;
      final q3 = quantize(
        i3,
        method: QuantizeMethod.binary,
        dither: DitherKernel.floydSteinberg,
      );
      File('$testOutputPath/filter/quantize_binary.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(q3));
    });

    test('quantize preserves dimensions', () {
      final src = quadrantImage(32, 32);
      final result = quantize(src, numberOfColors: 8);
      // Quantization must not resize the image.
      expect(result.width, equals(32));
      expect(result.height, equals(32));
    });

    test('quantize octree uses at most numberOfColors distinct colors', () {
      // The octree result is palette-indexed; at most numberOfColors entries.
      final src = quadrantImage(32, 32);
      const n = 4;
      final result = quantize(
        src,
        numberOfColors: n,
        method: QuantizeMethod.octree,
      );
      final colors = _distinctColors(result);
      expect(colors.length, lessThanOrEqualTo(n),
          reason: 'octree result has ${colors.length} colors, expected <=$n');
    });

    test('quantize neural uses at most numberOfColors distinct colors', () {
      // Neural-net quantizer also limits the palette to numberOfColors.
      final src = quadrantImage(32, 32);
      const n = 4;
      final result = quantize(src, numberOfColors: n);
      final colors = _distinctColors(result);
      expect(colors.length, lessThanOrEqualTo(n),
          reason: 'neural result has ${colors.length} colors, expected <=$n');
    });

    test('quantize solid-color image stays solid after quantization', () {
      // A single-color image has only one color; any quantizer must keep it.
      final color = ColorRgb8(100, 150, 200);
      final src = solidImage(16, 16, color);
      final result = quantize(
        src,
        numberOfColors: 8,
        method: QuantizeMethod.octree,
      );
      // All resolved pixels must be the same color (within rounding).
      final colors = _distinctColors(result);
      expect(colors.length, equals(1),
          reason: 'solid-color image quantized to ${colors.length} colors');
    });
  });
}
