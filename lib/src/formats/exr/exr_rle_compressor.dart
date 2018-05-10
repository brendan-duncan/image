import 'dart:typed_data';

import '../../image_exception.dart';
import '../../util/input_buffer.dart';
import '../../util/output_buffer.dart';
import 'exr_compressor.dart';
import 'exr_part.dart';

abstract class ExrRleCompressor extends ExrCompressor {
  factory ExrRleCompressor(ExrPart header, int maxScanLineSize) = InternalExrRleCompressor;
}

class InternalExrRleCompressor extends InternalExrCompressor implements ExrRleCompressor {
  InternalExrRleCompressor(ExrPart header, this._maxScanLineSize) :
    super(header) {
  }

  int numScanLines() => 1;

  Uint8List compress(InputBuffer inPtr, int x, int y,
                     [int width, int height]) {
    throw new ImageException('Rle compression not yet supported.');
  }

  Uint8List uncompress(InputBuffer inPtr, int x, int y,
                       [int width, int height]) {
    OutputBuffer out = new OutputBuffer(size: inPtr.length * 2);

    if (width == null) {
      width = header.width;
    }
    if (height == null) {
      height = header.linesInBuffer;
    }

    int minX = x;
    int maxX = x + width - 1;
    int minY = y;
    int maxY = y + height - 1;

    if (maxX > header.width) {
      maxX = header.width - 1;
    }
    if (maxY > header.height) {
      maxY = header.height - 1;
    }

    decodedWidth = (maxX - minX) + 1;
    decodedHeight = (maxY - minY) + 1;

    while (!inPtr.isEOS) {
      int n = inPtr.readInt8();
      if (n < 0) {
        int count = -n;
        while (count-- > 0) {
          out.writeByte(inPtr.readByte());
        }
      } else {
        int count = n;
        while (count-- >= 0) {
          out.writeByte(inPtr.readByte());
        }
      }
    }

    Uint8List data = out.getBytes();

    // Predictor
    for (int i = 1, len = data.length; i < len; ++i) {
      data[i] = data[i - 1] + data[i] - 128;
    }

    // Reorder the pixel data
    if (_outCache == null || _outCache.length != data.length) {
      _outCache = new Uint8List(data.length);
    }

    final int len = data.length;
    int t1 = 0;
    int t2 = (len + 1) ~/ 2;
    int si = 0;

    while (true) {
      if (si < len) {
        _outCache[si++] = data[t1++];
      } else {
        break;
      }
      if (si < len) {
        _outCache[si++] = data[t2++];
      } else {
        break;
      }
    }

    return _outCache;
  }

  Uint8List _outCache;
  int _maxScanLineSize;
}
