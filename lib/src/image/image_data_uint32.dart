import 'dart:typed_data';

import '../color/color.dart';
import '../color/color_uint32.dart';
import '../color/format.dart';
import 'image_data.dart';
import 'pixel.dart';
import 'pixel_range_iterator.dart';
import 'pixel_uint32.dart';

class ImageDataUint32 extends ImageData {
  final Uint32List data;

  ImageDataUint32(int width, int height, int numChannels)
      : data = Uint32List(width * height * numChannels)
      , super(width, height, numChannels);

  ImageDataUint32.from(ImageDataUint32 other, { bool skipPixels = false })
      : data = skipPixels ? Uint32List(other.data.length)
          : Uint32List.fromList(other.data)
      , super(other.width, other.height, other.numChannels);

  ImageDataUint32 clone({ bool noPixels = false }) =>
      ImageDataUint32.from(this, skipPixels: noPixels);

  Format get format => Format.uint32;

  FormatType get formatType => FormatType.uint;

  ByteBuffer get buffer => data.buffer;

  int get rowStride => width * numChannels * 4;

  int get bitsPerChannel => 32;

  num get maxChannelValue => 0xffffffff;

  PixelUint32 get iterator => PixelUint32.imageData(this);

  Iterator<Pixel> getRange(int x, int y, int width, int height) =>
      PixelRangeIterator(PixelUint32.imageData(this), x, y, width, height);

  int get lengthInBytes => data.lengthInBytes;

  int get length => data.lengthInBytes;

  bool get isHdrFormat => true;

  Color getColor(num r, num g, num b, [num? a]) =>
      a == null ? ColorUint32.rgb(r.toInt(), g.toInt(), b.toInt())
          : ColorUint32.rgba(r.toInt(), g.toInt(), b.toInt(), a.toInt());

  Pixel getPixel(int x, int y, [Pixel? pixel]) {
    if (pixel == null || pixel is! PixelUint32 || pixel.data != this) {
      pixel = PixelUint32.imageData(this);
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

  String toString() => 'ImageDataUint32($width, $height, $numChannels)';

  void clear([Color? c]) { }
}
