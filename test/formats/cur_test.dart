import 'dart:io';

import 'package:image/image.dart';
import 'package:image/src/formats/cur_encoder.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Format', () {
    group('cur', () {
      test('encode', () {
        final image = Image(width: 64, height: 64)
          ..clear(ColorRgb8(100, 200, 255));

        // Encode the image to CUR
        final png = CurEncoder().encode(image);
        File('$testOutputPath/cur/encode.cur')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);

        // CUR header: reserved(0,0), type=2 (LE), image-count=1
        expect(png[0], equals(0), reason: 'reserved byte 0');
        expect(png[1], equals(0), reason: 'reserved byte 1');
        // type field is little-endian uint16 == 2
        expect(png[2] | (png[3] << 8), equals(2), reason: 'CUR type == 2');
        // single image in directory
        expect(png[4] | (png[5] << 8), equals(1), reason: 'image count == 1');
        // encoded bytes must be non-trivially sized
        expect(png.length, greaterThan(6));

        final image2 = Image(width: 64, height: 64)
          ..clear(ColorRgb8(100, 255, 200));

        final png2 = CurEncoder(
          hotSpots: {1: Point(64, 64), 0: Point(64, 64)},
        ).encodeImages([image, image2]);
        File('$testOutputPath/cur/encode2.cur')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png2);

        // two images in directory
        expect(
          png2[4] | (png2[5] << 8),
          equals(2),
          reason: 'image count == 2',
        );
        // type field still 2
        expect(png2[2] | (png2[3] << 8), equals(2), reason: 'CUR type == 2');

        final image3 = Image(width: 32, height: 64)
          ..clear(ColorRgb8(255, 100, 200));

        final png3 = CurEncoder().encodeImages([image, image2, image3]);
        File('$testOutputPath/cur/encode3.cur')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png3);

        // three images in directory
        expect(
          png3[4] | (png3[5] << 8),
          equals(3),
          reason: 'image count == 3',
        );
      });
    });
  });
}
