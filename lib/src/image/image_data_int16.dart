import 'dart:typed_data';

import '../color/color.dart';
import '../color/color_int16.dart';
import '../color/format.dart';
import 'image_data.dart';
import 'pixel.dart';
import 'pixel_int16.dart';
import 'pixel_range_iterator.dart';

class ImageDataInt16 extends ImageData {
  final Int16List data;

  ImageDataInt16(int width, int height, int numChannels)
      : data = Int16List(width * height * numChannels)
      , super(width, height, numChannels);

  ImageDataInt16.from(ImageDataInt16 other, { bool skipPixels = false })
      : data = skipPixels ? Int16List(other.data.length)
          : Int16List.fromList(other.data)
      , super(other.width, other.height, other.numChannels);

  ImageDataInt16 clone({ bool noPixels = false }) =>
      ImageDataInt16.from(this, skipPixels: noPixels);

  Format get format => Format.int16;

  FormatType get formatType => FormatType.int;

  ByteBuffer get buffer => data.buffer;

  PixelInt16 get iterator => PixelInt16.imageData(this);

  Iterator<Pixel> getRange(int x, int y, int width, int height) =>
      PixelRangeIterator(PixelInt16.imageData(this), x, y, width, height);

  int get lengthInBytes => data.lengthInBytes;

  int get length => data.lengthInBytes;

  num get maxChannelValue => 0x7fff;

  bool get isHdrFormat => true;

  int get bitsPerChannel => 16;

  int get rowStride => width * numChannels * 2;

  Color getColor(num r, num g, num b, [num? a]) =>
      a == null ? ColorInt16.rgb(r.toInt(), g.toInt(), b.toInt())
          : ColorInt16.rgba(r.toInt(), g.toInt(), b.toInt(), a.toInt());

  Pixel getPixel(int x, int y, [Pixel? pixel]) {
    if (pixel == null || pixel is! PixelInt16 || pixel.data != this) {
      pixel = PixelInt16.imageData(this);
    }
    pixel.setPosition(x, y);
    return pixel;
  }

  void setPixelColor(int x, int y, num r, [num g = 0, num b = 0, num a = 0]) {
    final index = y * width * numChannels + (x * numChannels);
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

  String toString() => 'ImageDataInt16($width, $height, $numChannels)';

  void clear([Color? c]) { }
}
