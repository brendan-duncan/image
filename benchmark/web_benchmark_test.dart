// ignore_for_file: avoid_print

/// Benchmarks for the web, where the VM benchmark can't run. Inputs are
/// synthetic, as browsers can't read files.
///
/// ```
/// dart test -p chrome benchmark/web_benchmark_test.dart
/// dart test -p chrome -c dart2wasm benchmark/web_benchmark_test.dart
/// ```
///
/// Each benchmark prints its min and median time over a few runs, after a
/// warm-up run. Peak memory isn't available in a browser.
library;

import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:test/test.dart';

import 'benchmark.dart' show syntheticImage;

const _width = 2000;
const _height = 1500;
const _iterations = 3;

void _bench(String name, Object? Function() run) {
  run(); // warm up
  final times = <double>[];
  for (var i = 0; i < _iterations; ++i) {
    final sw = Stopwatch()..start();
    run();
    times.add(sw.elapsedMicroseconds / 1000);
  }
  times.sort();
  print('${name.padRight(22)}${times.first.toStringAsFixed(1).padLeft(10)}'
      '${times[times.length ~/ 2].toStringAsFixed(1).padLeft(11)}');
}

void main() {
  test('web benchmarks (${_width}x$_height)', () {
    final rgb = syntheticImage(_width, _height, 3);
    final rgba = syntheticImage(_width, _height, 4);
    final jpg = encodeJpg(rgb, quality: 90);
    final png = encodePng(rgb);
    final webp = encodeWebP(rgb, lossless: false);

    print('${'benchmark'.padRight(22)}${'min ms'.padLeft(10)}'
        '${'median ms'.padLeft(11)}');
    _bench('decode_jpeg', () => decodeJpg(jpg));
    _bench('decode_jpeg_scale8', () => decodeJpg(jpg, scale: 8));
    _bench('decode_png', () => decodePng(png));
    _bench('decode_webp_lossy', () => decodeWebP(webp));
    _bench('encode_jpeg', () => encodeJpg(rgb));
    _bench('encode_png', () => encodePng(rgb));
    _bench('encode_png_rgba', () => encodePng(rgba));
    _bench(
        'resize_linear',
        () => copyResize(rgb,
            width: _width ~/ 4, interpolation: Interpolation.linear));
    _bench(
        'resize_cubic',
        () => copyResize(rgb,
            width: _width ~/ 4, interpolation: Interpolation.cubic));
    _bench('gaussian_blur_r5', () => gaussianBlur(rgb.clone(), radius: 5));
    _bench('grayscale', () => grayscale(rgb.clone()));
    _bench('rotate_90', () => copyRotate(rgb, angle: 90));
    expect(Uint8List(1), isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
