import 'dart:typed_data';

import '../color/color.dart';
import '../color/color_int32.dart';
import '../color/format.dart';
import 'image_data.dart';
import 'pixel.dart';
import 'pixel_int32.dart';
import 'pixel_range_iterator.dart';

class ImageDataInt32 extends ImageData {
  final Int32List data;

  ImageDataInt32(int width, int height, int numChannels)
      : data = Int32List(width * height * numChannels)
      , super(width, height, numChannels);

  ImageDataInt32.from(ImageDataInt32 other)
      : data = Int32List.fromList(other.data)
      , super(other.width, other.height, other.numChannels);

  ImageDataInt32 clone() => ImageDataInt32.from(this);

  Format get format => Format.int32;

  FormatType get formatType => FormatType.int;

  ByteBuffer get buffer => data.buffer;

  int get bitsPerChannel => 32;

  int get rowStride => width * numChannels * 4;

  PixelInt32 get iterator => PixelInt32.imageData(this);

  Iterator<Pixel> getRange(int x, int y, int width, int height) =>
      PixelRangeIterator(PixelInt32.imageData(this), x, y, width, height);

  int get lengthInBytes => data.lengthInBytes;

  int get length => data.lengthInBytes;

  num get maxChannelValue => 0x7fffffff;

  bool get isHdrFormat => true;

  Color getColor(num r, num g, num b, [num? a]) =>
      a == null ? ColorInt32.rgb(r.toInt(), g.toInt(), b.toInt())
          : ColorInt32.rgba(r.toInt(), g.toInt(), b.toInt(), a.toInt());

  Pixel getPixel(int x, int y, [Pixel? pixel]) {
    if (pixel == null || pixel is! PixelInt32 || pixel.data != this) {
      pixel = PixelInt32.imageData(this);
    }
    pixel.setPosition(x, y);
    return pixel;
  }

  void setPixelColor(int x, int y, num r, [num g = 0, num b = 0, num a = 0]) {
    int index = y * width * numChannels + (x * numChannels);
    data[index] = r.toInt();
    if (numChannels > 1) {
      data[index + 1] = g.toInt();
      if (numChannels > 2) {
        data[index + 2] = b.toInt();
        if (numChannels > 3) {
          data[index + 3] = a.toInt();
        }
      }
    }
  }

  String toString() => 'ImageDataInt32($width, $height, $numChannels)';

  void clear([Color? c]) { }
}
