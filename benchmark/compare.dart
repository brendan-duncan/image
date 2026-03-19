import 'dart:io';
import 'package:image/image.dart';

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln('Usage: dart run benchmark/compare.dart <a.png> <b.png> [tolerance]');
    exit(2);
  }

  final a = decodePng(File(args[0]).readAsBytesSync());
  final b = decodePng(File(args[1]).readAsBytesSync());
  if (a == null || b == null) {
    stderr.writeln('Failed to decode images');
    exit(1);
  }

  final a4 = a.convert(format: Format.uint8, numChannels: 4, alpha: 255);
  final b4 = b.convert(format: Format.uint8, numChannels: 4, alpha: 255);

  final tol = args.length >= 3 ? int.parse(args[2]) : 0;
  final ok = compareImages(a4, b4, tol);
  if (!ok) {
    exit(1);
  }
}

bool compareImages(Image a, Image b, int tol) {
  if (a.width != b.width || a.height != b.height || a.numChannels != b.numChannels) {
    stderr.writeln('Image shape mismatch');
    return false;
  }

  for (var y = 0; y < a.height; y++) {
    for (var x = 0; x < a.width; x++) {
      final pa = a.getPixel(x, y);
      final pb = b.getPixel(x, y);
      if ((pa.r - pb.r).abs() > tol ||
          (pa.g - pb.g).abs() > tol ||
          (pa.b - pb.b).abs() > tol ||
          (pa.a - pb.a).abs() > tol) {
        stderr.writeln('Mismatch at $x,$y');
        return false;
      }
    }
  }

  print('Images match (tolerance=$tol)');
  return true;
}
