import 'dart:math';
import 'dart:typed_data';

import '../color/color.dart';
import '../color/color_uint1.dart';
import '../color/format.dart';
import 'image_data.dart';
import 'palette.dart';
import 'pixel.dart';
import 'pixel_range_iterator.dart';
import 'pixel_uint1.dart';

class ImageDataUint1 extends ImageData {
  late final Uint8List data;
  final int rowStride;
  final Palette? palette;

  ImageDataUint1(int width, int height, int numChannels)
      : rowStride = ((width * numChannels) / 8).ceil()
      , palette = null
      , super(width, height, numChannels) {
    data = Uint8List(max(rowStride * height, 1));
  }
  
  ImageDataUint1.palette(int width, int height, this.palette)
      : rowStride = (width / 8).ceil()
      , super(width, height, 1) {
    data = Uint8List(max(rowStride * height, 1));
  }

  ImageDataUint1.from(ImageDataUint1 other, { bool skipPixels = false })
      : data = skipPixels ? Uint8List(other.data.length)
          : Uint8List.fromList(other.data)
      , rowStride = other.width * other.numChannels
      , palette = other.palette?.clone()
      , super(other.width, other.height, other.numChannels);

  ImageDataUint1 clone({ bool noPixels = false }) =>
      ImageDataUint1.from(this, skipPixels: noPixels);

  Format get format => Format.uint1;

  FormatType get formatType => FormatType.uint;

  int get lengthInBytes => data.lengthInBytes;

  int get length => data.lengthInBytes;

  num get maxChannelValue => 1;

  bool get isHdrFormat => false;

  ByteBuffer get buffer => data.buffer;

  int get bitsPerChannel => 1;

  PixelUint1 get iterator => PixelUint1.imageData(this);

  Iterator<Pixel> getRange(int x, int y, int width, int height) =>
      PixelRangeIterator(PixelUint1.imageData(this), x, y, width, height);

  Color getColor(num r, num g, num b, [num? a]) =>
      a == null ? ColorUint1.rgb(r.toInt(), g.toInt(), b.toInt())
          : ColorUint1.rgba(r.toInt(), g.toInt(), b.toInt(), a.toInt());

  Pixel getPixel(int x, int y, [Pixel? pixel]) {
    if (pixel == null || pixel is! PixelUint1 || pixel.data != this) {
      pixel = PixelUint1.imageData(this);
    }
    pixel.setPosition(x, y);
    return pixel;
  }

  PixelUint1? _pixel;

  void setPixelColor(int x, int y, num r, [num g = 0, num b = 0, num a = 1]) {
    if (numChannels < 1) {
      return;
    }

    if (_pixel == null) {
      _pixel = PixelUint1.imageData(this);
    }
    _pixel!.setPosition(x, y);
    _pixel!.setColor(r, g, b, a);
  }

  String toString() => 'ImageDataUint1($width, $height, $numChannels)';

  void clear([Color? c]) { }
}
