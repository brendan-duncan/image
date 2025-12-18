import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart';
import 'package:test/test.dart';

final testOutputPath = '${Directory.systemTemp.createTempSync().path}/out';
//const testOutputPath = './_out';

int hashImage(Image image) {
  var hash = 0;
  var x = 0;
  var y = 0;

  final rgbaDouble = Float64List(4);
  final rgba8 = Uint8List.view(rgbaDouble.buffer);
  for (final p in image) {
    for (var ci = 0; ci < p.length; ++ci) {
      rgbaDouble[ci] = p[ci].toDouble();
    }
    hash = getCrc32(rgba8, hash);
    if (x != p.x || y != p.y) {
      throw ImageException('Invalid Pixel index');
    }
    x++;
    if (x == image.width) {
      x = 0;
      y++;
    }
  }

  return hash;
}

void testImageEquals(Image image, Image image2) {
  expect(image2.width, equals(image.width));
  expect(image2.height, equals(image.height));
  expect(image2.numChannels, equals(image.numChannels));
  expect(image2.hasPalette, equals(image.hasPalette));
  final c = image.iterator..moveNext();
  for (var p2 in image2) {
    final p1 = c.current;
    expect(p2, equals(p1));
    c.moveNext();
  }
}

Future<void> testImageConversions(Image image) async {
  for (final format in Format.values) {
    for (var nc = 1; nc <= 4; ++nc) {
      final ic =
          image.convert(format: format, numChannels: nc, withPalette: true);
      expect(ic.width, equals(image.width));
      expect(ic.height, equals(image.height));
      expect(ic.format, equals(format));
      expect(ic.numChannels, equals(nc));
      /*if (nc < 4 &&
          (format == Format.uint1 || format == Format.uint2 ||
              format == Format.uint4 ||
              (format == Format.uint8 && nc == 1))) {
        expect(ic.palette, isNotNull);
      } else {
        expect(ic.palette, isNull);
      }*/

      final oc = ic.convert(format: Format.uint8, numChannels: 4);
      final fnc = image.hasPalette ? 1 : image.numChannels;
      final dbgName = '$testOutputPath/image/${image.format.name}/'
          '${image.format.name}_${fnc}_to_${format.name}_$nc.png';
      //print(dbgName);
      await encodePngFile(dbgName, oc);

      /*final op = image.getPixel(0, 0);
      for (final np in ic) {
        final nr = (np.rNormalized * 255).floor();
        final or = (op.rNormalized * 255).floor();
        expect(nr, equals(or));
        op.moveNext();
      }*/
    }
  }
}
