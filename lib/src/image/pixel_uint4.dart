import 'dart:typed_data';

import '../color/channel_iterator.dart';
import '../color/color.dart';
import '../color/color_util.dart';
import '../color/format.dart';
import 'image.dart';
import 'image_data_uint4.dart';
import 'palette.dart';
import 'pixel.dart';

class PixelUint4 extends Iterable<num> implements Pixel {
  int x;
  int y;
  int _index;
  int _bitIndex;
  final ImageDataUint4 image;

  PixelUint4.imageData(this.image)
      : x = -1
      , y = 0
      , _index = 0
      , _bitIndex = -(image.numChannels << 2);

  PixelUint4.image(Image image)
      : x = -1
      , y = 0
      , _index = 0
      , _bitIndex = -(image.numChannels << 2)
      , image = image.data is ImageDataUint4 ? image.data as ImageDataUint4
          : ImageDataUint4(0, 0, 0);

  PixelUint4.from(PixelUint4 other)
      : x = other.x
      , y = other.y
      , _index = other._index
      , _bitIndex = other._bitIndex
      , image = other.image;

  PixelUint4 clone() => PixelUint4.from(this);

  int get length => palette?.numChannels ?? image.numChannels;
  int get numChannels => palette?.numChannels ?? image.numChannels;
  bool get hasPalette => image.hasPalette;
  Palette? get palette => image.palette;
  int get width => image.width;
  int get height => image.height;
  Uint8List get data => image.data;
  num get maxChannelValue => image.maxChannelValue;
  Format get format => Format.uint4;
  bool get isLdrFormat => image.isLdrFormat;
  bool get isHdrFormat => image.isHdrFormat;

  void setPosition(int x, int y) {
    this.x = x;
    this.y = y;
    final bpp = image.numChannels * 4;
    final w = image.width;
    final rowStride = image.rowStride;
    _index = bpp == 4 ? y * rowStride + (x >> 1)
        : bpp == 8 ? y * w + x
        : bpp == 16 ? y * rowStride + (x << 1)
        : y * rowStride + ((x * bpp) >> 3);
    _bitIndex = bpp > 7 ? (x * bpp) & 0x4 : (x * bpp) & 0x7;
  }

  Pixel get current => this;

  bool moveNext() {
    x++;
    if (x == width) {
      // skip row stride padding bits
      x = 0;
      y++;
      _bitIndex = 0;
      _index = y * image.rowStride;
      return y < height;
    }

    final nc = image.numChannels;
    if (palette != null || nc == 1) {
      _bitIndex += 4;
      if (_bitIndex > 7) {
        _bitIndex = 0;
        _index++;
      }
    } else {
      final bpp = nc << 2;
      _bitIndex += bpp;
      while (_bitIndex > 7) {
        _bitIndex -= 8;
        _index++;
      }
    }

    return _index < image.data.length;
  }

  int _get(int ci) {
    var i = _index;
    var bi = 4 - (_bitIndex + (ci << 2));
    if (bi < 0) {
      bi += 8;
      i++;
    }
    return (image.data[i] >> bi) & 0xf;
  }

  num get(int ci) => palette == null ? numChannels > ci ? _get(ci)  : 0
      : palette!.get(_get(0), ci);

  void setChannel(int ci, num value) {
    if (ci >= image.numChannels) {
      return;
    }

    var index = _index;
    var bi = 4 - (_bitIndex + (ci << 2));
    if (bi < 0) {
      bi += 8;
      index++;
    }

    var v = data[index];

    final vi = value.toInt().clamp(0, 15);
    final mask = bi == 4 ? 0x0f : 0xf0;
    v = (v & mask) | (vi << bi);
    data[index] = v;
  }

  num operator[](int i) => get(i);

  void operator[]=(int i, num value) => setChannel(i, value);

  num get index => _get(0);
  void set index(num i) => setChannel(0, i);

  num get r => get(0);

  void set r(num r) => setChannel(0, r);

  num get g => get(1);

  void set g(num g) => setChannel(1, g);

  num get b => get(2);

  void set b(num b) => setChannel(2, b);

  num get a => get(3);

  void set a(num a) => setChannel(3, a);

  num get rNormalized => r / maxChannelValue;
  void set rNormalized(num v) => r = v * maxChannelValue;

  num get gNormalized => g / maxChannelValue;
  void set gNormalized(num v) => g = v * maxChannelValue;

  num get bNormalized => b / maxChannelValue;
  void set bNormalized(num v) => b = v * maxChannelValue;

  num get aNormalized => a / maxChannelValue;
  void set aNormalized(num v) => a = v * maxChannelValue;

  void set(Color c) {
    r = c.r;
    g = c.g;
    b = c.b;
    a = c.a;
  }

  void setColor(num r, [num g = 0, num b = 0, num a = 0]) {
    final nc = image.numChannels;
    if (nc > 0) {
      setChannel(0, r);
      if (nc > 1) {
        setChannel(1, g);
        if (nc > 2) {
          setChannel(2, b);
          if (nc > 3) {
            setChannel(3, a);
          }
        }
      }
    }
  }

  ChannelIterator get iterator => ChannelIterator(this);

  bool operator==(Object? other) {
    if (other is PixelUint4) {
      return hashCode == other.hashCode;
    }
    if (other is List<int>) {
      final nc = numChannels;
      if (other.length != nc) {
        return false;
      }
      if (get(0) != other[0]) {
        return false;
      }
      if (nc > 1) {
        if (get(1) != other[1]) {
          return false;
        }
        if (nc > 2) {
          if (get(2) != other[2]) {
            return false;
          }
          if (nc > 3) {
            if (get(3) != other[3]) {
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
