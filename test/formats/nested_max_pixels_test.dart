import 'dart:typed_data';

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
  });
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
