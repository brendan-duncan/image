import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('Util', () {
    group('OutputBuffer', () {
      test('writes past the initial capacity are preserved', () {
        final out = OutputBuffer(size: 4);
        final expected = <int>[];
        for (var i = 0; i < 1000; ++i) {
          final row = List<int>.generate(i % 13 + 1, (j) => (i + j) & 0xff);
          out.writeBytes(row);
          expected.addAll(row);
          out.writeByte(i & 0xff);
          expected.add(i & 0xff);
        }
        expect(out.length, equals(expected.length));
        expect(out.getBytes(), equals(expected));
      });

      test('writeBuffer appends the input bytes', () {
        final out = OutputBuffer(size: 2)
          ..writeByte(1)
          ..writeBuffer(InputBuffer(Uint8List.fromList([2, 3, 4, 5])));
        expect(out.getBytes(), equals([1, 2, 3, 4, 5]));
      });

      test('many row writes run in linear time', () {
        // Growing by exactly the missing bytes made this quadratic: 4000
        // rows of 4000 bytes copied ~32GB.
        final row = Uint8List(4000);
        final out = OutputBuffer();
        final sw = Stopwatch()..start();
        for (var i = 0; i < 4000; ++i) {
          out.writeBytes(row);
        }
        expect(out.length, equals(4000 * 4000));
        expect(sw.elapsedMilliseconds, lessThan(2000));
      });
    });
  });
}
