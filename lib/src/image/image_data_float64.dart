import 'dart:typed_data';

import '../color/color.dart';
import '../color/color_float64.dart';
import '../color/format.dart';
import 'image_data.dart';
import 'pixel.dart';
import 'pixel_float64.dart';
import 'pixel_range_iterator.dart';

class ImageDataFloat64 extends ImageData {
  final Float64List data;

  ImageDataFloat64(int width, int height, int numChannels)
      : data = Float64List(width * height * 4 * numChannels)
      , super(width, height, numChannels);

  ImageDataFloat64.from(ImageDataFloat64 other)
      : data = Float64List.fromList(other.data)
      , super(other.width, other.height, other.numChannels);

  ImageDataFloat64 clone() => ImageDataFloat64.from(this);

  Format get format => Format.float64;

  FormatType get formatType => FormatType.float;

  ByteBuffer get buffer => data.buffer;

  int get length => data.lengthInBytes;

  int get bitsPerChannel => 64;

  PixelFloat64 get iterator => PixelFloat64.imageData(this);

  Iterator<Pixel> getRange(int x, int y, int width, int height) =>
      PixelRangeIterator(PixelFloat64.imageData(this), x, y, width, height);

  int get lengthInBytes => data.lengthInBytes;

  num get maxChannelValue => 1.0;

  int get rowStride => width * numChannels * 8;

  bool get isHdrFormat => true;

  Color getColor(num r, num g, num b, [num? a]) =>
      a == null ? ColorFloat64.rgb(r, g, b) : ColorFloat64.rgba(r, g, b, a);

  Pixel getPixel(int x, int y, [Pixel? pixel]) {
    if (pixel == null || pixel is! PixelFloat64 || pixel.data != this) {
      pixel = PixelFloat64.imageData(this);
    }
    pixel.setPosition(x, y);
    return pixel;
  }

  void setPixelColor(int x, int y, num r, [num g = 0, num b = 0, num a = 0]) {
    final index = y * width * numChannels + (x * numChannels);
    data[index] = r.toDouble();
    if (numChannels > 1) {
      data[index + 1] = g.toDouble();
      if (numChannels > 2) {
        data[index + 2] = b.toDouble();
        if (numChannels > 3) {
          data[index + 3] = a.toDouble();
        }
      }
    }
  }

  String toString() => 'ImageDataFloat64($width, $height, $numChannels)';

  void clear([Color? c]) { }
}
