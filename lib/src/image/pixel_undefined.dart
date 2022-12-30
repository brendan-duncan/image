import '../color/channel.dart';
import '../color/channel_iterator.dart';
import '../color/color.dart';
import '../color/format.dart';
import 'image_data.dart';
import 'image_data_uint8.dart';
import 'palette.dart';
import 'pixel.dart';

/// Represents an invalid pixel.
class PixelUndefined extends Iterable<num> implements Pixel {
  static final nullImageData = ImageDataUint8(0,0,0);
  PixelUndefined clone() => PixelUndefined();
  ImageData get image => nullImageData;
  int get x => 0;
  int get y => 0;
  num get xNormalized => 0;
  num get yNormalized => 0;
  void setPositionNormalized(num x, num y) {}
  int get width => 0;
  int get height => 0;
  int get length => 0;
  num get maxChannelValue => 0;
  num get maxIndexValue => 0;
  Format get format => Format.uint8;
  bool get isLdrFormat => false;
  bool get isHdrFormat => false;
  bool get hasPalette => false;
  Palette? get palette => null;
  bool get isValid => false;
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
  num get rNormalized => 0;
  void set rNormalized(num v) {}
  num get gNormalized => 0;
  void set gNormalized(num v) {}
  num get bNormalized => 0;
  void set bNormalized(num v) {}
  num get aNormalized => 0;
  void set aNormalized(num v) {}
  num get luminance => 0;
  num get luminanceNormalized => 0;
  num getChannel(Channel channel) => 0;
  num getChannelNormalized(Channel channel) => 0;
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
