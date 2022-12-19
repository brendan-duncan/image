import 'dart:typed_data';

import '../color/color.dart';
import '../color/color_uint16.dart';
import '../color/format.dart';
import 'image_data.dart';
import 'pixel.dart';
import 'pixel_range_iterator.dart';
import 'pixel_uint16.dart';

class ImageDataUint16 extends ImageData {
  final Uint16List data;

  ImageDataUint16(int width, int height, int numChannels)
      : data = Uint16List(width * height * numChannels)
      , super(width, height, numChannels);

  ImageDataUint16.from(ImageDataUint16 other)
      : data = Uint16List.fromList(other.data)
      , super(other.width, other.height, other.numChannels);

  ImageDataUint16 clone() => ImageDataUint16.from(this);

  Format get format => Format.uint16;

  FormatType get formatType => FormatType.uint;

  ByteBuffer get buffer => data.buffer;

  int get bitsPerChannel => 16;

  num get maxChannelValue => 0xffff;

  int get rowStride => width * numChannels * 2;

  PixelUint16 get iterator => PixelUint16.imageData(this);

  Iterator<Pixel> getRange(int x, int y, int width, int height) =>
      PixelRangeIterator(PixelUint16.imageData(this), x, y, width, height);

  int get lengthInBytes => data.lengthInBytes;

  int get length => data.lengthInBytes;

  bool get isHdrFormat => true;

  Color getColor(num r, num g, num b, [num? a]) =>
      a == null ? ColorUint16.rgb(r.toInt(), g.toInt(), b.toInt())
          : ColorUint16.rgba(r.toInt(), g.toInt(), b.toInt(), a.toInt());

  Pixel getPixel(int x, int y, [Pixel? pixel]) {
    if (pixel == null || pixel is! PixelUint16 || pixel.data != this) {
      pixel = PixelUint16.imageData(this);
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

  String toString() => 'ImageDataUint16($width, $height, $numChannels)';

  void clear([Color? c]) { }
}
