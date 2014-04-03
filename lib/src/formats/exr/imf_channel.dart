part of image;

class ImfChannel {
  static const int TYPE_UINT = 0;
  static const int TYPE_HALF = 1;
  static const int TYPE_FLOAT = 2;

  String name;
  int type;
  bool pLinear;
  int xSample;
  int ySample;

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
    xSample = input.readUint32();
    ySample = input.readUint32();
  }

  bool get isValid => name != null;
}
