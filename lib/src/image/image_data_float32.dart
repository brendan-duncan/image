import 'dart:typed_data';

import '../color/color.dart';
import '../color/color_float32.dart';
import '../color/format.dart';
import 'image_data.dart';
import 'pixel.dart';
import 'pixel_float32.dart';
import 'pixel_range_iterator.dart';

class ImageDataFloat32 extends ImageData {
  final Float32List data;

  ImageDataFloat32(int width, int height, int numChannels)
      : data = Float32List(width * height * numChannels)
      , super(width, height, numChannels);

  ImageDataFloat32.from(ImageDataFloat32 other, { bool skipPixels = false })
      : data = skipPixels ? Float32List(other.data.length)
          : Float32List.fromList(other.data)
      , super(other.width, other.height, other.numChannels);

  ImageDataFloat32 clone({ bool noPixels = false }) =>
      ImageDataFloat32.from(this, skipPixels: noPixels);

  Format get format => Format.float32;

  FormatType get formatType => FormatType.float;

  ByteBuffer get buffer => data.buffer;

  int get bitsPerChannel => 32;

  PixelFloat32 get iterator => PixelFloat32.imageData(this);

  Iterator<Pixel> getRange(int x, int y, int width, int height) =>
      PixelRangeIterator(PixelFloat32.imageData(this), x, y, width, height);

  int get lengthInBytes => data.lengthInBytes;

  int get length => data.lengthInBytes;

  num get maxChannelValue => 1.0;

  int get rowStride => width * numChannels * 4;

  bool get isHdrFormat => true;

  Color getColor(num r, num g, num b, [num? a]) =>
      a == null ? ColorFloat32.rgb(r, g, b) : ColorFloat32.rgba(r, g, b, a);

  Pixel getPixel(int x, int y, [Pixel? pixel]) {
    if (pixel == null || pixel is! PixelFloat32 || pixel.data != this) {
      pixel = PixelFloat32.imageData(this);
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

  String toString() => 'ImageDataFloat32($width, $height, $numChannels)';

  void clear([Color? c]) { }
}
