import 'dart:convert';

import 'package:image/image.dart';

import '../../formats/decode_info.dart';

import '../../util/input_buffer.dart';

enum BitmapCompression { BI_BITFIELDS, NONE }

class BitmapFileHeader {
  int fileLength;
  static final fileHeaderSize = 14;

  int offset;
  BitmapFileHeader(InputBuffer b) {
    if (!isValidFile(b)) {
      throw ImageException('Not a bitmap file.');
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
      throw ImageException(
          "Bitmap compression $compIndex is not supported yet.");
    }
    return compression;
  }

  int decodeRgba(InputBuffer input) {
    if (this.compression == BitmapCompression.BI_BITFIELDS && bpp == 32) {
      final a = input.readByte();
      final b = input.readByte();
      final g = input.readByte();
      final r = input.readByte();
      return getColor(r, g, b, a);
    } else if (bpp == 32 && compression == BitmapCompression.NONE) {
      final b = input.readByte();
      final g = input.readByte();
      final r = input.readByte();
      final a = input.readByte();
      return getColor(r, g, b, a);
    } else if (bpp == 24) {
      final b = input.readByte();
      final g = input.readByte();
      final r = input.readByte();
      final a = 255;
      return getColor(r, g, b, a);
    }
    // else if (bpp == 16) {
    //   return _rgbaFrom16(input);
    // }
    else {
      throw ImageException(
          'Unsupported bpp ($bpp) or compression unsupported.');
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

  String _compToString() {
    switch (compression) {
      case BitmapCompression.BI_BITFIELDS:
        return 'BI_BITFIELDS';
      case BitmapCompression.NONE:
        return 'none';
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
