import 'dart:typed_data';

import '../../image_exception.dart';
import '../../util/input_buffer.dart';

class PsdChannel {
  static const int RED = 0;
  static const int GREEN = 1;
  static const int BLUE = 2;
  static const int BLACK = 3;
  static const int ALPHA = -1;
  static const int MASK = -2;
  static const int REAL_MASK = -3;

  static const int COMPRESS_NONE = 0;
  static const int COMPRESS_RLE = 1;
  static const int COMPRESS_ZIP = 2;
  static const int COMPRESS_ZIP_PREDICTOR = 3;

  int id;
  int dataLength;
  Uint8List data;

  PsdChannel(this.id, this.dataLength);

  PsdChannel.read(InputBuffer input, this.id, int width, int height,
      int bitDepth, int compression, Uint16List lineLengths, int planeNumber) {
    readPlane(
        input, width, height, bitDepth, compression, lineLengths, planeNumber);
  }

  void readPlane(InputBuffer input, int width, int height, int bitDepth,
      [int compression, Uint16List lineLengths, int planeNum = 0]) {
    if (compression == null) {
      compression = input.readUint16();
    }

    switch (compression) {
      case COMPRESS_NONE:
        _readPlaneUncompressed(input, width, height, bitDepth);
        break;
      case COMPRESS_RLE:
        if (lineLengths == null) {
          lineLengths = _readLineLengths(input, height);
        }
        _readPlaneRleCompressed(
            input, width, height, bitDepth, lineLengths, planeNum);
        break;
      default:
        throw new ImageException('Unsupported compression: $compression');
    }
  }

  Uint16List _readLineLengths(InputBuffer input, int height) {
    Uint16List lineLengths = Uint16List(height);
    for (int i = 0; i < height; ++i) {
      lineLengths[i] = input.readUint16();
    }
    return lineLengths;
  }

  void _readPlaneUncompressed(
      InputBuffer input, int width, int height, int bitDepth) {
    int len = width * height;
    if (bitDepth == 16) {
      len *= 2;
    }
    if (len > input.length) {
      data = Uint8List(len);
      data.fillRange(0, len, 255);
      return;
    }

    InputBuffer imgData = input.readBytes(len);
    data = imgData.toUint8List();
  }

  void _readPlaneRleCompressed(InputBuffer input, int width, int height,
      int bitDepth, Uint16List lineLengths, int planeNum) {
    int len = width * height;
    if (bitDepth == 16) {
      len *= 2;
    }
    data = Uint8List(len);
    int pos = 0;
    int lineIndex = planeNum * height;
    if (lineIndex >= lineLengths.length) {
      data.fillRange(0, data.length, 255);
      return;
    }

    for (int i = 0; i < height; ++i) {
      int len = lineLengths[lineIndex++];
      InputBuffer s = input.readBytes(len);
      _decodeRLE(s, data, pos);
      pos += width;
    }
  }

  void _decodeRLE(InputBuffer src, Uint8List dst, int dstIndex) {
    while (!src.isEOS) {
      int n = src.readInt8();
      if (n < 0) {
        n = 1 - n;
        int b = src.readByte();
        for (int i = 0; i < n; ++i) {
          dst[dstIndex++] = b;
        }
      } else {
        n++;
        for (int i = 0; i < n; ++i) {
          dst[dstIndex++] = src.readByte();
        }
      }
    }
  }
}
