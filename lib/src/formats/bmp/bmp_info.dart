import 'dart:convert';

import '../../formats/decode_info.dart';

import '../../util/input_buffer.dart';

enum BitmapCompression { BI_BITFIELDS, RLE_8, RLE_4, NONE }

class BitmapFileHeader {
  int fileLength;
  static final fileHeaderSize = 14;

  int offset;
  BitmapFileHeader(InputBuffer b) {
    if (!isValidFile(b)) {
      throw 'Not a bitmap file.';
    }
    b.skip(2);

    fileLength = b.readInt32();
    b.skip(4); // skip reserved space

    offset = b.readInt32();
  }

  static bool isValidFile(InputBuffer b) {
    final type = InputBuffer.from(b).readUint16();
    return type == BMP_HEADER_FILETYPE;
  }

  static const BMP_HEADER_FILETYPE = (0x42) + (0x4D << 8); // BM

  Map<String, int> toJson() => {
        'offset': offset,
        'fileLength': fileLength,
        'fileType': BMP_HEADER_FILETYPE
      };
}

class BmpInfo extends DecodeInfo {
  int get numFrames => 1;
  final BitmapFileHeader file;

  @override
  final int width;
  @override
  final int height;

  final int headerSize;
  final int planes;
  final int bpp;
  final BitmapCompression compression;
  final int imageSize;
  final int xppm;
  final int yppm;
  final int totalColors;
  final int importantColors;
  BmpInfo(InputBuffer p)
      : this.file = BitmapFileHeader(p),
        this.headerSize = p.readUint32(),
        this.width = p.readInt32(),
        this.height = p.readInt32(),
        this.planes = p.readUint16(),
        this.bpp = p.readUint16(),
        this.compression = _intToCompressions(p.readUint32()),
        this.imageSize = p.readUint32(),
        this.xppm = p.readInt32(),
        this.yppm = p.readInt32(),
        this.totalColors = p.readUint32(),
        this.importantColors = p.readUint32();

  static BitmapCompression _intToCompressions(int compIndex) {
    final map = <int, BitmapCompression>{
      0: BitmapCompression.NONE,
      // 1: BitmapCompression.RLE_8,
      // 2: BitmapCompression.RLE_4,
      3: BitmapCompression.BI_BITFIELDS,
    };
    final compression = map[compIndex];
    if (compression == null) {
      throw "Bitmap compression $compIndex is not supported yet.";
    }
    return compression;
  }

  final R = 'R';
  final G = 'G';
  final B = 'B';
  final A = 'A';

  List<int> decodeRgba(InputBuffer input) {
    if (this.compression == BitmapCompression.BI_BITFIELDS && bpp == 32) {
      return _rgba(input, [A, B, G, R]);
    } else if (bpp == 32 && compression == BitmapCompression.NONE) {
      return _rgba(input, [B, G, R, A], defaults: {A: 0});
    } else if (bpp == 24) {
      return _rgba(input, [
        B,
        G,
        R,
      ], defaults: {
        A: 0
      });
    }
    // else if (bpp == 16) {
    //   return _rgbaFrom16(input);
    // }
    else {
      throw 'Unsupported bpp ($bpp) or compression unsupported.';
    }
  }

  List<int> _rgbaFrom16(InputBuffer input) {
    // TODO: finish decoding for 16 bit
    final maskRed = 0x7C00;
    final maskGreen = 0x3E0;
    final maskBlue = 0x1F;
    final pixel = input.readUint16();

    return [(pixel & maskRed), (pixel & maskGreen), (pixel & maskBlue), 0];
  }

  // defaults do not move any bytes
  List<int> _rgba(InputBuffer input, List<String> order,
      {Map<String, int> defaults = const {}}) {
    defaults.keys.forEach((k) => !order.contains(k) ? order.add(k) : null);
    final lookup = <String, int>{};
    order.forEach((k) => lookup[k] = defaults[k] ?? input.readByte());

    return [lookup[R], lookup[G], lookup[B], lookup[A]];
  }

  String _compToString() {
    switch (compression) {
      case BitmapCompression.BI_BITFIELDS:
        return 'BI_BITFIELDS';
      case BitmapCompression.NONE:
        return 'none';
      case BitmapCompression.RLE_4:
        return 'RLE-4';
      case BitmapCompression.RLE_8:
        return 'RLE-8';
    }
    return 'UNSUPPORTED: $compression';
  }

  String toString() {
    final json = JsonEncoder.withIndent(" ");
    return json.convert({
      'headerSize': headerSize,
      'width': width,
      'height': height,
      'planes': planes,
      'bpp': bpp,
      'file': file.toJson(),
      'compression': _compToString(),
      'imageSize': imageSize,
      'xppm': xppm,
      'yppm': yppm,
      'totalColors': totalColors,
      'importantColors': importantColors
    });
  }
}
