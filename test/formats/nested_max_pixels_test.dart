import 'dart:typed_data';

import 'package:archive/archive.dart' show getCrc32;
import 'package:image/image.dart';
import 'package:image/src/formats/webp/vp8l_encoder.dart';
import 'package:image/src/formats/webp/webp_container.dart';
import 'package:test/test.dart';

// Bitstreams nested inside another container declare their own size, which
// must not get past the size the container's maxPixels check was run on.
void main() {
  group('nested bitstream sizes', () {
    const maxPixels = 40000000;
    final source = Image(width: 16, height: 16, numChannels: 4)
      ..clear(ColorRgba8(10, 200, 30, 255));

    Uint8List animated(WebPChunk bitstream) => buildRiff([
          WebPChunk('VP8X', vp8xChunkData(2, 16, 16)),
          WebPChunk('ANIM', animChunkData(0, 0, 0, 0, 0)),
          WebPChunk(
              'ANMF',
              anmfChunkData(
                  x: 0,
                  y: 0,
                  width: 16,
                  height: 16,
                  duration: 100,
                  clearToBackground: false,
                  blend: false,
                  frame: [bitstream])),
        ]);

    // The VP8L header packs width - 1 and height - 1 in 14 bits each after
    // the signature byte
    Uint8List vp8l(int width, int height) {
      final data = VP8LEncoder().encodeVP8L(source);
      final view = ByteData.sublistView(data);
      final bits = view.getUint32(1, Endian.little) & ~0x0fffffff;
      view.setUint32(
          1, bits | (width - 1) | ((height - 1) << 14), Endian.little);
      return data;
    }

    // The 'VP8 ' payload of a simple lossy file, its size at bytes 6 to 9
    Uint8List vp8(int width, int height) {
      final file = WebPEncoder(lossless: false).encode(source);
      expect(String.fromCharCodes(file, 12, 16), 'VP8 ');
      final size = ByteData.sublistView(file).getUint32(16, Endian.little);
      final data = Uint8List.fromList(file.sublist(20, 20 + size));
      ByteData.sublistView(data)
        ..setUint16(6, width, Endian.little)
        ..setUint16(8, height, Endian.little);
      return data;
    }

    WebPDecoder webp() => WebPDecoder()..maxPixels = maxPixels;

    // Checked by message: the old decoders also threw, but only after
    // allocating the declared size
    Matcher refused(String message) => throwsA(isA<ImageException>()
        .having((e) => e.message, 'message', contains(message)));

    test('WebP lossless frame matching its ANMF size decodes', () {
      final image = webp().decode(animated(WebPChunk('VP8L', vp8l(16, 16))));
      expect(image?.width, 16);
      expect(image?.getPixel(3, 3).g, 200);
    });

    test('WebP lossless frame larger than its ANMF size is refused', () {
      final bytes = animated(WebPChunk('VP8L', vp8l(12000, 12000)));
      expect(() => webp().decode(bytes), refused('does not match'));
    });

    test('WebP lossy frame matching its ANMF size decodes', () {
      final image = webp().decode(animated(WebPChunk('VP8 ', vp8(16, 16))));
      expect(image?.width, 16);
      expect(image!.getPixel(3, 3).g, closeTo(200, 8));
    });

    test('WebP lossy frame larger than its ANMF size is refused', () {
      final bytes = animated(WebPChunk('VP8 ', vp8(12000, 12000)));
      expect(() => webp().decode(bytes), refused('does not match'));
    });

    test('WebP lossy size ignores the upscaling bits', () {
      // The top 2 bits are a scaling hint, so this is still 16 x 16
      final bytes = animated(WebPChunk('VP8 ', vp8(0xc010, 0x4010)));
      final image = webp().decode(bytes);
      expect(image?.width, 16);
      expect(image?.height, 16);
    });

    test('TIFF JPEG tile larger than the tile is refused', () {
      final bytes = _tiffWithJpegTile(16000);
      expect(() => TiffDecoder(maxPixels: maxPixels).decode(bytes),
          refused('exceed the maximum of 256 pixels'));
    });

    test('TIFF JPEG tile matching the tile decodes', () {
      final image = TiffDecoder(maxPixels: maxPixels)
          .decode(_tiffWithJpegTile(16, width: 16, height: 16));
      expect(image?.width, 16);
    });

    test('WebP frame holding its own animation is refused', () {
      // The inner frame's size was never checked against maxPixels
      final inner = WebPChunk(
          'ANMF',
          anmfChunkData(
              x: 0,
              y: 0,
              width: 16,
              height: 16,
              duration: 100,
              clearToBackground: false,
              blend: false,
              frame: [WebPChunk('VP8L', vp8l(16, 16))]));
      final bytes = buildRiff([
        WebPChunk('VP8X', vp8xChunkData(2, 16, 16)),
        WebPChunk('ANIM', animChunkData(0, 0, 0, 0, 0)),
        WebPChunk(
            'ANMF',
            anmfChunkData(
                x: 0,
                y: 0,
                width: 16,
                height: 16,
                duration: 100,
                clearToBackground: false,
                blend: false,
                frame: [
                  WebPChunk('VP8X', vp8xChunkData(2, 16, 16)),
                  WebPChunk('ANIM', animChunkData(0, 0, 0, 0, 0)),
                  inner,
                ])),
      ]);
      expect(() => webp().decode(bytes), refused('holds an animation'));
    });

    test('WebP frame outside the canvas is refused', () {
      final bytes = buildRiff([
        WebPChunk('VP8X', vp8xChunkData(2, 16, 16)),
        WebPChunk('ANIM', animChunkData(0, 0, 0, 0, 0)),
        WebPChunk(
            'ANMF',
            anmfChunkData(
                x: 8,
                y: 0,
                width: 16,
                height: 16,
                duration: 100,
                clearToBackground: false,
                blend: false,
                frame: [WebPChunk('VP8L', vp8l(16, 16))])),
      ]);
      expect(() => webp().decode(bytes), refused('outside the 16x16 canvas'));
    });

    test('APNG frame outside the canvas is refused', () {
      final anim = Image(width: 16, height: 16)
        ..addFrame(Image(width: 16, height: 16));
      final png = encodePng(anim);
      // Widen the second frame's fcTL
      final fctl = _chunkOffsets(png, 'fcTL')[1];
      ByteData.sublistView(png).setUint32(fctl + 12, 32);
      _fixCrc(png, fctl);
      expect(() => PngDecoder(maxPixels: maxPixels).decode(png),
          refused('outside the 16x16 canvas'));
      // The first frame, unchanged, still decodes
      expect(decodePng(encodePng(anim))?.numFrames, 2);
    });
  });

  group('crafted header values', () {
    Matcher refused(String message) => throwsA(isA<ImageException>()
        .having((e) => e.message, 'message', contains(message)));

    test('PNG size whose product overflows is refused', () {
      final png = encodePng(Image(width: 1, height: 1));
      ByteData.sublistView(png)
        ..setUint32(16, 0xffffffff)
        ..setUint32(20, 0x80000001);
      _fixCrc(png, 8);
      expect(() => PngDecoder(maxPixels: 40000000).startDecode(png),
          refused('exceed the maximum'));
    });

    test('PNM size whose product overflows is refused', () {
      // 274177 * 67280421310721 is 2^64 + 1, which wraps to 1
      final pnm = Uint8List.fromList(
          [...'P5\n274177 67280421310721\n255\n'.codeUnits, 0]);
      expect(() => PnmDecoder().decode(pnm), refused('exceed the maximum'));
    });

    test('JPEG with 4 components and no Adobe marker is refused at once', () {
      // Without its tables the scan would fail differently if decoded
      final jpeg = Uint8List.fromList([
        0xff, 0xd8, // SOI
        0xff, 0xc2, 0, 20, 8, 0, 8, 0, 8, 4, // SOF2 8 x 8, 4 components
        1, 0x11, 0, 2, 0x11, 0, 3, 0x11, 0, 4, 0x11, 0,
        0xff, 0xda, 0, 14, 4, 1, 0, 2, 0, 3, 0, 4, 0, 0, 0, 0, // SOS
        0, 0,
        0xff, 0xd9, // EOI
      ]);
      expect(() => decodeJpg(jpeg), refused('4 components'));
    });

    test('BMP palette larger than the file is refused', () {
      final bmp = ByteData(58)
        ..setUint8(0, 0x42)
        ..setUint8(1, 0x4d)
        ..setUint32(2, 58, Endian.little)
        ..setUint32(10, 58, Endian.little) // pixel data offset
        ..setUint32(14, 40, Endian.little) // BITMAPINFOHEADER
        ..setInt32(18, 1, Endian.little)
        ..setInt32(22, 1, Endian.little)
        ..setUint16(26, 1, Endian.little)
        ..setUint16(28, 8, Endian.little) // 8 bits per pixel
        ..setUint32(46, 0xffffffff, Endian.little); // colors used
      expect(() => BmpDecoder().decode(bmp.buffer.asUint8List()),
          refused('larger than the file'));
    });
  });
}

/// The offsets of the PNG chunks of [type] in [png].
List<int> _chunkOffsets(Uint8List png, String type) {
  final bd = ByteData.sublistView(png);
  return [
    for (var offset = 8;
        offset < png.length;
        offset += 12 + bd.getUint32(offset))
      if (String.fromCharCodes(png, offset + 4, offset + 8) == type) offset,
  ];
}

/// Recomputes the CRC of the PNG chunk at [offset].
void _fixCrc(Uint8List png, int offset) {
  final bd = ByteData.sublistView(png);
  final length = bd.getUint32(offset);
  bd.setUint32(offset + 8 + length,
      getCrc32(png.sublist(offset + 4, offset + 8 + length)));
}

/// An RGB TIFF with one 16 x 16 JPEG tile whose SOF0 declares [size] x [size].
Uint8List _tiffWithJpegTile(int size, {int width = 1, int height = 1}) {
  final jpeg = encodeJpg(Image(width: 16, height: 16));
  for (var i = 0; i + 8 < jpeg.length; i++) {
    if (jpeg[i] == 0xff && jpeg[i + 1] == 0xc0) {
      ByteData.sublistView(jpeg)
        ..setUint16(i + 5, size)
        ..setUint16(i + 7, size);
      break;
    }
  }
  const entries = 10;
  const ifdOffset = 8;
  const dataOffset = ifdOffset + 2 + entries * 12 + 4;
  final out = ByteData(dataOffset + jpeg.length)
    ..setUint8(0, 0x49)
    ..setUint8(1, 0x49)
    ..setUint16(2, 42, Endian.little)
    ..setUint32(4, ifdOffset, Endian.little)
    ..setUint16(ifdOffset, entries, Endian.little);
  var at = ifdOffset + 2;
  for (final (id, type, value) in [
    (256, 4, width), // ImageWidth
    (257, 4, height), // ImageLength
    (258, 3, 8), // BitsPerSample
    (259, 3, 7), // Compression: JPEG
    (262, 3, 2), // Photometric: RGB
    (277, 3, 3), // SamplesPerPixel
    (322, 3, 16), // TileWidth
    (323, 3, 16), // TileLength
    (324, 4, dataOffset), // TileOffsets
    (325, 4, jpeg.length), // TileByteCounts
  ]) {
    out
      ..setUint16(at, id, Endian.little)
      ..setUint16(at + 2, type, Endian.little)
      ..setUint32(at + 4, 1, Endian.little)
      ..setUint32(at + 8, value, Endian.little);
    at += 12;
  }
  final bytes = out.buffer.asUint8List();
  bytes.setRange(dataOffset, bytes.length, jpeg);
  return bytes;
}
