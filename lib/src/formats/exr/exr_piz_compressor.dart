part of image;

/**
 * Wavelet compression
 */
class ExrPizCompressor extends ExrCompressor {
  ExrPizCompressor(ExrPart header, this._maxScanLineSize, this._numScanLines) :
    super._(header) {
    _channelData = new List<_PizChannelData>(header.channels.length);
    for (int i = 0; i < _channelData.length; ++i) {
      _channelData[i] = new _PizChannelData();
    }

    int tmpBufferSize = (_maxScanLineSize * _numScanLines) ~/ 2;
    _tmpBuffer = new Uint8List(tmpBufferSize);
  }

  int numScanLines() => _numScanLines;


  Uint8List compress(InputBuffer inPtr, int y) {
    throw new ImageException('Piz compression not yet supported.');
  }

  Uint8List uncompress(InputBuffer inPtr, int y) {
    int tmpBufferEnd = 0;
    List<ExrChannel> channels = _header.channels;
    for (int i = 0; i < channels.length; ++i) {
      ExrChannel ch = channels[i];
      _PizChannelData cd = _channelData[i];
      cd.start = tmpBufferEnd;
      cd.end = cd.start;

      cd.nx = _numSamples(ch.xSampling, 0, _header.width);
      cd.ny = _numSamples(ch.ySampling, 0, _header._linesInBuffer);
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
    for (int i = 0; i < channels.length; ++i) {
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

    // Rearrange the pixel data into the format expected by the caller.
    //char *outEnd = _outBuffer;
    for (int y = 0; y <= _numScanLines; ++y) {
      for (int i = 0; i < channels.length; ++i) {
        _PizChannelData cd = _channelData[i];

        if ((y % cd.ys) != 0) {
          continue;
        }

        for (int x = cd.nx * cd.size; x > 0; --x) {
          _output.writeByte(_tmpBuffer[cd.end++]);
        }
      }
    }
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
  Uint8List _tmpBuffer;
}

class _PizChannelData {
  int start;
  int end;
  int nx;
  int ny;
  int ys;
  int size;
}
