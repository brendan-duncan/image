import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('ditherImage', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final orig = i0.clone();
      // The quantizer is deterministic; share it to build the palette once.
      final quantizer = NeuralQuantizer(i0);
      final palette = quantizer.palette;
      final srcMean = imageMean(i0);

      Image dither(DitherKernel kernel, String name,
          {DitherScanOrder scanOrder = DitherScanOrder.zigzag}) {
        final id = ditherImage(i0,
            quantizer: quantizer, kernel: kernel, scanOrder: scanOrder);
        File('$testOutputPath/filter/dither_$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(id));

        // The result is indexed into the quantizer's palette, and the
        // average color is preserved.
        expect(id.width, equals(i0.width), reason: name);
        expect(id.height, equals(i0.height), reason: name);
        expect(id.hasPalette, isTrue, reason: name);
        expect(id.palette!.numColors, equals(palette.numColors), reason: name);
        for (final p in id) {
          expect(p.index, lessThan(palette.numColors), reason: name);
        }
        expect((imageMean(id) - srcMean).abs(), lessThan(5), reason: name);
        return id;
      }

      final atkinson = dither(DitherKernel.atkinson, 'Atkinson');
      final floyd = dither(DitherKernel.floydSteinberg, 'FloydSteinberg',
          scanOrder: DitherScanOrder.raster);
      final falseFloyd =
          dither(DitherKernel.falseFloydSteinberg, 'FalseFloydSteinberg');
      final stucki = dither(DitherKernel.stucki, 'Stucki');
      final burkes = dither(DitherKernel.burkes, 'Burkes');
      final zigzag =
          dither(DitherKernel.floydSteinberg, 'FloydSteinberg_zigzag');
      final bayer = dither(DitherKernel.bayer8x8, 'Bayer8x8');
      final none = dither(DitherKernel.none, 'None');

      // The source is not modified.
      testImageEquals(i0, orig);

      // Every dithering kernel and scan order produces a different pattern
      // than plain nearest-color mapping.
      final results = [atkinson, floyd, falseFloyd, stucki, burkes, zigzag];
      for (final id in [...results, bayer]) {
        expect(imagesAreEqual(id, none), isFalse);
      }
      expect(imagesAreEqual(floyd, zigzag), isFalse);

      // On a uniform gray with a black and white palette, plain mapping
      // turns every pixel black, while dithering mixes in white pixels in
      // proportion to the gray level (100 / 255 ~= 0.39).
      final gray = solidImage(32, 32, ColorRgb8(100, 100, 100));
      final bw = _BlackWhiteQuantizer();
      double whiteFraction(Image id) {
        var white = 0;
        for (final p in id) {
          if (p.index == 1) {
            white++;
          }
        }
        return white / (id.width * id.height);
      }

      expect(
          whiteFraction(
              ditherImage(gray, quantizer: bw, kernel: DitherKernel.none)),
          equals(0));
      // Floyd-Steinberg in raster order diffuses all of the error forward.
      expect(
          whiteFraction(ditherImage(gray,
              quantizer: bw, scanOrder: DitherScanOrder.raster)),
          closeTo(100 / 255, 0.02));
      // Other kernels and orders lose some of the error (Atkinson by design,
      // and taps landing on already visited pixels), so only expect a
      // sizable minority of white pixels.
      for (final kernel in DitherKernel.values) {
        if (kernel == DitherKernel.none) {
          continue;
        }
        for (final order in DitherScanOrder.values) {
          final id = ditherImage(gray,
              quantizer: bw, kernel: kernel, scanOrder: order);
          expect(whiteFraction(id), inInclusiveRange(0.2, 0.45),
              reason: '$kernel $order');
        }
      }
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

    test('dithering a palette image', () {
      // Error used to be diffused into the palette indices, running past the
      // end of the palette.
      final img = decodePng(File('test/_data/png/logo.png').readAsBytesSync())!;
      expect(img.hasPalette, isTrue);
      final dithered = ditherImage(img);
      expect(dithered.width, equals(img.width));
      expect(dithered.hasPalette, isTrue);
    });
  });
}

class _BlackWhiteQuantizer extends Quantizer {
  @override
  final Palette palette = PaletteUint8(2, 3)..setRgb(1, 255, 255, 255);

  @override
  Color getQuantizedColor(Color c) =>
      getColorIndex(c) == 0 ? ColorRgb8(0, 0, 0) : ColorRgb8(255, 255, 255);

  @override
  int getColorIndex(Color c) =>
      getColorIndexRgb(c.r.toInt(), c.g.toInt(), c.b.toInt());

  @override
  int getColorIndexRgb(int r, int g, int b) => r + g + b < 383 ? 0 : 1;
}
