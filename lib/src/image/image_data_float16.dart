import 'dart:typed_data';

import '../color/color.dart';
import '../color/color_float16.dart';
import '../color/format.dart';
import '../util/float16.dart';
import 'image_data.dart';
import 'pixel.dart';
import 'pixel_float16.dart';
import 'pixel_range_iterator.dart';

class ImageDataFloat16 extends ImageData {
  final Uint16List data;

  ImageDataFloat16(int width, int height, int numChannels)
      : data = Uint16List(width * height * numChannels)
      , super(width, height, numChannels);

  ImageDataFloat16.from(ImageDataFloat16 other, { bool skipPixels = false })
      : data = skipPixels ? Uint16List(other.data.length) :
          Uint16List.fromList(other.data)
      , super(other.width, other.height, other.numChannels);

  ImageDataFloat16 clone({ bool noPixels = false }) =>
      ImageDataFloat16.from(this, skipPixels: noPixels);

  Format get format => Format.float16;

  FormatType get formatType => FormatType.float;

  ByteBuffer get buffer => data.buffer;

  int get bitsPerChannel => 16;

  int get rowStride => width * numChannels * 2;

  PixelFloat16 get iterator => PixelFloat16.imageData(this);

  Iterator<Pixel> getRange(int x, int y, int width, int height) =>
    PixelRangeIterator(PixelFloat16.imageData(this), x, y, width, height);

  int get lengthInBytes => data.lengthInBytes;

  int get length => data.lengthInBytes;

  num get maxChannelValue => 1.0;

  bool get isHdrFormat => true;

  Color getColor(num r, num g, num b, [num? a]) =>
      a == null ? ColorFloat16.rgb(r, g, b) : ColorFloat16.rgba(r, g, b, a);

  Pixel getPixel(int x, int y, [Pixel? pixel]) {
    if (pixel == null || pixel is! PixelFloat16 || pixel.data != this) {
      pixel = PixelFloat16.imageData(this);
    }
    pixel.setPosition(x, y);
    return pixel;
  }

  void setPixelColor(int x, int y, num r, [num g = 0, num b = 0, num a = 0]) {
    final index = y * width * numChannels + (x * numChannels);
    data[index] = Float16.doubleToFloat16(r);
    if (numChannels > 1) {
      data[index + 1] = Float16.doubleToFloat16(g);
      if (numChannels > 2) {
        data[index + 2] = Float16.doubleToFloat16(b);
        if (numChannels > 3) {
          data[index + 3] = Float16.doubleToFloat16(a);
        }
      }
    }
  }

  String toString() => 'ImageDataFloat16($width, $height, $numChannels)';

  void clear([Color? c]) { }
}
