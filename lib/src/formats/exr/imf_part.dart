part of image;

class ImfPart {
  static const int TYPE_SCANLINE = 0;
  static const int TYPE_TILE = 1;
  static const int TYPE_DEEP_SCANLINE = 2;
  static const int TYPE_DEEP_TILE = 3;

  static const int NO_COMPRESSION = 0;
  static const int RLE_COMPRESSION = 1;
  static const int ZIPS_COMPRESSION = 2;
  static const int ZIP_COMPRESSION = 3;
  static const int PIZ_COMPRESSION = 4;
  static const int PXR24_COMPRESSION = 5;
  static const int B44_COMPRESSION = 6;
  static const int B44A_COMPRESSION = 7;

  static const int INCREASING_Y = 0;
  static const int DECREASING_Y = 1;
  static const int RANDOM_Y = 2;

  Map<String, ImfAttribute> attributes = {};
  List<int> displayWindow;
  List<int> dataWindow;
  int type;
  int width;
  int height;
  int lineOrder = INCREASING_Y;
  int compression = NO_COMPRESSION;
  double pixelAspectRatio = 1.0;
  double screenWindowCenterX = 0.0;
  double screenWindowCenterY = 0.0;
  double screenWindowWidth = 1.0;
  List<int> offsets = [];
  List<ImfChannel> channels = [];

  ImfPart(bool tiled, InputBuffer input) {
    type = tiled ? ImfPart.TYPE_TILE : ImfPart.TYPE_SCANLINE;

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
          dataWindow = [value.readInt32(), value.readInt32(),
                        value.readInt32(), value.readInt32()];
          width = dataWindow[2] - dataWindow[0];
          height = dataWindow[3] - dataWindow[1];
          break;
        case 'displayWindow':
          displayWindow = [value.readInt32(), value.readInt32(),
                           value.readInt32(), value.readInt32()];
          break;
        case 'compression':
          compression = value.readByte();
          if (compression > 7) {
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
            ImfChannel channel = new ImfChannel(value);
            if (!channel.isValid) {
              break;
            }
            channels.add(channel);
          }
          break;
        default:
          print(name);
          attributes[name] = new ImfAttribute(name, type, size, value);
          break;
      }
    }
  }

  bool get isValid => width != null;


  void readOffsets(InputBuffer input) {
    int numOffsets = height;
    offsets = new Uint32List(numOffsets);
    for (int i = 0; i < numOffsets; ++i) {
      offsets[i] = input.readUint64();
    }
  }
}
