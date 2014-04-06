part of image;

class ExrPart {
  /// The framebuffer for this exr part.
  ExrFrameBuffer framebuffer = new ExrFrameBuffer();
  /// The channels present in this part.
  List<ExrChannel> channels = [];
  /// The extra attributes read from the part header.
  Map<String, ExrAttribute> attributes = {};
  /// The display window (see the openexr documentation).
  List<int> displayWindow;
  /// dataWindow top
  int top;
  /// dataWindow left
  int left;
  /// dataWindow bottom
  int bottom;
  /// dataWindow right
  int right;
  /// width of the data window
  int width;
  /// Height of the data window
  int height;
  double pixelAspectRatio = 1.0;
  double screenWindowCenterX = 0.0;
  double screenWindowCenterY = 0.0;
  double screenWindowWidth = 1.0;
  Float32List chromaticities;

  ExrPart(bool tiled, InputBuffer input) {
    _type = tiled ? ExrPart.TYPE_TILE : ExrPart.TYPE_SCANLINE;

    while (true) {
      String name = input.readString();
      if (name == null || name.isEmpty) {
        break;
      }

      String type = input.readString();
      int size = input.readUint32();
      InputBuffer value = input.readBytes(size);

      switch (name) {
        case 'channels':
          while (true) {
            ExrChannel channel = new ExrChannel(value);
            if (!channel.isValid) {
              break;
            }
            channels.add(channel);
          }
          break;
        case 'chromaticities':
          chromaticities = new Float32List(8);
          chromaticities[0] = value.readFloat32();
          chromaticities[1] = value.readFloat32();
          chromaticities[2] = value.readFloat32();
          chromaticities[3] = value.readFloat32();
          chromaticities[4] = value.readFloat32();
          chromaticities[5] = value.readFloat32();
          chromaticities[6] = value.readFloat32();
          chromaticities[7] = value.readFloat32();
          break;
        case 'compression':
          _compressionType = value.readByte();
          if (_compressionType > 7) {
            throw new ImageException('EXR Invalid compression type');
          }
          break;
        case 'dataWindow':
          left = value.readInt32();
          top = value.readInt32();
          right = value.readInt32();
          bottom = value.readInt32();
          width = right - left;
          height = bottom - top;
          break;
        case 'displayWindow':
          displayWindow = [value.readInt32(), value.readInt32(),
                           value.readInt32(), value.readInt32()];
          break;
        case 'lineOrder':
          _lineOrder = value.readByte();
          break;
        case 'pixelAspectRatio':
          pixelAspectRatio = value.readFloat32();
          break;
        case 'screenWindowCenter':
          screenWindowCenterX = value.readFloat32();
          screenWindowCenterY = value.readFloat32();
          break;
        case 'screenWindowWidth':
          screenWindowWidth = value.readFloat32();
          break;
        case 'type':
          String s = value.readString();
          if (s == 'deepscanline') {
            this._type = TYPE_DEEP_SCANLINE;
          } else if (s == 'deeptile') {
            this._type = TYPE_DEEP_TILE;
          } else {
            throw new ImageException('EXR Invalid type: $s');
          }
          break;
        default:
          attributes[name] = new ExrAttribute(name, type, size, value);
          break;
      }
    }

    _bytesPerLine = new Uint32List(height + 1);
    for (ExrChannel ch in channels) {
      int nBytes = ch.size * (width + 1) ~/ ch.xSampling;
      for (int y = 0; y < height; ++y) {
        if ((y + top) % ch.ySampling == 0) {
          _bytesPerLine[y] += nBytes;
        }
      }
    }

    int maxBytesPerLine = 0;
    for (int y = 0; y < height; ++y) {
      maxBytesPerLine = Math.max(maxBytesPerLine, _bytesPerLine[y]);
    }

    _compressor = new ExrCompressor(_compressionType, maxBytesPerLine, this);

    _linesInBuffer = _compressor.numScanLines();
    _lineBufferSize = maxBytesPerLine * _linesInBuffer;

    _offsetInLineBuffer = new Uint32List(_bytesPerLine.length);

    int offset = 0;
    for (int i = 0; i <= _bytesPerLine.length - 1; ++i) {
      if (i % _linesInBuffer == 0) {
        offset = 0;
      }
      _offsetInLineBuffer[i] = offset;
      offset += _bytesPerLine[i];
    }

    int numOffsets = (height + _linesInBuffer) ~/ _linesInBuffer;
    _offsets = new Uint32List(numOffsets);
  }

  /**
   * Was this part successfully decoded?
   */
  bool get isValid => width != null;

  void _readOffsets(InputBuffer input) {
    int numOffsets = _offsets.length;
    for (int i = 0; i < numOffsets; ++i) {
      _offsets[i] = input.readUint64();
    }
  }

  static const int TYPE_SCANLINE = 0;
  static const int TYPE_TILE = 1;
  static const int TYPE_DEEP_SCANLINE = 2;
  static const int TYPE_DEEP_TILE = 3;

  static const int INCREASING_Y = 0;
  static const int DECREASING_Y = 1;
  static const int RANDOM_Y = 2;

  int _type;
  int _lineOrder = INCREASING_Y;
  int _compressionType = ExrCompressor.NO_COMPRESSION;
  List<int> _offsets = [];
  Uint32List _bytesPerLine;
  ExrCompressor _compressor;
  int _linesInBuffer;
  int _lineBufferSize;
  Uint32List _offsetInLineBuffer;
}
