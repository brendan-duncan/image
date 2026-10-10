// Malformed and malicious inputs must fail quickly and cleanly: no hangs, no
// huge allocations, and no errors other than ImageException.
//
// The inputs are built in memory, so this also runs on the web.

import 'dart:typed_data';

import 'package:archive/archive.dart' show getCrc32;
import 'package:image/image.dart';
import 'package:test/test.dart';

final _throwsImageException = throwsA(isA<ImageException>());

// An animation of [numFrames] frames of [width] x [height].
Image _animation(int width, int height, int numFrames) {
  final image = Image(width: width, height: height);
  for (var i = 1; i < numFrames; ++i) {
    image.addFrame(
        Image(width: width, height: height)..clear(ColorRgb8(i * 40, 0, 0)));
  }
  return image;
}

// A JPEG holding an APP1 EXIF segment with the given TIFF structure.
Uint8List _jpegWithExif(List<int> tiff) {
  final app1 = [...'Exif'.codeUnits, 0, 0, ...tiff];
  final length = app1.length + 2;
  return Uint8List.fromList([
    0xff, 0xd8, //
    0xff, 0xe1, length >> 8, length & 0xff, ...app1,
    0xff, 0xd9,
  ]);
}

void main() {
  group('malformed input', () {
    test('EXIF IFDs that form a cycle', () {
      // Two empty IFDs that point at each other.
      final jpeg = _jpegWithExif([
        0x49, 0x49, 0x2a, 0x00, 8, 0, 0, 0, // little endian, first IFD at 8
        0, 0, 14, 0, 0, 0, // 0 entries, next IFD at 14
        0, 0, 8, 0, 0, 0, // 0 entries, next IFD at 8
      ]);
      final exif = decodeJpgExif(jpeg);
      expect(exif, isNotNull);
      expect(exif!.directories.length, lessThanOrEqualTo(2));
    });

    test('TIFF IFDs that form a cycle', () {
      final tiff = encodeTiff(Image(width: 2, height: 2));
      final data = ByteData.sublistView(tiff);
      final bigEndian = tiff[0] == 0x4d;
      final endian = bigEndian ? Endian.big : Endian.little;
      // Point the first IFD's next-IFD offset back at itself.
      final ifd = data.getUint32(4, endian);
      final entries = data.getUint16(ifd, endian);
      data.setUint32(ifd + 2 + entries * 12, ifd, endian);

      expect(TiffDecoder().isValidFile(tiff), isTrue);
      final image = decodeTiff(tiff);
      expect(image, isNotNull);
      expect(image!.numFrames, equals(1));
      expect(decodeImage(tiff)?.numFrames, equals(1));
    });
  });

  test('isValidFile with truncated data', () {
    final small = Image(width: 8, height: 8);
    final files = [
      encodePng(small),
      encodeJpg(small),
      encodeGif(small),
      encodeWebP(small),
      encodeTiff(small),
      encodeBmp(small),
      encodeTga(small),
      encodeIco(small),
      encodePvr(small),
      Uint8List.fromList([0x76, 0x2f, 0x31, 0x01, 2]),
      Uint8List.fromList('8BPS'.codeUnits),
    ];
    final decoders = <Decoder Function()>[
      JpegDecoder.new,
      PngDecoder.new,
      GifDecoder.new,
      WebPDecoder.new,
      TiffDecoder.new,
      PsdDecoder.new,
      ExrDecoder.new,
      BmpDecoder.new,
      PnmDecoder.new,
      TgaDecoder.new,
      IcoDecoder.new,
      PvrDecoder.new,
    ];
    for (final file in files) {
      for (var n = 0; n < file.length && n < 64; ++n) {
        final bytes = Uint8List.sublistView(file, 0, n);
        for (final decoder in decoders) {
          expect(() => decoder().isValidFile(bytes), returnsNormally);
        }
        expect(() => findDecoderForData(bytes), returnsNormally);
      }
    }
  });

  test('truncated files throw only ImageException', () {
    final small = Image(width: 8, height: 8, numChannels: 4);
    final anim = Image(width: 8, height: 8)
      ..addFrame(Image(width: 8, height: 8));
    final files = {
      'png': encodePng(anim),
      'jpg': encodeJpg(small),
      'gif': encodeGif(anim),
      'webp': encodeWebP(anim),
      'tiff': encodeTiff(small),
      'bmp': encodeBmp(small),
      'tga': encodeTga(small),
      'ico': encodeIco(anim),
      'pvr': encodePvr(small),
    };
    for (final e in files.entries) {
      final file = e.value;
      for (var n = 0; n < file.length; n += 1 + n ~/ 16) {
        final bytes = Uint8List.sublistView(file, 0, n);
        try {
          decodeImage(bytes);
          decodeJpgExif(bytes);
        } catch (err) {
          expect(err, isA<ImageException>(), reason: '${e.key} $n bytes');
        }
      }
    }
  });

  test('PVR files are detected', () {
    final pvr = encodePvr(Image(width: 8, height: 8));
    expect(PvrDecoder().isValidFile(pvr), isTrue);
    expect(decodeImage(pvr)?.width, equals(8));
  });

  group('maxPixels', () {
    final small = Image(width: 64, height: 64);

    test('every decoder', () {
      final files = {
        'png': (encodePng(small), PngDecoder(maxPixels: 1000)),
        'gif': (encodeGif(small), GifDecoder()..maxPixels = 1000),
        'webp': (encodeWebP(small), WebPDecoder()..maxPixels = 1000),
        'tiff': (encodeTiff(small), TiffDecoder(maxPixels: 1000)),
        'bmp': (encodeBmp(small), BmpDecoder(maxPixels: 1000)),
        'tga': (encodeTga(small), TgaDecoder(maxPixels: 1000)),
        'ico': (encodeIco(small), IcoDecoder(maxPixels: 1000)),
        'pvr': (encodePvr(small), PvrDecoder(maxPixels: 1000)),
        'jpg': (encodeJpg(small), JpegDecoder(maxPixels: 1000)),
      };
      for (final e in files.entries) {
        final (bytes, decoder) = e.value;
        expect(() => decoder.decode(bytes), _throwsImageException,
            reason: e.key);
      }
    });

    test('Decoder.defaultMaxPixels', () {
      final saved = Decoder.defaultMaxPixels;
      addTearDown(() => Decoder.defaultMaxPixels = saved);
      Decoder.defaultMaxPixels = 64 * 64;
      expect(decodeImage(encodePng(small))?.width, equals(64));
      expect(() => decodeImage(encodePng(Image(width: 65, height: 64))),
          _throwsImageException);
    });

    test('PNG declaring a huge size', () {
      final png = encodePng(Image(width: 1, height: 1));
      // IHDR data starts at 16: width, height, then the CRC at 29.
      ByteData.sublistView(png)
        ..setUint32(16, 100000)
        ..setUint32(20, 100000)
        ..setUint32(29, getCrc32(png.sublist(12, 29)));
      expect(() => decodePng(png), _throwsImageException);
    });

    test('GIF declaring a huge canvas', () {
      final gif = encodeGif(Image(width: 1, height: 1))
        ..fillRange(6, 10, 0xff); // screen width and height
      expect(() => decodeGif(gif), _throwsImageException);
    });

    test('animation frames together', () {
      // 3 frames of 100 pixels each.
      final anim = _animation(10, 10, 3);
      final files = {
        'gif': (encodeGif(anim), GifDecoder()..maxPixels = 250),
        'png': (encodePng(anim), PngDecoder(maxPixels: 250)),
        'webp': (encodeWebP(anim), WebPDecoder()..maxPixels = 250),
        'ico': (encodeIco(anim), IcoDecoder(maxPixels: 250)),
      };
      for (final e in files.entries) {
        final (bytes, decoder) = e.value;
        expect(() => decoder.decode(bytes), _throwsImageException,
            reason: e.key);
        // A single frame is within the limit.
        expect(decoder.decode(bytes, frame: 0), isNotNull, reason: e.key);
      }
    });

    test('PSD declaring a huge size', () {
      final psd = Uint8List(26 + 12 + 2);
      ByteData.sublistView(psd)
        ..setUint32(0, 0x38425053) // 8BPS
        ..setUint16(4, 1) // version
        ..setUint16(12, 3) // channels
        ..setUint32(14, 30000) // height
        ..setUint32(18, 30000) // width
        ..setUint16(22, 8) // depth
        ..setUint16(24, 3); // RGB
      expect(() => decodePsd(psd), _throwsImageException);
    });

    test('EXR declaring a huge size', () {
      List<int> int32(int v) =>
          [v & 0xff, v >> 8 & 0xff, v >> 16 & 0xff, v >> 24 & 0xff];
      List<int> attr(String name, String type, List<int> value) => [
            ...name.codeUnits, 0, ...type.codeUnits, 0, //
            ...int32(value.length), ...value,
          ];
      final exr = Uint8List.fromList([
        ...int32(20000630), 2, 0, 0, 0, // magic, version, flags
        ...attr('channels', 'chlist', [
          ...'R'.codeUnits,
          0,
          ...int32(1),
          0,
          0,
          0,
          0,
          ...int32(1),
          ...int32(1),
          0
        ]),
        ...attr('compression', 'compression', [0]),
        ...attr('dataWindow', 'box2i',
            [...int32(0), ...int32(0), ...int32(99999), ...int32(99999)]),
        0,
      ]);
      expect(() => decodeExr(exr), _throwsImageException);
    });

    test('BMP with a negative width', () {
      final bmp = encodeBmp(Image(width: 2, height: 2));
      ByteData.sublistView(bmp).setInt32(18, -2147483648, Endian.little);
      expect(decodeBmp(bmp), isNull);
    });

    test('BMP with too little data for its size', () {
      final bmp = encodeBmp(Image(width: 2, height: 2));
      ByteData.sublistView(bmp).setInt32(22, 10000, Endian.little);
      expect(() => decodeBmp(bmp), _throwsImageException);
    });

    test('PNM with a negative size', () {
      final pnm = Uint8List.fromList('P1\n-2 -2\n0 1 0 1\n'.codeUnits);
      expect(decodePnm(pnm), isNull);
    });

    test('PNM with too little data for its size', () {
      final pnm = Uint8List.fromList('P1\n10000 10000\n0 1 0 1\n'.codeUnits);
      expect(() => decodePnm(pnm), _throwsImageException);
    });
  });
}
