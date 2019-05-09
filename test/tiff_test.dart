import 'dart:io' as Io;
import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  Io.Directory dir = Io.Directory('res/tiff');
  if (!dir.existsSync()) {
    return;
  }
  List files = dir.listSync();

  group('TIFF/getInfo', () {
    for (var f in files) {
      if (f is! Io.File ||
          (!f.path.endsWith('.tif') && !f.path.endsWith('.tiff'))) {
        continue;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = f.readAsBytesSync();

        TiffInfo info = TiffDecoder().startDecode(bytes);
        if (info == null) {
          throw new ImageException('Unable to parse Tiff info: $name.');
        }

        print(name);
        print('  width: ${info.width}');
        print('  height: ${info.height}');
        print('  bigEndian: ${info.bigEndian}');
        print('  images: ${info.images.length}');
        for (int i = 0; i < info.images.length; ++i) {
          print('  image[$i]');
          print('    width: ${info.images[i].width}');
          print('    height: ${info.images[i].height}');
          print('    photometricType: ${info.images[i].photometricType}');
          print('    compression: ${info.images[i].compression}');
          print('    bitsPerSample: ${info.images[i].bitsPerSample}');
          print('    samplesPerPixel: ${info.images[i].samplesPerPixel}');
          print('    imageType: ${info.images[i].imageType}');
          print('    tiled: ${info.images[i].tiled}');
          print('    tileWidth: ${info.images[i].tileWidth}');
          print('    tileHeight: ${info.images[i].tileHeight}');
          print('    predictor: ${info.images[i].predictor}');
          if (info.images[i].colorMap != null) {
            print(
                '    colorMap.numColors: ${info.images[i].colorMap.length ~/ 3}');
            print('    colorMap: ${info.images[i].colorMap}');
          }
        }
      });
    }
  });

  group('TIFF/decodeImage', () {
    for (var f in files) {
      if (f is! Io.File ||
          (!f.path.endsWith('.tif') && !f.path.endsWith('.tiff'))) {
        continue;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test('$name', () {
        print(name);
        List<int> bytes = f.readAsBytesSync();
        Image image = TiffDecoder().decodeImage(bytes);
        if (image == null) {
          throw new ImageException('Unable to decode TIFF Image: $name.');
        }

        List<int> png = PngEncoder().encodeImage(image);
        new Io.File('out/tif/${name}.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);
      });
    }
  });
}
