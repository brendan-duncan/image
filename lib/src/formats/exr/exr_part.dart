part of image;

class ExrPart {
  static const int TYPE_SCANLINE = 0;
  static const int TYPE_TILE = 1;
  static const int TYPE_DEEP_SCANLINE = 2;
  static const int TYPE_DEEP_TILE = 3;

  static const int INCREASING_Y = 0;
  static const int DECREASING_Y = 1;
  static const int RANDOM_Y = 2;

  Map<String, ExrAttribute> attributes = {};
  List<int> displayWindow;
  int top;
  int left;
  int bottom;
  int right;
  int type;
  int width;
  int height;
  int lineOrder = INCREASING_Y;
  int compressionType = ExrCompressor.NO_COMPRESSION;
  double pixelAspectRatio = 1.0;
  double screenWindowCenterX = 0.0;
  double screenWindowCenterY = 0.0;
  double screenWindowWidth = 1.0;
  List<int> offsets = [];
  List<ExrChannel> channels = [];
  Uint32List bytesPerLine;
  ExrCompressor compressor;
  //int format;
  int linesInBuffer;
  int lineBufferSize;
  int nextLineBufferMinY;
  Uint32List offsetInLineBuffer;
  ExrFrameBuffer framebuffer = new ExrFrameBuffer();

  ExrPart(bool tiled, InputBuffer input) {
    type = tiled ? ExrPart.TYPE_TILE : ExrPart.TYPE_SCANLINE;

    while (true) {
      String name = input.readString();
      if (name == null || name.isEmpty) {
        break;
      }

      String type = input.readString();
      int size = input.readUint32();
      InputBuffer value = input.readBytes(size);

      switch (name) {
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
        case 'compression':
          compressionType = value.readByte();
          if (compressionType > 7) {
            throw new ImageException('EXR Invalid compression type');
          }
          break;
        case 'type':
          String s = value.readString();
          if (s == 'deepscanline') {
            this.type = TYPE_DEEP_SCANLINE;
          } else if (s == 'deeptile') {
            this.type = TYPE_DEEP_TILE;
          } else {
            throw new ImageException('EXR Invalid type: $s');
          }
          break;
        case 'lineOrder':
          lineOrder = value.readByte();
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
        case 'channels':
          while (true) {
            ExrChannel channel = new ExrChannel(value);
            if (!channel.isValid) {
              break;
            }
            channels.add(channel);
          }
          break;
        default:
          print(name);
          attributes[name] = new ExrAttribute(name, type, size, value);
          break;
      }
    }

    bytesPerLine = new Uint32List(height + 1);
    for (ExrChannel ch in channels) {
      int nBytes = ch.size * (width + 1) ~/ ch.xSampling;
      for (int y = 0; y < height; ++y) {
        if ((y + top) % ch.ySampling == 0) {
          bytesPerLine[y] += nBytes;
        }
      }
    }

    int maxBytesPerLine = 0;
    for (int y = 0; y < height; ++y) {
      maxBytesPerLine = Math.max(maxBytesPerLine, bytesPerLine[y]);
    }

    compressor = new ExrCompressor(compressionType, maxBytesPerLine, this);

    linesInBuffer = compressor.numScanLines();
    lineBufferSize = maxBytesPerLine * linesInBuffer;

    nextLineBufferMinY = top - 1;

    offsetInLineBuffer = new Uint32List(bytesPerLine.length);

    int offset = 0;
    for (int i = 0; i <= bytesPerLine.length - 1; ++i) {
      if (i % linesInBuffer == 0) {
        offset = 0;
      }
      offsetInLineBuffer[i] = offset;
      offset += bytesPerLine[i];
    }

    int numOffsets = (height + linesInBuffer) ~/ linesInBuffer;
    offsets = new Uint32List(numOffsets);
  }

  bool get isValid => width != null;


  void readOffsets(InputBuffer input) {
    int numOffsets = offsets.length;
    for (int i = 0; i < numOffsets; ++i) {
      offsets[i] = input.readUint64();
    }
  }
}
