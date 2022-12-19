import 'dart:typed_data';

import '../color/channel_iterator.dart';
import '../color/color.dart';
import '../color/color_util.dart';
import '../color/format.dart';
import 'image.dart';
import 'image_data_float64.dart';
import 'palette.dart';
import 'pixel.dart';

class PixelFloat64 extends Iterable<num> implements Pixel {
  int x;
  int y;
  int _index;
  final ImageDataFloat64 image;

  PixelFloat64.imageData(this.image)
      : x = -1
      , y = -1
      , _index = -image.numChannels;

  PixelFloat64.image(Image image)
      : x = -1
      , y = -1
      , _index = -image.numChannels
      , image = image.data is ImageDataFloat64 ? image.data as ImageDataFloat64
          : ImageDataFloat64(0, 0, 0);

  PixelFloat64.from(PixelFloat64 other)
      : x = other.x
      , y = other.y
      , _index = other._index
      , image = other.image;

  PixelFloat64 clone() => PixelFloat64.from(this);

  int get length => image.numChannels;
  int get numChannels => image.numChannels;
  bool get hasPalette => image.hasPalette;
  Palette? get palette => null;
  int get width => image.width;
  int get height => image.height;
  Float64List get data => image.data;
  num get maxChannelValue => image.maxChannelValue;
  Format get format => Format.float64;
  bool get isLdrFormat => image.isLdrFormat;
  bool get isHdrFormat => image.isHdrFormat;

  void setPosition(int x, int y) {
    this.x = x;
    this.y = y;
    _index = y * image.width * image.numChannels + (x * image.numChannels);
  }

  Pixel get current => this;

  bool moveNext() {
    x++;
    if (x == width) {
      x = 0;
      y++;
    }
    _index += numChannels;
    return _index < image.data.length;
  }

  num operator[](int i) => i < numChannels ? data[_index + i] : 0;

  void operator[]=(int i, num value) {
    if (i < numChannels) {
      data[_index + i] = value.toDouble();
    }
  }

  num get index => r;
  void set index(num i) => r = i;

  num get r => numChannels > 0 ? data[_index] : 0;

  void set r(num r) { if (numChannels > 0) { data[_index] = r.toDouble(); } }

  num get g => numChannels > 1 ? data[_index + 1]  : 0;

  void set g(num g) { if (numChannels > 1) data[_index + 1] = g.toDouble(); }

  num get b => numChannels > 2 ? data[_index + 2]  : 0;

  void set b(num b) { if (numChannels > 2) data[_index + 2] = b.toDouble(); }

  num get a => numChannels > 3 ? data[_index + 3]  : 0;

  void set a(num a) { if (numChannels > 3) data[_index + 3] = a.toDouble(); }

  void set(Color c) {
    r = c.r;
    g = c.g;
    b = c.b;
    a = c.a;
  }

  void setColor(num r, [num g = 0, num b = 0, num a = 0]) {
    if (numChannels > 0) {
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
  }

  ChannelIterator get iterator => ChannelIterator(this);

  bool operator==(Object? other) {
    if (other is PixelFloat64) {
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