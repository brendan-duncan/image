import 'dart:typed_data';

import '../../image_exception.dart';
import '../../internal/internal.dart';
import '../../util/input_buffer.dart';
import '../../util/output_buffer.dart';
import 'exr_channel.dart';
import 'exr_compressor.dart';
import 'exr_huffman.dart';
import 'exr_part.dart';
import 'exr_wavelet.dart';

/**
 * Wavelet compression
 */
abstract class ExrPizCompressor extends ExrCompressor {
  factory ExrPizCompressor(ExrPart header, int maxScanLineSize,
                           int numScanLines) = InternalExrPizCompressor;
}

@internal
class InternalExrPizCompressor extends InternalExrCompressor implements ExrPizCompressor {
  InternalExrPizCompressor(ExrPart header, this._maxScanLineSize, this._numScanLines) :
    super(header) {
    _channelData = new List<_PizChannelData>(header.channels.length);
    for (int i = 0; i < _channelData.length; ++i) {
      _channelData[i] = new _PizChannelData();
    }

    int tmpBufferSize = (_maxScanLineSize * _numScanLines) ~/ 2;
    _tmpBuffer = new Uint16List(tmpBufferSize);
  }

  int numScanLines() => _numScanLines;

  Uint8List compress(InputBuffer inPtr, int x, int y,
                     [int width, int height]) {
    throw new ImageException('Piz compression not yet supported.');
  }

  Uint8List uncompress(InputBuffer inPtr, int x, int y,
                       [int width, int height]) {
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

    int tmpBufferEnd = 0;
    List<ExrChannel> channels = header.channels;
    final int numChannels = channels.length;

    for (int i = 0; i < numChannels; ++i) {
      ExrChannel ch = channels[i];
      _PizChannelData cd = _channelData[i];
      cd.start = tmpBufferEnd;
      cd.end = cd.start;

      cd.nx = numSamples(ch.xSampling, minX, maxX);
      cd.ny = numSamples(ch.ySampling, minY, maxY);
      cd.ys = ch.ySampling;

      cd.size = ch.size ~/ 2; //2=size(HALF)

      tmpBufferEnd += cd.nx * cd.ny * cd.size;
    }

    int minNonZero = inPtr.readUint16();
    int maxNonZero = inPtr.readUint16();

    if (maxNonZero >= BITMAP_SIZE) {
      throw new ImageException("Error in header for PIZ-compressed data "
                               "(invalid bitmap size).");
    }

    Uint8List bitmap = new Uint8List(BITMAP_SIZE);
    if (minNonZero <= maxNonZero) {
      InputBuffer b = inPtr.readBytes(maxNonZero - minNonZero + 1);
      for (int i = 0, j = minNonZero, len = b.length; i < len; ++i) {
        bitmap[j++] = b[i];
      }
    }

    Uint16List lut = new Uint16List(USHORT_RANGE);
    int maxValue = _reverseLutFromBitmap(bitmap, lut);

    // Huffman decoding
    int length = inPtr.readUint32();
    ExrHuffman.uncompress(inPtr, length, _tmpBuffer, tmpBufferEnd);

    // Wavelet decoding
    for (int i = 0; i < numChannels; ++i) {
      _PizChannelData cd = _channelData[i];
      for (int j = 0; j < cd.size; ++j) {
        ExrWavelet.decode(_tmpBuffer, cd.start + j, cd.nx, cd.size, cd.ny,
                          cd.nx * cd.size, maxValue);
      }
    }

    // Expand the pixel data to their original range
    _applyLut(lut, _tmpBuffer, tmpBufferEnd);

    if (_output == null) {
      _output = new OutputBuffer(size: (_maxScanLineSize * _numScanLines) +
                                       (65536 + 8192));
    }
    _output.rewind();

    int count = 0;
    // Rearrange the pixel data into the format expected by the caller.
    for (int y = minY; y <= maxY; ++y) {
      for (int i = 0; i < numChannels; ++i) {
        _PizChannelData cd = _channelData[i];

        if ((y % cd.ys) != 0) {
          continue;
        }

        for (int x = cd.nx * cd.size; x > 0; --x) {
          _output.writeUint16(_tmpBuffer[cd.end++]);
        }
      }
    }

    return _output.getBytes();
  }

  void _applyLut(List<int> lut, List<int> data, int nData) {
    for (int i = 0; i < nData; ++i) {
      data[i] = lut[data[i]];
    }
  }

  int _reverseLutFromBitmap(Uint8List bitmap, Uint16List lut) {
    int k = 0;
    for (int i = 0; i < USHORT_RANGE; ++i) {
      if ((i == 0) || (bitmap[i >> 3] & (1 << (i & 7))) != 0) {
        lut[k++] = i;
      }
    }

    int n = k - 1;

    while (k < USHORT_RANGE) {
      lut[k++] = 0;
    }

    return n;   // maximum k where lut[k] is non-zero,
  }

  static const int USHORT_RANGE = 1 << 16;
  static const int BITMAP_SIZE = 8192;

  OutputBuffer _output;
  int _maxScanLineSize;
  int _numScanLines;
  List<_PizChannelData> _channelData;
  Uint16List _tmpBuffer;
}

class _PizChannelData {
  int start;
  int end;
  int nx;
  int ny;
  int ys;
  int size;
}
