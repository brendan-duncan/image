part of image;

class GifImageDesc {
  int x;
  int y;
  int width;
  int height;
  bool interlaced;
  GifColorMap colorMap;
  int duration = 80;
  bool clearFrame = true;

  GifImageDesc(Arc.InputStream input) {
    x = input.readUint16();
    y = input.readUint16();
    width = input.readUint16();
    height = input.readUint16();

    int b = input.readByte();

    int bitsPerPixel = (b & 0x07) + 1;

    interlaced = (b & 0x40) != 0;

    if (b & 0x80 != 0) {
      colorMap = new GifColorMap(1 << bitsPerPixel);

      for (int i = 0; i < colorMap.numColors; ++i) {
        colorMap.setColor(i, input.readByte(), input.readByte(),
                          input.readByte());
      }
    }

    _inputPosition = input.position;
  }

  /// The position in the file after the ImageDesc for this frame.
  int _inputPosition;
}

