import '../color/channel_iterator.dart';
import '../color/color.dart';
import '../color/format.dart';
import 'image_data.dart';
import 'image_data_uint8.dart';
import 'pixel.dart';

/// Represents an invalid pixel.
class PixelUndefined extends Iterable<num> implements Pixel {
  static final nullImageData = ImageDataUint8(0,0,0);
  PixelUndefined clone() => PixelUndefined();
  ImageData get image => nullImageData;
  int get x => 0;
  void set x(int value) {}
  int get y => 0;
  void set y(int value) {}
  int get width => 0;
  int get height => 0;
  int get length => 0;
  num get maxChannelValue => 255;
  Format get format => Format.uint8;
  bool get isLdrFormat => false;
  bool get isHdrFormat => false;
  num operator[](int index) => 0;
  void operator[]=(int index, num value) {}
  num get index => 0;
  void set index(num i) {}
  num get r => 0;
  void set r(num r) {}
  num get g => 0;
  void set g(num g) {}
  num get b => 0;
  void set b(num b) {}
  num get a => 0;
  void set a(num a) {}
  void set(Color c) {}
  void setColor(num r, [num g = 0, num b = 0, num a = 0]) {}
  void setPosition(int x, int y) {}
  Pixel get current => this;
  bool moveNext() => false;
  bool nextPixel() => false;
  bool operator==(Object? other) => other == null ||
      other is PixelUndefined;
  int get hashCode => 0;
  ChannelIterator get iterator => ChannelIterator(this);
  Color convert({ Format? format, int? numChannels, num? alpha }) => this;
}
