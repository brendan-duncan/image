part of image;

class ExrPart {
  /// The framebuffer for this exr part.
  HdrImage framebuffer = new HdrImage();
  /// The channels present in this part.
  List<ExrChannel> channels = [];
  /// The extra attributes read from the part header.
  Map<String, ExrAttribute> attributes = {};
  /// The display window (see the openexr documentation).
  List<int> displayWindow;
  /// The data window (see the openexr documentation).
  List<int> dataWindow;
  /// width of the data window
  int width;
  /// Height of the data window
  int height;
  double pixelAspectRatio = 1.0;
  double screenWindowCenterX = 0.0;
  double screenWindowCenterY = 0.0;
  double screenWindowWidth = 1.0;
  Float32List chromaticities;

  ExrPart(this._tiled, InputBuffer input) {
    _type = _tiled ? ExrPart.TYPE_TILE : ExrPart.TYPE_SCANLINE;

    while (true) {
      String name = input.readString();
      if (name == null || name.isEmpty) {
        break;
      }

      String type = input.readString();
      int size = input.readUint32();
      InputBuffer value = input.readBytes(size);

      attributes[name] = new ExrAttribute(name, type, size, value);

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
          dataWindow = [value.readInt32(), value.readInt32(),
                        value.readInt32(), value.readInt32()];
          width = (dataWindow[2] - dataWindow[0]) + 1;
          height = (dataWindow[3] - dataWindow[1]) + 1;
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
        case 'tiles':
          _tileWidth = value.readUint32();
          _tileHeight = value.readUint32();
          int mode = value.readByte();
          _tileLevelMode = mode & 0xf;
          _tileRoundingMode = (mode >> 4) & 0xf;
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
          break;
      }
    }

    if (_tiled) {
      _numXLevels = _calculateNumXLevels(left, right, top, bottom);
      _numYLevels = _calculateNumYLevels(left, right, top, bottom);
      if (_tileLevelMode != RIPMAP_LEVELS) {
        _numYLevels = 1;
      }

      _numXTiles = new List<int>(_numXLevels);
      _numYTiles = new List<int>(_numYLevels);

      _calculateNumTiles(_numXTiles, _numXLevels, left, right, _tileWidth,
                         _tileRoundingMode);

      _calculateNumTiles(_numYTiles, _numYLevels, top, bottom, _tileHeight,
                         _tileRoundingMode);

      _bytesPerPixel = _calculateBytesPerPixel();
      _maxBytesPerTileLine = _bytesPerPixel * _tileWidth;
      _tileBufferSize = _maxBytesPerTileLine * _tileHeight;

      _compressor = new ExrCompressor(_compressionType, this,
                                      _maxBytesPerTileLine, _tileHeight);

      _offsets = new List<Uint32List>(_numXLevels * _numYLevels);
      for (int ly = 0, l = 0; ly < _numYLevels; ++ly) {
        for (int lx = 0; lx < _numXLevels; ++lx, ++l) {
          _offsets[l] = new Uint32List(_numXTiles[lx] * _numYTiles[ly]);
        }
      }
    } else {
      _bytesPerLine = new Uint32List(height + 1);
      for (ExrChannel ch in channels) {
        int nBytes = ch.size * width ~/ ch.xSampling;
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

      _compressor = new ExrCompressor(_compressionType, this, maxBytesPerLine);

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

      int numOffsets = ((height + _linesInBuffer) ~/ _linesInBuffer) - 1;
      _offsets = [new Uint32List(numOffsets)];
    }
  }

  int get left => dataWindow[0];

  int get top => dataWindow[1];

  int get right => dataWindow[2];

  int get bottom => dataWindow[3];

  /**
   * Was this part successfully decoded?
   */
  bool get isValid => width != null;

  int _calculateNumXLevels(int minX, int maxX, int minY, int maxY) {
    int num = 0;

    switch (_tileLevelMode) {
      case ONE_LEVEL:
        num = 1;
        break;
      case MIPMAP_LEVELS:
        int w = maxX - minX + 1;
        int h = maxY - minY + 1;
        num = _roundLog2(Math.max(w, h), _tileRoundingMode) + 1;
        break;
      case RIPMAP_LEVELS:
        int w = maxX - minX + 1;
        num = _roundLog2(w, _tileRoundingMode) + 1;
        break;
      default:
        throw new ImageException("Unknown LevelMode format.");
    }

    return num;
  }


  int _calculateNumYLevels(int minX, int maxX, int minY, int maxY) {
    int num = 0;

    switch (_tileLevelMode) {
      case ONE_LEVEL:
        num = 1;
        break;
      case MIPMAP_LEVELS:
        int w = (maxX - minX) + 1;
        int h = (maxY - minY) + 1;
        num = _roundLog2(Math.max(w, h), _tileRoundingMode) + 1;
        break;
      case RIPMAP_LEVELS:
        int h = (maxY - minY) + 1;
        num = _roundLog2(h, _tileRoundingMode) + 1;
        break;
      default:
        throw new ImageException('Unknown LevelMode format.');
    }

    return num;
  }

  int _roundLog2(int x, int rmode) {
    return (rmode == ROUND_DOWN) ? _floorLog2(x) : _ceilLog2(x);
  }

  int _floorLog2(int x) {
    int y = 0;

    while (x > 1) {
      y +=  1;
      x >>= 1;
    }

    return y;
  }


  int _ceilLog2(int x) {
    int y = 0;
    int r = 0;

    while (x > 1) {
      if (x & 1 != 0) {
        r = 1;
      }

      y +=  1;
      x >>= 1;
    }

    return y + r;
  }

  void _readOffsets(InputBuffer input) {
    if (_tiled) {
      for (int i = 0; i < _offsets.length; ++i) {
        for (int j = 0; j < _offsets[i].length; ++j) {
          _offsets[i][j] = input.readUint64();
        }
      }
    } else {
      int numOffsets = _offsets[0].length;
      for (int i = 0; i < numOffsets; ++i) {
        _offsets[0][i] = input.readUint64();
      }
    }
  }

  int _calculateBytesPerPixel() {
    int bytesPerPixel = 0;

    for (ExrChannel ch in channels) {
      bytesPerPixel += ch.size;
    }

    return bytesPerPixel;
  }

  void _calculateNumTiles(List<int> numTiles, int numLevels,
                          int min, int max, int size, int rmode) {
    for (int i = 0; i < numLevels; i++) {
      numTiles[i] = (_levelSize(min, max, i, rmode) + size - 1) ~/ size;
    }
  }

  int _levelSize(int min, int max, int l, int rmode) {
    if (l < 0) {
      throw new ImageException('Argument not in valid range.');
    }

    int a = (max - min) + 1;
    int b = (1 << l);
    int size = a ~/ b;

    if (rmode == ROUND_UP && size * b < a) {
      size += 1;
    }

    return Math.max(size, 1);
  }

  static const int TYPE_SCANLINE = 0;
  static const int TYPE_TILE = 1;
  static const int TYPE_DEEP_SCANLINE = 2;
  static const int TYPE_DEEP_TILE = 3;

  static const int INCREASING_Y = 0;
  static const int DECREASING_Y = 1;
  static const int RANDOM_Y = 2;

  static const int ONE_LEVEL = 0;
  static const int MIPMAP_LEVELS = 1;
  static const int RIPMAP_LEVELS = 2;

  static const int ROUND_DOWN = 0;
  static const int ROUND_UP = 1;

  int _type;
  int _lineOrder = INCREASING_Y;
  int _compressionType = ExrCompressor.NO_COMPRESSION;
  List<Uint32List> _offsets;

  Uint32List _bytesPerLine;
  ExrCompressor _compressor;
  int _linesInBuffer;
  int _lineBufferSize;
  Uint32List _offsetInLineBuffer;

  bool _tiled;
  int _tileWidth;
  int _tileHeight;
  int _tileLevelMode;
  int _tileRoundingMode;
  List<int> _numXTiles;
  List<int> _numYTiles;
  int _numXLevels;
  int _numYLevels;
  int _bytesPerPixel;
  int _maxBytesPerTileLine;
  int _tileBufferSize;
}
