import 'dart:typed_data';

import '../color/channel.dart';
import '../color/channel_iterator.dart';
import '../color/color.dart';
import '../color/format.dart';
import '../util/color_util.dart';
import 'image.dart';
import 'image_data_uint1.dart';
import 'palette.dart';
import 'pixel.dart';

class PixelUint1 extends Iterable<num> implements Pixel {
  int _x;
  int _y;
  int _index;
  int _bitIndex;
  int _rowOffset;
  final ImageDataUint1 image;

  PixelUint1.imageData(this.image)
      : _x = -1
      , _y = 0
      , _index = 0
      , _bitIndex = -1
      , _rowOffset = 0;

  PixelUint1.image(Image image)
      : _x = -1
      , _y = 0
      , _index = 0
      , _bitIndex = -1
      , _rowOffset = 0
      , image = image.data is ImageDataUint1 ? image.data as ImageDataUint1
          : ImageDataUint1(0, 0, 0);

  PixelUint1.from(PixelUint1 other)
      : _x = other._x
      , _y = other._y
      , _index = other._index
      , _bitIndex = other._bitIndex
      , _rowOffset = other._rowOffset
      , image = other.image;

  PixelUint1 clone() => PixelUint1.from(this);

  int get length => palette?.numChannels ?? image.numChannels;
  int get numChannels => palette?.numChannels ?? image.numChannels;
  bool get hasPalette => image.hasPalette;
  Palette? get palette => image.palette;
  int get width => image.width;
  int get height => image.height;
  Uint8List get data => image.data;
  int get imageLength => image.length;
  num get maxChannelValue => image.maxChannelValue;
  num get maxIndexValue => image.maxIndexValue;
  Format get format => Format.uint1;
  bool get isLdrFormat => image.isLdrFormat;
  bool get isHdrFormat => image.isHdrFormat;

  bool get isValid => x >= 0 && x < (image.width - 1) &&
      y >= 0 && y < (image.height - 1);

  int get x => _x;
  int get y => _y;

  /// The normalized x coordinate of the pixel, in the range \[0, 1\].
  num get xNormalized => width > 1 ? _x / (width - 1) : 0;

  /// The normalized y coordinate of the pixel, in the range \[0, 1\].
  num get yNormalized => height > 1 ? _y / (height - 1) : 0;

  /// Set the normalized coordinates of the pixel, in the range \[0, 1\].
  void setPositionNormalized(num x, num y) =>
      setPosition((x * (width - 1)).floor(), (y * (height - 1)).floor());

  void setPosition(int x, int y) {
    this._x = x;
    this._y = y;
    final bpp = image.numChannels;
    _rowOffset = _y * image.rowStride;
    _index = _rowOffset + ((_x * bpp) >> 3);
    _bitIndex = (_x * bpp) & 0x7;
  }

  Pixel get current => this;

  bool moveNext() {
    _x++;
    if (_x == width) {
      _x = 0;
      _y++;
      _bitIndex = 0;
      _index++;
      _rowOffset += image.rowStride;
      return _y < height;
    }

    final nc = numChannels;
    if (palette != null || nc == 1) {
      _bitIndex++;
      if (_bitIndex > 7) {
        _bitIndex = 0;
        _index++;
      }
    } else {
      final bpp = image.numChannels;
      _bitIndex = (_x * bpp) & 0x7;
      _index = _rowOffset + ((_x * bpp) >> 3);
    }

    return _index < imageLength;
  }

  int _get(int ci) {
    var i = _index;
    var bi = 7 - (_bitIndex + ci);
    if (bi < 0) {
      bi += 8;
      i++;
    }
    if (i >= image.data.length)
      return 0;
    return (image.data[i] >> bi) & 0x1;
  }

  num _getChannel(int ci) => palette == null ? numChannels > ci ? _get(ci)  : 0
      : palette!.get(_get(0), ci);

  void _setChannel(int ci, num value) {
    if (ci >= image.numChannels) {
      return;
    }

    var i = _index;
    var bi = 7 - (_bitIndex + ci);
    if (bi < 0) {
      i++;
      bi += 8;
    }

    var v = data[i];
    final vi = value.toInt().clamp(0, 1);
    const _mask = [ 0xfe, 0xfd, 0xfb, 0xf7, 0xef, 0xdf, 0xbf, 0x7f ];
    final mask = _mask[bi];
    v = (v & mask) | (vi << bi);
    data[i] = v;
  }

  num operator[](int ci) => _getChannel(ci);

  void operator[]=(int ci, num value) => _setChannel(ci, value);

  num get index => _get(0);
  void set index(num i) => _setChannel(0, i);

  num get r => _getChannel(0);

  void set r(num r) => _setChannel(0, r);

  num get g => _getChannel(1);

  void set g(num g) => _setChannel(1, g);

  num get b => _getChannel(2);

  void set b(num b) => _setChannel(2, b);

  num get a => _getChannel(3);

  void set a(num a) => _setChannel(3, a);

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

  num getChannel(Channel channel) => channel == Channel.luminance ?
      luminance : channel.index < numChannels ? _getChannel(channel.index)
      : 0;

  num getChannelNormalized(Channel channel) =>
      getChannel(channel) / maxChannelValue;

  void set(Color c) {
    r = c.r;
    g = c.g;
    b = c.b;
    a = c.a;
  }

  void setColor(num r, [num g = 0, num b = 0, num a = 0]) {
    final nc = image.numChannels;
    if (nc > 0) {
      _setChannel(0, r);
      if (nc > 1) {
        _setChannel(1, g);
        if (nc > 2) {
          _setChannel(2, b);
          if (nc > 3) {
            _setChannel(3, a);
          }
        }
      }
    }
  }

  ChannelIterator get iterator => ChannelIterator(this);

  bool operator==(Object? other) {
    if (other is PixelUint1) {
      return hashCode == other.hashCode;
    }
    if (other is List<int>) {
      final nc = palette != null ? palette!.numChannels : numChannels;
      if (other.length != nc) {
        return false;
      }
      if (_getChannel(0) != other[0]) {
        return false;
      }
      if (nc > 1) {
        if (_getChannel(1) != other[1]) {
          return false;
        }
        if (nc > 2) {
          if (_getChannel(2) != other[2]) {
            return false;
          }
          if (nc > 3) {
            if (_getChannel(3) != other[3]) {
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
