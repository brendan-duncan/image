import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../image_exception.dart';
import '../../util/input_buffer.dart';
import 'exr_compressor.dart';
import 'exr_part.dart';

abstract class ExrZipCompressor extends ExrCompressor {
  factory ExrZipCompressor(ExrPart header, int maxScanLineSize,
                           int numScanLines) = InternalExrZipCompressor;
}

class InternalExrZipCompressor extends InternalExrCompressor implements ExrZipCompressor {
  ZLibDecoder zlib = ZLibDecoder();

  InternalExrZipCompressor(ExrPart header, int maxScanLineSize, this._numScanLines) :
    super(header) {
  }

  int numScanLines() => _numScanLines;

  Uint8List compress(InputBuffer input, int x, int y,
                     [int width, int height]) {
    throw new ImageException('Zip compression not yet supported');
  }

  Uint8List uncompress(InputBuffer input, int x, int y,
                       [int width, int height]) {
    Uint8List data = zlib.decodeBytes(input.toUint8List());

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

    // Predictor
    for (int i = 1, len = data.length; i < len; ++i) {
      data[i] = data[i - 1] + data[i] - 128;
    }

    // Reorder the pixel data
    if (_outCache == null || _outCache.length != data.length) {
      _outCache = Uint8List(data.length);
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

  int _numScanLines;
  Uint8List _outCache;
}
