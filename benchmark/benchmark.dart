// ignore_for_file: avoid_print

/// Benchmarks for decoding, encoding and processing.
///
/// Each benchmark runs in its own process so peak memory can be attributed to
/// it. Inputs are generated once from a deterministic synthetic image and
/// cached in `.dart_tool/image_benchmark/`.
///
/// ```
/// dart run benchmark/benchmark.dart [options]
///
/// # AOT, closest to Flutter release builds:
/// dart compile exe benchmark/benchmark.dart -o build/benchmark.exe
/// build/benchmark.exe [options]
/// ```
///
/// Options:
///   --size=WxH        Synthetic image size (default 4000x3000, 12MP).
///   --iterations=N    Timed iterations after one warm-up (default 3).
///   --filter=a,b      Only run benchmarks whose name contains a or b.
///   --list            List benchmark names.
///
/// Reported: min and median time, and the peak RSS of the first (warm-up)
/// run above the baseline measured after the inputs are loaded (MB). Peak RSS
/// includes garbage that has not been collected yet, so it is an upper bound
/// on live memory, and it is affected by GC timing.
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart';

class Benchmark {
  final String name;

  /// Loads inputs; not timed and included in the memory baseline.
  final Object Function(Inputs) setup;

  /// The timed operation. The result is kept alive until timing ends.
  final Object? Function(Object input) run;

  const Benchmark(this.name, this.setup, this.run);
}

final benchmarks = <Benchmark>[
  // Decoding
  Benchmark('decode_jpeg', (i) => i.file('rgb.jpg'), (b) => decodeJpg(_b(b))),
  Benchmark('decode_jpeg_scale2', (i) => i.file('rgb.jpg'),
      (b) => decodeJpg(_b(b), scale: 2)),
  Benchmark('decode_jpeg_scale8', (i) => i.file('rgb.jpg'),
      (b) => decodeJpg(_b(b), scale: 8)),
  Benchmark(
      'decode_png_rgb', (i) => i.file('rgb.png'), (b) => decodePng(_b(b))),
  Benchmark(
      'decode_png_rgba', (i) => i.file('rgba.png'), (b) => decodePng(_b(b))),
  Benchmark('decode_webp_lossy', (i) => i.file('rgb_lossy.webp'),
      (b) => decodeWebP(_b(b))),
  Benchmark(
      'decode_image_jpeg', (i) => i.file('rgb.jpg'), (b) => decodeImage(_b(b))),
  Benchmark('decode_anim_gif', (i) => i.testData('gif/lighthouse.gif'),
      (b) => decodeGif(_b(b))),
  Benchmark('decode_anim_webp', (i) => i.testData('webp/animated_lossy.webp'),
      (b) => decodeWebP(_b(b))),
  Benchmark('decode_anim_apng', (i) => i.testData('png/apng/test_apng2.png'),
      (b) => decodePng(_b(b))),

  // Encoding
  Benchmark('encode_jpeg', (i) => i.rgb, (img) => encodeJpg(_i(img))),
  Benchmark('encode_png_rgb', (i) => i.rgb, (img) => encodePng(_i(img))),
  Benchmark('encode_png_rgba', (i) => i.rgba, (img) => encodePng(_i(img))),
  Benchmark('encode_bmp_rgb', (i) => i.rgb, (img) => encodeBmp(_i(img))),
  Benchmark('encode_bmp_gray', (i) => i.gray, (img) => encodeBmp(_i(img))),
  Benchmark('encode_tga', (i) => i.rgb, (img) => encodeTga(_i(img))),
  Benchmark('encode_tiff', (i) => i.rgb, (img) => encodeTiff(_i(img))),
  Benchmark('encode_gif', (i) => i.small, (img) => encodeGif(_i(img))),

  // Processing
  Benchmark('resize_nearest', (i) => i.rgb,
      (img) => _resize(img, Interpolation.nearest)),
  Benchmark('resize_linear', (i) => i.rgb,
      (img) => _resize(img, Interpolation.linear)),
  Benchmark(
      'resize_cubic', (i) => i.rgb, (img) => _resize(img, Interpolation.cubic)),
  Benchmark('resize_average', (i) => i.rgb,
      (img) => _resize(img, Interpolation.average)),
  // resize works in place, so each run resizes a fresh copy.
  Benchmark('resize_inplace_linear', (i) => i.rgb,
      (img) => _resizeInPlace(img, Interpolation.linear)),
  Benchmark('resize_inplace_average', (i) => i.rgb,
      (img) => _resizeInPlace(img, Interpolation.average)),
  // A portrait phone photo: copyResize bakes the orientation first.
  Benchmark('resize_portrait', (i) => i.rgb..exif.imageIfd.orientation = 6,
      (img) => _resize(img, Interpolation.linear)),
  Benchmark('gaussian_blur_r5', (i) => i.rgb,
      (img) => gaussianBlur(_i(img).clone(), radius: 5)),
  Benchmark('convolution_sharpen', (i) => i.small,
      (img) => convolution(_i(img).clone(), filter: _sharpen)),
  Benchmark('sobel', (i) => i.small, (img) => sobel(_i(img).clone())),
  Benchmark('rotate_90', (i) => i.rgb, (img) => copyRotate(_i(img), angle: 90)),
  Benchmark('crop', (i) => i.rgb,
      (img) => copyCrop(_i(img), x: 500, y: 400, width: 2000, height: 1500)),
  Benchmark('flip_vertical', (i) => i.rgb, (img) => flipVertical(_i(img))),
  Benchmark('grayscale', (i) => i.rgb, (img) => grayscale(_i(img).clone())),
  Benchmark('gamma', (i) => i.rgb, (img) => gamma(_i(img).clone(), gamma: 2.2)),
  Benchmark('adjust_color', (i) => i.rgb,
      (img) => adjustColor(_i(img).clone(), contrast: 1.2, brightness: 1.1)),
];

const _sharpen = [0, -1, 0, -1, 5, -1, 0, -1, 0];

Uint8List _b(Object o) => o as Uint8List;
Image _i(Object o) => o as Image;
Image _resizeInPlace(Object img, Interpolation interpolation) {
  final src = _i(img).clone();
  return resize(src,
      width: src.width ~/ 4,
      height: src.height ~/ 4,
      interpolation: interpolation);
}

Image _resize(Object img, Interpolation interpolation) {
  final src = _i(img);
  return copyResize(src,
      width: src.width ~/ 4,
      height: src.height ~/ 4,
      interpolation: interpolation);
}

/// Benchmark inputs, generated lazily and cached on disk.
class Inputs {
  final int width;
  final int height;
  final Directory cacheDir;

  Inputs(this.width, this.height)
      : cacheDir = Directory('.dart_tool/image_benchmark/${width}x$height');

  Image get rgb => syntheticImage(width, height, 3);
  Image get rgba => syntheticImage(width, height, 4);
  Image get gray => syntheticImage(width, height, 1);

  /// A smaller image for benchmarks that are too slow at full size.
  Image get small => syntheticImage(width ~/ 4, height ~/ 4, 3);

  Uint8List testData(String path) => File('test/_data/$path').readAsBytesSync();

  Uint8List file(String name) =>
      File('${cacheDir.path}/$name').readAsBytesSync();

  /// Generates any missing cached files.
  void generate() {
    final generators = <String, Uint8List Function()>{
      'rgb.jpg': () => encodeJpg(rgb, quality: 90),
      'rgb.png': () => encodePng(rgb),
      'rgba.png': () => encodePng(rgba),
      'rgb_lossy.webp': () => encodeWebP(rgb, lossless: false),
    };
    cacheDir.createSync(recursive: true);
    for (final entry in generators.entries) {
      final f = File('${cacheDir.path}/${entry.key}');
      if (!f.existsSync()) {
        stdout.write('Generating ${f.path}... ');
        f.writeAsBytesSync(entry.value());
        print('done');
      }
    }
  }
}

/// A deterministic, photo-like image: smooth gradients, soft shapes and
/// fine noise, so compressed sizes are realistic.
Image syntheticImage(int width, int height, int numChannels) {
  final image = Image(width: width, height: height, numChannels: numChannels);
  final data = image.data!.toUint8List();
  final rowStride = image.data!.rowStride;
  var seed = 12345;
  for (var y = 0; y < height; ++y) {
    final fy = y / height;
    var i = y * rowStride;
    for (var x = 0; x < width; ++x) {
      final fx = x / width;
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final noise = (seed >> 16) % 17 - 8;
      final wave = sin(fx * 12.0 + sin(fy * 7.0) * 2.0) * 40.0;
      final d = (fx - 0.6) * (fx - 0.6) + (fy - 0.4) * (fy - 0.4);
      final spot = d < 0.04 ? 60.0 : 0.0;
      final r = 90 + 120 * fx + wave + spot + noise;
      final g = 70 + 100 * fy - wave * 0.5 + noise;
      final b = 150 - 80 * fx + 60 * fy + spot * 0.5 + noise;
      if (numChannels == 1) {
        data[i++] = (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);
      } else {
        data[i++] = r.round().clamp(0, 255);
        data[i++] = g.round().clamp(0, 255);
        data[i++] = b.round().clamp(0, 255);
        if (numChannels == 4) {
          data[i++] = (255 * (0.5 + 0.5 * sin(fx * 9.0 + fy * 5.0))).round();
        }
      }
    }
  }
  return image;
}

Future<void> main(List<String> args) async {
  final options = {
    for (final a in args.where((a) => a.startsWith('--')))
      a.substring(2).split('=').first:
          a.contains('=') ? a.substring(a.indexOf('=') + 1) : ''
  };
  final size = (options['size'] ?? '4000x3000').split('x').map(int.parse);
  final inputs = Inputs(size.first, size.last);
  final iterations = int.parse(options['iterations'] ?? '3');

  if (options.containsKey('run')) {
    _runOne(options['run']!, inputs, iterations);
    return;
  }

  if (options.containsKey('list')) {
    for (final b in benchmarks) {
      print(b.name);
    }
    return;
  }

  final filters = options['filter']?.split(',') ?? const <String>[];
  final selected = benchmarks
      .where((b) => filters.isEmpty || filters.any(b.name.contains))
      .toList();

  inputs.generate();

  final aot = !Platform.resolvedExecutable
      .split(Platform.pathSeparator)
      .last
      .startsWith('dart');
  print('${aot ? 'AOT' : 'JIT'}, ${inputs.width}x${inputs.height}, '
      '$iterations iterations');
  print('${'benchmark'.padRight(22)}${'min ms'.padLeft(10)}'
      '${'median ms'.padLeft(11)}${'peak MB'.padLeft(10)}');

  for (final b in selected) {
    final childArgs = [
      if (!aot) Platform.script.toFilePath(),
      '--run=${b.name}',
      '--size=${inputs.width}x${inputs.height}',
      '--iterations=$iterations',
    ];
    final result = await Process.run(Platform.resolvedExecutable, childArgs);
    final out = (result.stdout as String).trim();
    if (result.exitCode != 0 || !out.startsWith('RESULT ')) {
      print('${b.name.padRight(22)}  FAILED: ${result.stderr}'.trim());
      continue;
    }
    final v = out.substring(7).split(' ');
    print('${b.name.padRight(22)}${v[0].padLeft(10)}${v[1].padLeft(11)}'
        '${v[2].padLeft(10)}');
  }
}

void _runOne(String name, Inputs inputs, int iterations) {
  final b = benchmarks.firstWhere((b) => b.name == name);
  final input = b.setup(inputs);
  final baseline = ProcessInfo.currentRss;

  final times = <double>[];
  var peakMb = 0.0;
  for (var i = 0; i <= iterations; ++i) {
    final sw = Stopwatch()..start();
    final result = b.run(input);
    sw.stop();
    if (result == null) {
      throw StateError('$name returned null');
    }
    if (i == 0) {
      // Measured on the first run only, so garbage left over from earlier
      // runs isn't counted.
      peakMb = max(0, ProcessInfo.maxRss - baseline) / (1024 * 1024);
    } else {
      times.add(sw.elapsedMicroseconds / 1000);
    }
  }
  times.sort();
  print('RESULT ${times.first.toStringAsFixed(1)} '
      '${times[times.length ~/ 2].toStringAsFixed(1)} '
      '${peakMb.toStringAsFixed(1)}');
}
