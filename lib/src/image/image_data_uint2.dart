import 'dart:math';
import 'dart:typed_data';

import '../color/color.dart';
import '../color/color_uint2.dart';
import '../color/format.dart';
import 'image_data.dart';
import 'palette.dart';
import 'pixel.dart';
import 'pixel_range_iterator.dart';
import 'pixel_uint2.dart';

class ImageDataUint2 extends ImageData {
  late final Uint8List data;
  final int rowStride;
  final Palette? palette;

  ImageDataUint2(int width, int height, int numChannels)
      : rowStride = ((width * (numChannels << 1)) / 8).ceil()
      , palette = null
      , super(width, height, numChannels) {
    data = Uint8List(max(rowStride * height, 1));
  }

  ImageDataUint2.palette(int width, int height, this.palette)
      : rowStride = (width / 4).ceil()
      , super(width, height, 1) {
    data = Uint8List(max(rowStride * height, 1));
  }

  ImageDataUint2.from(ImageDataUint2 other, { bool skipPixels = false })
      : data = skipPixels ? Uint8List(other.data.length)
          : Uint8List.fromList(other.data)
      , rowStride = other.rowStride
      , palette = other.palette?.clone()
      , super(other.width, other.height, other.numChannels);

  ImageDataUint2 clone({ bool noPixels = false }) =>
      ImageDataUint2.from(this, skipPixels: noPixels);

  Format get format => Format.uint2;

  FormatType get formatType => FormatType.uint;

  int get bitsPerChannel => 2;

  ByteBuffer get buffer => data.buffer;

  PixelUint2 get iterator => PixelUint2.imageData(this);

  Iterator<Pixel> getRange(int x, int y, int width, int height) =>
      PixelRangeIterator(PixelUint2.imageData(this), x, y, width, height);

  int get lengthInBytes => data.lengthInBytes;

  int get length => data.lengthInBytes;

  num get maxChannelValue => palette?.maxChannelValue ?? 3;

  num get maxIndexValue => 3;

  bool get isHdrFormat => false;

  Color getColor(num r, num g, num b, [num? a]) =>
      a == null ? ColorUint2.rgb(r.toInt(), g.toInt(), b.toInt())
          : ColorUint2.rgba(r.toInt(), g.toInt(), b.toInt(), a.toInt());

  Pixel getPixel(int x, int y, [Pixel? pixel]) {
    if (pixel == null || pixel is! PixelUint2 || pixel.image != this) {
      pixel = PixelUint2.imageData(this);
    }
    pixel.setPosition(x, y);
    return pixel;
  }

  PixelUint2? _pixel;

  void setPixelColor(int x, int y, num r, [num g = 0, num b = 0, num a = 3]) {
    if (numChannels < 1) {
      return;
    }

    if (_pixel == null) {
      _pixel = PixelUint2.imageData(this);
    }
    _pixel!.setPosition(x, y);
    _pixel!.setColor(r, g, b, a);
  }

  String toString() => 'ImageDataUint2($width, $height, $numChannels)';

  void clear([Color? c]) { }
}
