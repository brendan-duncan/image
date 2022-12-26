import 'dart:typed_data';

import '../color/channel_iterator.dart';
import '../color/color.dart';
import '../color/format.dart';
import '../util/color_util.dart';
import 'image.dart';
import 'image_data_float32.dart';
import 'palette.dart';
import 'pixel.dart';

class PixelFloat32 extends Iterable<num> implements Pixel {
  int _x;
  int _y;
  int _index;
  final ImageDataFloat32 image;

  PixelFloat32.imageData(this.image)
      : _x = -1
      , _y = -1
      , _index = -image.numChannels;

  PixelFloat32.image(Image image)
      : _x = -1
      , _y = -1
      , _index = -image.numChannels
      , image = image.data is ImageDataFloat32 ? image.data as ImageDataFloat32
          : ImageDataFloat32(0, 0, 0);

  PixelFloat32.from(PixelFloat32 other)
      : _x = other._x
      , _y = other._y
      , _index = other._index
      , image = other.image;

  PixelFloat32 clone() => PixelFloat32.from(this);

  int get length => image.numChannels;
  int get numChannels => image.numChannels;
  bool get hasPalette => image.hasPalette;
  Palette? get palette => null;
  int get width => image.width;
  int get height => image.height;
  Float32List get data => image.data;
  num get maxChannelValue => image.maxChannelValue;
  Format get format => Format.float32;
  bool get isLdrFormat => image.isLdrFormat;
  bool get isHdrFormat => image.isHdrFormat;

  bool get isValid => x >= 0 && x < (image.width - 1) &&
      y >= 0 && y < (image.height - 1);

  int get x => _x;
  int get y => _y;

  /// The normalized x coordinate of the pixel, in the range \[0, 1\].
  num get xNormalized => width > 1 ? x / (width - 1) : 0;

  /// The normalized y coordinate of the pixel, in the range \[0, 1\].
  num get yNormalized => height > 1 ? y / (height - 1) : 0;

  /// Set the normalized coordinates of the pixel, in the range \[0, 1\].
  void setPositionNormalized(num x, num y) =>
      setPosition((x * (width - 1)).floor(), (y * (height - 1)).floor());

  void setPosition(int x, int y) {
    this._x = x;
    this._y = y;
    _index = _y * image.width * image.numChannels + (_x * image.numChannels);
  }

  Pixel get current => this;

  bool moveNext() {
    _x++;
    if (_x == width) {
      _x = 0;
      _y++;
    }
    _index += numChannels;
    return _index < image.data.length;
  }

  bool nextPixel() => moveNext();

  num operator[](int i) => i < numChannels ? data[_index + i] : 0;

  void operator[]=(int i, num value) {
    if (i < numChannels) {
      data[_index + i] = value.toDouble();
    }
  }

  num get index => r;
  void set index(num i) => r = i;

  num get r => numChannels > 0 ? data[_index] : 0;

  void set r(num r) { if (numChannels > 0) data[_index] = r.toDouble(); }

  num get g => numChannels > 1 ? data[_index + 1]  : 0;

  void set g(num g) { if (numChannels > 1) data[_index + 1] = g.toDouble(); }

  num get b => numChannels > 2 ? data[_index + 2]  : 0;

  void set b(num b) { if (numChannels > 2) data[_index + 2] = b.toDouble(); }

  num get a => numChannels > 3 ? data[_index + 3]  : 1;

  void set a(num a) { if (numChannels > 3) data[_index + 3] = a.toDouble(); }

  num get rNormalized => r / maxChannelValue;
  void set rNormalized(num v) => r = v * maxChannelValue;

  num get gNormalized => g / maxChannelValue;
  void set gNormalized(num v) => g = v * maxChannelValue;

  num get bNormalized => b / maxChannelValue;
  void set bNormalized(num v) => b = v * maxChannelValue;

  num get aNormalized => a / maxChannelValue;
  void set aNormalized(num v) => a = v * maxChannelValue;

  num get luminance => getLuminance(this);
  num get luminanceNormalized => getLuminanceNormalized(this);

  void set(Color c) {
    r = c.r;
    g = c.g;
    b = c.b;
    a = c.a;
  }

  void setColor(num r, [num g = 0, num b = 0, num a = 0]) {
    data[_index] = r.toDouble();
    if (numChannels > 1) {
      data[_index + 1] = g.toDouble();
      if (numChannels > 2) {
        data[_index + 2] = b.toDouble();
        if (numChannels > 3) {
          data[_index + 3] = a.toDouble();
        }
      }
    }
  }

  ChannelIterator get iterator => ChannelIterator(this);

  bool operator==(Object? other) {
    if (other is PixelFloat32) {
      return hashCode == other.hashCode;
    }
    if (other is List<int>) {
      if (other.length != numChannels) {
        return false;
      }
      if (data[_index] != other[0]) {
        return false;
      }
      if (numChannels > 1) {
        if (data[_index + 1] != other[1]) {
          return false;
        }
        if (numChannels > 2) {
          if (data[_index + 2] != other[2]) {
            return false;
          }
          if (numChannels > 3) {
            if (data[_index + 3] != other[3]) {
              return false;
            }
          }
        }
      }
      return true;
    }
    return false;
  }

  int get hashCode => Object.hashAll(toList());

  Color convert({ Format? format, int? numChannels, num? alpha }) =>
      convertColor(this, format: format, numChannels: numChannels,
          alpha: alpha);
}
