import 'dart:typed_data';
import 'package:image/image.dart';
import 'package:test/test.dart';


void imageTest() {
  group('image', () {
    test('empty', () {
      final i0 = Image.empty();
      expect(i0.isValid, equals(false));

      final i1 = Image.empty();
      expect(i1.isValid, equals(false));
    });

    test('fromBytes', () {
      const w = 256;
      const h = 256;
      const w2 = 300;
      const stride = w2 * 3;
      final bytes = Uint8List(h * stride);
      for (var y = 0, i = 0; y < h; ++y) {
        for (var x = 0; x < w2; ++x) {
          bytes[i++] = x < 256 ? x : 255;
          bytes[i++] = x < 256 ? y : 0;
          bytes[i++] = x < 256 ? 0 : 255;
        }
      }
      final img = Image.fromBytes(w, h, bytes.buffer, rowStride: stride);
      expect(img.width, equals(w));
      expect(img.height, equals(h));
      expect(img.numChannels, equals(3));
      var differs = false;
      for (var y = 0; y < w && !differs; ++y) {
        for (var x = 0; x < h; ++x) {
          final p = img.getPixel(x, y);
          if (p.r != x || p.g != y || p.b != 0) {
            differs = true;
            break;
          }
        }
      }
      expect(differs, equals(false));
    });

    test('getPixel iterator', () {
      final i0 = Image(width: 10, height: 10);
      final p = i0.getPixel(0, 5);
      int x = 0;
      int y = 5;
      do {
        expect(x, equals(p.x));
        expect(y, equals(p.y));
        x++;
        if (x == 10) {
          x = 0;
          y++;
        }
      } while (p.moveNext());
    });

    test('getRange', () {
      final i0 = Image(width: 10, height: 10);
      int x = 0;
      int y = 0;
      final iter = i0.getRange(0, 0, 10, 10);
      while (iter.moveNext()) {
        expect(x, equals(iter.current.x));
        expect(y, equals(iter.current.y));
        x++;
        if (x == 10) {
          x = 0;
          y++;
        }
      }
    });
  });
}
