import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  var dir = Directory('test/res/psd');
  var files = dir.listSync();

  group('PSD', () {
    for (var f in files) {
      if (f is! File || !f.path.endsWith('.psd')) {
        continue;
      }

      var name = f.path.split(RegExp(r'(/|\\)')).last;
      test(name, () {
        print('Decoding $name');

        var psd = PsdDecoder().decodeImage((f as File).readAsBytesSync());

        if (psd != null) {
          var outPng = PngEncoder().encodeImage(psd);
          File('.dart_tool/out/psd/$name.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(outPng);
        } else {
          throw 'Unable to decode $name';
        }
      });
    }
  });
}
