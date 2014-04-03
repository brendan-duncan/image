part of image;

class ImfChannel {
  static const int TYPE_UINT = 0;
  static const int TYPE_HALF = 1;
  static const int TYPE_FLOAT = 2;

  String name;
  int type;
  int size;
  bool pLinear;
  int xSampling;
  int ySampling;

  ImfChannel(InputBuffer input) {
    name = input.readString();
    if (name == null || name.isEmpty) {
      name = null;
      return;
    }
    type = input.readUint32();
    int i = input.readByte();
    assert(i == 0 || i == 1);
    pLinear = i == 1;
    input.skip(3);
    xSampling = input.readUint32();
    ySampling = input.readUint32();

    switch (type) {
      case TYPE_UINT:
        size = 4;
        break;
      case TYPE_HALF:
        size = 2;
        break;
      case TYPE_FLOAT:
        size = 4;
        break;
      default:
        throw new ImageException('EXR Invalid pixel type: $type');
    }
  }

  bool get isValid => name != null;
}
