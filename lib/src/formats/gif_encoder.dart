part of image;

/**
 *
 */
class GifEncoder {
  GifEncoder({this.delay: 80}) :
    _encodedFrames = 0;

  void addFrame(Image image, {int delay}) {
    if (output == null) {
      output = new OutputStream();

      if (delay != null) {
        this.delay = delay;
      }
      _lastColorMap = new NeuralQuantizer(image);
      _lastImage = _lastColorMap.getIndexMap(image);
      _width = image.width;
      _height = image.height;
      return;
    }

    if (_encodedFrames == 0) {
      _writeHeader(_width, _height);
    }

    _writeGraphicsCtrlExt();
    _addImage(_lastImage, _width, _height, _lastColorMap.colorMap, 256);
    _encodedFrames++;

    if (delay != null) {
      this.delay = delay;
    }
    _lastColorMap = new NeuralQuantizer(image);
    _lastImage = _lastColorMap.getIndexMap(image);
  }

  /**
   * Encode the images that were added with [addFrame].
   */
  List<int> encode() {
    List<int> bytes;
    if (output == null) {
      return bytes;
    }

    if (_encodedFrames == 0) {
      _writeHeader(_width, _height);
    } else {
      _writeGraphicsCtrlExt();
    }

    _addImage(_lastImage, _width, _height, _lastColorMap.colorMap, 256);

    output.writeByte(TERMINATE_RECORD_TYPE);

    _lastImage = null;
    _lastColorMap = null;
    _encodedFrames = 0;

    bytes = output.getBytes();
    output = null;
    return bytes;
  }

  /**
   * Encode a single frame image.
   */
  List<int> encodeImage(Image image) {
    output = new OutputStream();
    List<int> bytes = output.getBytes();
    output = null;
    return bytes;
  }

  /**
   * Encode an animation.
   */
  List<int> encodeAnimation(Animation anim) {
    output = new OutputStream();
    List<int> bytes = output.getBytes();
    output = null;
    return bytes;
  }

  void _addImage(Uint8List image, int width, int height,
                 Uint8List colorMap, int numColors) {
    // Image desc
    output.writeByte(0x2c); // image separator
    output.writeUint16(0); // image position x,y = 0,0
    output.writeUint16(0);
    output.writeUint16(width); // image size
    output.writeUint16(height);

    // Local color map
    // 10000111 (1-use lcm, 111-7 palette size)
    output.writeByte(0x87);
    output.writeBytes(colorMap);
    for (int i = numColors; i < 256; ++i) {
      output.writeByte(0);
      output.writeByte(0);
      output.writeByte(0);
    }
  }

  void _writeGraphicsCtrlExt() {
    output.writeByte(EXTENSION_RECORD_TYPE);
    output.writeByte(GRAPHIC_CONTROL_EXT);
    output.writeByte(4); // data block size

    int transparency = 0;
    int dispose = 0; // dispose = no action

    // packed fields
    output.writeByte(0 |       // 1:3 reserved
                     dispose | // 4:6 disposal
                     0 |       // 7   user input - 0 = none
                     transparency); // 8   transparency flag

    output.writeUint16(delay); // delay x 1/100 sec
    output.writeByte(0); // transparent color index
    output.writeByte(0); // block terminator
  }

  /**
   * GIF header and Logical Screen Descriptor
   */
  void _writeHeader(int width, int height) {
    output.writeBytes(GIF89_STAMP.codeUnits);
    output.writeUint16(width);
    output.writeUint16(height);
    output.writeByte(0); // global color map parameters (not being used).
    output.writeByte(0); // background color index.
    output.writeByte(0); // aspect
  }

  int background;
  int delay;
  int repeat;

  Uint8List _lastImage;
  NeuralQuantizer _lastColorMap;
  int _width;
  int _height;
  int _encodedFrames;

  OutputStream output;

  static const String GIF89_STAMP = 'GIF89a';

  static const int IMAGE_DESC_RECORD_TYPE = 0x2c;
  static const int EXTENSION_RECORD_TYPE = 0x21;
  static const int TERMINATE_RECORD_TYPE = 0x3b;

  static const int GRAPHIC_CONTROL_EXT = 0xf9;

  static const int EOF = -1;
  static const int BITS = 12;
  static const int HSIZE = 5003; // 80% occupancy
  static const List<int> MASKS = const [
    0x0000, 0x0001, 0x0003, 0x0007, 0x000F, 0x001F,
    0x003F, 0x007F, 0x00FF, 0x01FF, 0x03FF, 0x07FF,
    0x0FFF, 0x1FFF, 0x3FFF, 0x7FFF, 0xFFFF];
}
