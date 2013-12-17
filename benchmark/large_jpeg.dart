import 'dart:io' as Io;
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:dart_image/dart_image.dart';

class LargeJpegBenchmark extends BenchmarkBase {
  JpegDecoder jpegDecoder;
  List<int> jpegBytes;
  Stopwatch timer = new Stopwatch();

  LargeJpegBenchmark() :
    super("LargeJpeg");

  static void main() {
    new LargeJpegBenchmark().report();
  }

  void run() {
    var t1 = timer.elapsed;
    var image = jpegDecoder.decode(jpegBytes);
    print('DECODE TIME: ${timer.elapsed - t1}');
  }

  void setup() {
    Io.File file = new Io.File('res/diamond_plate_texture.jpg');
    file.openSync();

    jpegBytes = file.readAsBytesSync();
    jpegDecoder = new JpegDecoder();
    timer.start();
  }

  void teardown() {
    print('TOTAL TIME: ${timer.elapsed}');
  }
}

main() {
  LargeJpegBenchmark.main();
}
