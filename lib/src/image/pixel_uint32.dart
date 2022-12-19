import 'dart:typed_data';

import '../color/channel_iterator.dart';
import '../color/color.dart';
import '../color/color_util.dart';
import '../color/format.dart';
import 'image.dart';
import 'image_data_uint32.dart';
import 'palette.dart';
import 'pixel.dart';

class PixelUint32 extends Iterable<num> implements Pixel {
  int x;
  int y;
  int _index;
  final ImageDataUint32 image;

  PixelUint32.imageData(this.image)
      : x = -1
      , y = 0
      , _index = -image.numChannels;

  PixelUint32.image(Image image)
      : x = -1
      , y = 0
      , _index = -image.numChannels
      , image = image.data is ImageDataUint32 ? image.data as ImageDataUint32
          : ImageDataUint32(0, 0, 0);

  PixelUint32.from(PixelUint32 other)
      : x = other.x
      , y = other.y
      , _index = other._index
      , image = other.image;

  PixelUint32 clone() => PixelUint32.from(this);

  int get length => image.numChannels;
  int get numChannels => image.numChannels;
  bool get hasPalette => image.hasPalette;
  Palette? get palette => null;
  int get width => image.width;
  int get height => image.height;
  Uint32List get data => image.data;
  num get maxChannelValue => image.maxChannelValue;
  Format get format => Format.uint32;
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
      data[_index + i] = value.toInt();
    }
  }

  num get index => r;
  void set index(num i) => r = i;

  num get r => numChannels > 0 ? data[_index] : 0;

  void set r(num r) { if (numChannels > 0) { data[_index] = r.toInt(); } }

  num get g => numChannels > 1 ? data[_index + 1]  : 0;

  void set g(num g) { if (image.numChannels > 1) data[_index + 1] = g.toInt(); }

  num get b => numChannels > 2 ? data[_index + 2]  : 0;

  void set b(num b) { if (image.numChannels > 2) data[_index + 2] = b.toInt(); }

  num get a => numChannels > 3 ? data[_index + 3]  : 0;

  void set a(num a) { if (image.numChannels > 3) data[_index + 3] = a.toInt(); }

  void set(Color c) {
    r = c.r;
    g = c.g;
    b = c.b;
    a = c.a;
  }

  void setColor(num r, [num g = 0, num b = 0, num a = 0]) {
    final nc = image.numChannels;
    if (nc > 0) {
      data[_index] = r.toInt();
      if (nc > 1) {
        data[_index + 1] = g.toInt();
        if (nc > 2) {
          data[_index + 2] = b.toInt();
          if (nc > 3) {
            data[_index + 3] = a.toInt();
          }
        }
      }
    }
  }

  ChannelIterator get iterator => ChannelIterator(this);

  bool operator==(Object? other) {
    if (other is PixelUint32) {
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