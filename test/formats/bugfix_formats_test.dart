import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:test/test.dart';

// Palette for the test GIFs: black, red, green, blue.
const _black = [0, 0, 0];
const _red = [255, 0, 0];
const _green = [0, 255, 0];
const _blue = [0, 0, 255];

class _GifFrame {
  final int x;
  final int y;
  final int width;
  final int height;
  final int disposal;
  final int? transparent;
  final List<int> pixels;

  _GifFrame(this.x, this.y, this.width, this.height, this.pixels,
      {this.disposal = 0, this.transparent});
}

// Builds a GIF89a with a 4 color global palette (black, red, green, blue).
Uint8List _buildGif(int width, int height, List<_GifFrame> frames) {
  final out = BytesBuilder();
  void u16(int v) => out.add([v & 0xff, v >> 8]);
  out.add('GIF89a'.codeUnits);
  u16(width);
  u16(height);
  // Global color table of 4 colors, background color 0.
  out.add([0x81, 0, 0]);
  for (final c in [_black, _red, _green, _blue]) {
    out.add(c);
  }
  for (final f in frames) {
    // Graphic control extension.
    final t = f.transparent;
    out
      ..add([0x21, 0xf9, 4, (f.disposal << 2) | (t != null ? 1 : 0), 0, 0])
      ..add([t ?? 0, 0])
      // Image descriptor, no local color table.
      ..add([0x2c]);
    u16(f.x);
    u16(f.y);
    u16(f.width);
    u16(f.height);
    out
      ..add([0])
      // LZW data with a minimum code size of 2: a clear code before every
      // pixel keeps the code size at 3 bits.
      ..add([2]);
    var bits = 0;
    var numBits = 0;
    final data = <int>[];
    void code(int c) {
      bits |= c << numBits;
      numBits += 3;
      while (numBits >= 8) {
        data.add(bits & 0xff);
        bits >>= 8;
        numBits -= 8;
      }
    }

    for (final p in f.pixels) {
      code(4);
      code(p);
    }
    code(5);
    if (numBits > 0) {
      data.add(bits & 0xff);
    }
    for (var i = 0; i < data.length; i += 255) {
      final end = i + 255 < data.length ? i + 255 : data.length;
      out
        ..addByte(end - i)
        ..add(data.sublist(i, end));
    }
    out.addByte(0);
  }
  out.addByte(0x3b);
  return out.toBytes();
}

void _expectRgba(Image image, int x, int y, List<int>? rgb) {
  final p = image.getPixel(x, y);
  if (rgb == null) {
    expect(p.a, equals(0), reason: '($x, $y) should be transparent');
  } else {
    expect([p.r, p.g, p.b, p.a], equals([...rgb, 255]), reason: '($x, $y)');
  }
}

void main() {
  group('ico', () {
    test('decodeImageLargest treats a size of 0 as 256', () {
      final ico = IcoEncoder().encodeImages(
          [Image(width: 48, height: 48), Image(width: 256, height: 256)]);
      // The 256 entry is stored as 0 in the directory.
      expect(ico[6 + 16], equals(0));
      final decoder = IcoDecoder();
      final info = decoder.startDecode(ico) as IcoInfo;
      expect(info.images[1].width, equals(256));
      expect(info.images[1].height, equals(256));
      final largest = decoder.decodeImageLargest(ico)!;
      expect(largest.width, equals(256));
      expect(largest.height, equals(256));
    });

    test('icons larger than 256 throw an ImageException', () {
      expect(() => IcoEncoder().encode(Image(width: 257, height: 16)),
          throwsA(isA<ImageException>()));
    });
  });

  group('cur', () {
    test('findEncoderForNamedImage returns a CurEncoder for .cur', () {
      expect(findEncoderForNamedImage('cursor.cur'), isA<CurEncoder>());
      final bytes = encodeNamedImage('cursor.cur', Image(width: 8, height: 8))!;
      // Type 2 is CUR, type 1 is ICO.
      expect(bytes[2], equals(2));
    });
  });

  group('psd', () {
    test('startDecode returns null for non-PSD data', () {
      final png = encodePng(Image(width: 8, height: 8));
      final decoder = PsdDecoder();
      expect(decoder.isValidFile(png), isFalse);
      expect(decoder.startDecode(png), isNull);
      expect(decoder.numFrames(), equals(0));
      expect(decoder.decodeFrame(0), isNull);
      expect(decoder.decode(png), isNull);
    });

    test('startDecode still accepts PSD data', () {
      final bytes = File('test/_data/psd/psd1.psd').readAsBytesSync();
      expect(PsdDecoder().startDecode(bytes), isNotNull);
    });
  });

  group('exports', () {
    test('Rational and WebPFrame are exported', () {
      expect(Rational(1, 2).toDouble(), equals(0.5));
      final info = WebPDecoder().startDecode(
          File('test/_data/webp/animated_lossy.webp').readAsBytesSync())!;
      final List<WebPFrame> frames = info.frames;
      expect(frames, isNotEmpty);
    });
  });

  group('gif animation', () {
    test(
        'first frame is placed on the logical screen and disposal 2 '
        'clears only the frame area', () {
      final gif = _buildGif(4, 4, [
        _GifFrame(1, 1, 2, 2, [1, 1, 1, 1], disposal: 2, transparent: 0),
        _GifFrame(0, 0, 1, 1, [2], disposal: 1, transparent: 0),
        _GifFrame(3, 3, 1, 1, [3], transparent: 0),
      ]);
      final anim = decodeGif(gif)!;
      expect(anim.numFrames, equals(3));
      for (final frame in anim.frames) {
        expect(frame.width, equals(4));
        expect(frame.height, equals(4));
      }

      final f0 = anim.frames[0];
      _expectRgba(f0, 0, 0, null);
      _expectRgba(f0, 1, 1, _red);
      _expectRgba(f0, 2, 2, _red);
      _expectRgba(f0, 3, 3, null);

      // Frame 0's disposal 2 cleared its area before frame 1 was drawn.
      final f1 = anim.frames[1];
      _expectRgba(f1, 0, 0, _green);
      _expectRgba(f1, 1, 1, null);
      _expectRgba(f1, 2, 2, null);

      // Frame 1's disposal 1 keeps it on the canvas for frame 2.
      final f2 = anim.frames[2];
      _expectRgba(f2, 0, 0, _green);
      _expectRgba(f2, 1, 1, null);
      _expectRgba(f2, 3, 3, _blue);
    });

    test('disposal applies after the frame is displayed', () {
      // Frame 0 disposes to background, frame 1 is drawn with disposal 1 over
      // the cleared area, and frame 2 must still see frame 1.
      final gif = _buildGif(2, 1, [
        _GifFrame(0, 0, 2, 1, [1, 1], disposal: 1),
        _GifFrame(0, 0, 1, 1, [2], disposal: 2, transparent: 0),
        _GifFrame(1, 0, 1, 1, [3], disposal: 1, transparent: 0),
      ]);
      final anim = decodeGif(gif)!;
      expect(anim.numFrames, equals(3));
      _expectRgba(anim.frames[0], 0, 0, _red);
      _expectRgba(anim.frames[0], 1, 0, _red);
      // Frame 1 is shown on top of frame 0 even though it disposes to
      // background afterwards.
      _expectRgba(anim.frames[1], 0, 0, _green);
      _expectRgba(anim.frames[1], 1, 0, _red);
      // Frame 1's area was restored to the background for frame 2.
      _expectRgba(anim.frames[2], 0, 0, null);
      _expectRgba(anim.frames[2], 1, 0, _blue);
    });

    test('disposal 3 restores the previous canvas', () {
      final gif = _buildGif(4, 4, [
        _GifFrame(0, 0, 4, 4, List.filled(16, 1), disposal: 1),
        _GifFrame(1, 1, 1, 1, [2], disposal: 3),
        _GifFrame(2, 2, 1, 1, [3]),
      ]);
      final anim = decodeGif(gif)!;
      expect(anim.numFrames, equals(3));

      final f1 = anim.frames[1];
      _expectRgba(f1, 0, 0, _red);
      _expectRgba(f1, 1, 1, _green);
      _expectRgba(f1, 2, 2, _red);

      final f2 = anim.frames[2];
      _expectRgba(f2, 0, 0, _red);
      _expectRgba(f2, 1, 1, _red);
      _expectRgba(f2, 2, 2, _blue);
    });

    test('frames without a local palette keep the previous canvas', () {
      final gif = _buildGif(2, 1, [
        _GifFrame(0, 0, 2, 1, [1, 2], disposal: 1),
        _GifFrame(1, 0, 1, 1, [3]),
      ]);
      final anim = decodeGif(gif)!;
      _expectRgba(anim.frames[1], 0, 0, _red);
      _expectRgba(anim.frames[1], 1, 0, _blue);
    });

    test('frames decoded before a bad frame are kept', () {
      final gif = _buildGif(2, 2, [
        _GifFrame(0, 0, 2, 2, [1, 1, 1, 1]),
        _GifFrame(0, 0, 1, 1, [2]),
        // Outside of the logical screen.
        _GifFrame(1, 1, 2, 2, [3, 3, 3, 3]),
      ]);
      final anim = decodeGif(gif)!;
      expect(anim.numFrames, equals(2));
      _expectRgba(anim.frames[1], 0, 0, _green);
      _expectRgba(anim.frames[1], 1, 1, _red);
    });
  });
}
