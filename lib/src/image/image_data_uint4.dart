import 'dart:math';
import 'dart:typed_data';

import '../color/color.dart';
import '../color/color_uint4.dart';
import '../color/format.dart';
import 'image_data.dart';
import 'palette.dart';
import 'pixel.dart';
import 'pixel_range_iterator.dart';
import 'pixel_uint4.dart';

class ImageDataUint4 extends ImageData {
  late final Uint8List data;
  final int rowStride;
  final Palette? palette;

  ImageDataUint4(int width, int height, int numChannels)
      : rowStride = numChannels == 2 ? width
          : numChannels == 4 ? width * 2
          : numChannels == 3 ? (width * 1.5).ceil()
          : (width / 2).ceil()
      , palette = null
      , super(width, height, numChannels) {
    data = Uint8List(max(rowStride * height, 1));
  }

  ImageDataUint4.palette(int width, int height, this.palette)
      : rowStride = (width / 2).ceil()
      , super(width, height, 1) {
    data = Uint8List(max(rowStride * height, 1));
  }

  ImageDataUint4.from(ImageDataUint4 other, { bool skipPixels = false })
      : data = skipPixels ? Uint8List(other.data.length)
          : Uint8List.fromList(other.data)
      , rowStride = other.rowStride
      , palette = other.palette?.clone()
      , super(other.width, other.height, other.numChannels);

  ImageDataUint4 clone({ bool noPixels = false }) =>
      ImageDataUint4.from(this, skipPixels: noPixels);

  Format get format => Format.uint4;

  FormatType get formatType => FormatType.uint;

  ByteBuffer get buffer => data.buffer;

  PixelUint4 get iterator => PixelUint4.imageData(this);

  Iterator<Pixel> getRange(int x, int y, int width, int height) =>
      PixelRangeIterator(PixelUint4.imageData(this), x, y, width, height);

  int get lengthInBytes => data.lengthInBytes;

  int get length => data.lengthInBytes;

  num get maxChannelValue => palette?.maxChannelValue ?? 15;

  num get maxIndexValue => 15;

  bool get isHdrFormat => false;

  int get bitsPerChannel => 4;

  Color getColor(num r, num g, num b, [num? a]) =>
      a == null ? ColorUint4.rgb(r.toInt(), g.toInt(), b.toInt())
          : ColorUint4.rgba(r.toInt(), g.toInt(), b.toInt(), a.toInt());

  Pixel getPixel(int x, int y, [Pixel? pixel]) {
    if (pixel == null || pixel is! PixelUint4 || pixel.data != this) {
      pixel = PixelUint4.imageData(this);
    }
    pixel.setPosition(x, y);
    return pixel;
  }

  PixelUint4? _pixel;

  void setPixelColor(int x, int y, num r, [num g = 0, num b = 0, num a = 15]) {
    if (numChannels == 0) {
      return;
    }

    if (_pixel == null) {
      _pixel = PixelUint4.imageData(this);
    }
    _pixel!.setPosition(x, y);
    _pixel!.setColor(r, g, b, a);
  }

  String toString() => 'ImageDataUint4($width, $height, $numChannels)';

  void clear([Color? c]) { }
}
