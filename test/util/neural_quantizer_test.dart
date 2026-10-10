import 'dart:io';
import 'dart:math' show max;

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

/// Expects [indexed], the result of [q].getIndexImage([img]), to use at most
/// [maxColors] and at least [minColors] palette entries, to approximate
/// [img] with a mean (and worst) per pixel error of at most [maxMean]
/// ([maxError]), and [q] to map every used palette color to itself.
void _expectQuantized(Quantizer q, Image img, Image indexed,
    {required int maxColors,
    required int minColors,
    required num maxMean,
    required num maxError}) {
  expect(indexed.width, equals(img.width));
  expect(indexed.height, equals(img.height));
  final pal = indexed.palette!;
  num err(Color c, int i) => [
        (c.r - pal.get(i, 0)).abs(),
        (c.g - pal.get(i, 1)).abs(),
        (c.b - pal.get(i, 2)).abs()
      ].reduce(max);

  final used = <int>{};
  num sum = 0;
  num worst = 0;
  for (final p in img) {
    final i = indexed.getPixel(p.x, p.y).index.toInt();
    used.add(i);
    final e = err(p, i);
    sum += e;
    worst = max(worst, e);
  }
  expect(used.length, lessThanOrEqualTo(maxColors), reason: 'colors used');
  expect(used.length, greaterThanOrEqualTo(minColors), reason: 'colors used');
  expect(sum / (img.width * img.height), lessThan(maxMean), reason: 'mean');
  expect(worst, lessThan(maxError), reason: 'worst error');

  for (final i in used) {
    final c = ColorRgb8(
        pal.get(i, 0).toInt(), pal.get(i, 1).toInt(), pal.get(i, 2).toInt());
    expect(err(c, q.getColorIndex(c)), equals(0), reason: 'palette entry $i');
  }
}

void main() {
  group('Util', () {
    test('neuralQuantizer', () {
      final img = Image(width: 256, height: 256);
      for (final p in img) {
        p
          ..r = p.x
          ..g = p.y;
      }

      final q = NeuralQuantizer(img);
      var img2 = q.getIndexImage(img);
      File('$testOutputPath/util/neuralQuantizer_256_10.bmp')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeBmp(img2));
      // 256 colors spread over a 256x256 red/green ramp leave cells of about
      // 16x16 values, so the error is a few levels per channel.
      _expectQuantized(q, img, img2,
          maxColors: 256, minColors: 192, maxMean: 12, maxError: 48);

      final q_1 = NeuralQuantizer(img, samplingFactor: 1);
      img2 = q_1.getIndexImage(img);
      File('$testOutputPath/util/neuralQuantizer_256_1.bmp')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeBmp(img2));
      _expectQuantized(q_1, img, img2,
          maxColors: 256, minColors: 192, maxMean: 12, maxError: 48);

      final q_100 = NeuralQuantizer(img, samplingFactor: 100);
      img2 = q_100.getIndexImage(img);
      File('$testOutputPath/util/neuralQuantizer_256_100.bmp')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeBmp(img2));
      // Sampling only 1% of the pixels trains a coarser palette.
      _expectQuantized(q_100, img, img2,
          maxColors: 256, minColors: 96, maxMean: 16, maxError: 64);
    });

    test('neuralQuantizer: numColors reflects the requested size', () {
      // numColors (the network size) must equal max(numberOfColors, 4).
      // The internal palette storage is always 256 slots wide regardless.
      final img = solidImage(16, 16, ColorRgb8(100, 150, 200));
      final q = NeuralQuantizer(img, numberOfColors: 64);
      // numColors is the network size which equals max(numberOfColors, 4)
      expect(q.numColors, equals(64));
      // internal palette allocation is always 256 (implementation detail)
      expect(q.palette.numColors, equals(256));
    });

    test('neuralQuantizer: getColorIndex returns valid palette index', () {
      // Any color lookup must return an index within [0, numColors).
      final img = solidImage(16, 16, ColorRgb8(200, 100, 50));
      final q = NeuralQuantizer(img);
      final idx = q.getColorIndex(ColorRgb8(200, 100, 50));
      expect(idx, greaterThanOrEqualTo(0));
      expect(idx, lessThan(q.numColors));
    });

    test('neuralQuantizer: getQuantizedColor returns a valid color', () {
      // getQuantizedColor must return a Color with channels in 0-255.
      final img = solidImage(16, 16, ColorRgb8(80, 160, 240));
      final q = NeuralQuantizer(img);
      final c = q.getQuantizedColor(ColorRgb8(80, 160, 240));
      expect(c.r, inInclusiveRange(0, 255));
      expect(c.g, inInclusiveRange(0, 255));
      expect(c.b, inInclusiveRange(0, 255));
    });

    test('neuralQuantizer: index image has same dimensions as source', () {
      // getIndexImage must preserve width and height.
      final img = Image(width: 32, height: 32);
      for (final p in img) {
        p
          ..r = p.x * 8
          ..g = p.y * 8;
      }
      final q = NeuralQuantizer(img);
      final idx = q.getIndexImage(img);
      expect(idx.width, equals(32));
      expect(idx.height, equals(32));
    });

    test('neuralQuantizer: getColorIndex consistent with getQuantizedColor',
        () {
      // palette.get(idx, ch) must match the channels returned by
      // getQuantizedColor for the same input color.
      final img = solidImage(16, 16, ColorRgb8(128, 64, 32));
      final q = NeuralQuantizer(img);
      final testColor = ColorRgb8(128, 64, 32);
      final idx = q.getColorIndex(testColor);
      final qc = q.getQuantizedColor(testColor);
      expect(q.palette.get(idx, 0), equals(qc.r.toInt()));
      expect(q.palette.get(idx, 1), equals(qc.g.toInt()));
      expect(q.palette.get(idx, 2), equals(qc.b.toInt()));
    });
  });
}
