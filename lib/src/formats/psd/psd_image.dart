import 'dart:math';
import 'dart:typed_data';

import '../decode_info.dart';
import '../../color.dart';
import '../../image.dart';
import '../../image_exception.dart';
import '../../util/input_buffer.dart';
import 'psd_channel.dart';
import 'psd_image_resource.dart';
import 'psd_layer.dart';

class PsdImage extends DecodeInfo {
  static const int SIGNATURE = 0x38425053; // '8BPS'

  static const int COLORMODE_BITMAP = 0;
  static const int COLORMODE_GRAYSCALE = 1;
  static const int COLORMODE_INDEXED = 2;
  static const int COLORMODE_RGB = 3;
  static const int COLORMODE_CMYK = 4;
  static const int COLORMODE_MULTICHANNEL = 7;
  static const int COLORMODE_DUOTONE = 8;
  static const int COLORMODE_LAB = 9;

  int signature;
  int version;
  int channels;
  int depth;
  int colorMode;
  List<PsdLayer> layers;
  List<PsdChannel> mergeImageChannels;
  Image mergedImage;
  Map<int, PsdImageResource> imageResources = {};
  bool hasAlpha = false;

  PsdImage(List<int> bytes) {
    _input = InputBuffer(bytes, bigEndian: true);

    _readHeader();
    if (!isValid) {
      return;
    }

    int len = _input.readUint32();
    /*_colorData =*/ _input.readBytes(len);

    len = _input.readUint32();
    _imageResourceData = _input.readBytes(len);

    len = _input.readUint32();
    _layerAndMaskData = _input.readBytes(len);

    _imageData = _input.readBytes(_input.length);
  }

  bool get isValid => signature == SIGNATURE;

  /// The number of frames that can be decoded.
  int get numFrames => 1;

  /**
   * Decode the raw psd structure without rendering the output image.
   * Use [renderImage] to render the output image.
   */
  bool decode() {
    if (!isValid || _input == null) {
      return false;
    }

    // Color Mode Data Block:
    // Indexed and duotone images have palette data in colorData...
    _readColorModeData();

    // Image Resource Block:
    // Image resources are used to store non-pixel data associated with images,
    // such as pen tool paths.
    _readImageResources();

    _readLayerAndMaskData();

    _readMergeImageData();

    _input = null;
    //_colorData = null;
    _imageResourceData = null;
    _layerAndMaskData = null;
    _imageData = null;

    return true;
  }

  Image decodeImage() {
    if (!decode()) {
      return null;
    }

    return renderImage();
  }

  Image renderImage() {
    if (mergedImage != null) {
      return mergedImage;
    }

    mergedImage = Image(width, height);
    mergedImage.fill(0);

    Uint8List pixels = mergedImage.getBytes();

    for (int li = 0; li < layers.length; ++li) {
      PsdLayer layer = layers[li];
      if (!layer.isVisible()) {
        continue;
      }

      double opacity = layer.opacity / 255.0;
      int blendMode = layer.blendMode;

      //int ns = depth == 16 ? 2 : 1;
      Uint8List srcP = layer.layerImage.getBytes();

      for (int y = 0, sy = layer.top, si = 0; y < layer.height; ++y, ++sy) {
        int di = (layer.top + y) * width * 4 + layer.left * 4;
        for (int x = 0, sx = layer.left; x < layer.width; ++x, ++sx) {
          int br = srcP[si++];
          int bg = srcP[si++];
          int bb = srcP[si++];
          int ba = srcP[si++];

          if (sx >= 0 && sx < width && sy >= 0 && sy < height) {
            int ar = pixels[di];
            int ag = pixels[di + 1];
            int ab = pixels[di + 2];
            int aa = pixels[di + 3];

            _blend(
                ar, ag, ab, aa, br, bg, bb, ba, blendMode, opacity, pixels, di);
          }

          di += 4;
        }
      }
    }

    return mergedImage;
  }

  void _blend(int ar, int ag, int ab, int aa, int br, int bg, int bb, int ba,
      int blendMode, double opacity, Uint8List pixels, int di) {
    int r = br;
    int g = bg;
    int b = bb;
    int a = ba;
    double da = (ba / 255.0) * opacity;

    switch (blendMode) {
      case PsdLayer.BLEND_PASSTHROUGH:
        r = ar;
        g = ag;
        b = ab;
        a = aa;
        break;
      case PsdLayer.BLEND_NORMAL:
        break;
      case PsdLayer.BLEND_DISSOLVE:
        break;
      case PsdLayer.BLEND_DARKEN:
        r = _blendDarken(ar, br);
        g = _blendDarken(ag, bg);
        b = _blendDarken(ab, bb);
        break;
      case PsdLayer.BLEND_MULTIPLY:
        r = _blendMultiply(ar, br);
        g = _blendMultiply(ag, bg);
        b = _blendMultiply(ab, bb);
        break;
      case PsdLayer.BLEND_COLOR_BURN:
        r = _blendColorBurn(ar, br);
        g = _blendColorBurn(ag, bg);
        b = _blendColorBurn(ab, bb);
        break;
      case PsdLayer.BLEND_LINEAR_BURN:
        r = _blendLinearBurn(ar, br);
        g = _blendLinearBurn(ag, bg);
        b = _blendLinearBurn(ab, bb);
        break;
      case PsdLayer.BLEND_DARKEN_COLOR:
        break;
      case PsdLayer.BLEND_LIGHTEN:
        r = _blendLighten(ar, br);
        g = _blendLighten(ag, bg);
        b = _blendLighten(ab, bb);
        break;
      case PsdLayer.BLEND_SCREEN:
        r = _blendScreen(ar, br);
        g = _blendScreen(ag, bg);
        b = _blendScreen(ab, bb);
        break;
      case PsdLayer.BLEND_COLOR_DODGE:
        r = _blendColorDodge(ar, br);
        g = _blendColorDodge(ag, bg);
        b = _blendColorDodge(ab, bb);
        break;
      case PsdLayer.BLEND_LINEAR_DODGE:
        r = _blendLinearDodge(ar, br);
        g = _blendLinearDodge(ag, bg);
        b = _blendLinearDodge(ab, bb);
        break;
      case PsdLayer.BLEND_LIGHTER_COLOR:
        break;
      case PsdLayer.BLEND_OVERLAY:
        r = _blendOverlay(ar, br, aa, ba);
        g = _blendOverlay(ag, bg, aa, ba);
        b = _blendOverlay(ab, bb, aa, ba);
        break;
      case PsdLayer.BLEND_SOFT_LIGHT:
        r = _blendSoftLight(ar, br);
        g = _blendSoftLight(ag, bg);
        b = _blendSoftLight(ab, bb);
        break;
      case PsdLayer.BLEND_HARD_LIGHT:
        r = _blendHardLight(ar, br);
        g = _blendHardLight(ag, bg);
        b = _blendHardLight(ab, bb);
        break;
      case PsdLayer.BLEND_VIVID_LIGHT:
        r = _blendVividLight(ar, br);
        g = _blendVividLight(ag, bg);
        b = _blendVividLight(ab, bb);
        break;
      case PsdLayer.BLEND_LINEAR_LIGHT:
        r = _blendLinearLight(ar, br);
        g = _blendLinearLight(ag, bg);
        b = _blendLinearLight(ab, bb);
        break;
      case PsdLayer.BLEND_PIN_LIGHT:
        r = _blendPinLight(ar, br);
        g = _blendPinLight(ag, bg);
        b = _blendPinLight(ab, bb);
        break;
      case PsdLayer.BLEND_HARD_MIX:
        r = _blendHardMix(ar, br);
        g = _blendHardMix(ag, bg);
        b = _blendHardMix(ab, bb);
        break;
      case PsdLayer.BLEND_DIFFERENCE:
        r = _blendDifference(ar, br);
        g = _blendDifference(ag, bg);
        b = _blendDifference(ab, bb);
        break;
      case PsdLayer.BLEND_EXCLUSION:
        r = _blendExclusion(ar, br);
        g = _blendExclusion(ag, bg);
        b = _blendExclusion(ab, bb);
        break;
      case PsdLayer.BLEND_SUBTRACT:
        break;
      case PsdLayer.BLEND_DIVIDE:
        break;
      case PsdLayer.BLEND_HUE:
        break;
      case PsdLayer.BLEND_SATURATION:
        break;
      case PsdLayer.BLEND_COLOR:
        break;
      case PsdLayer.BLEND_LUMINOSITY:
        break;
    }

    r = ((ar * (1.0 - da)) + (r * da)).toInt();
    g = ((ag * (1.0 - da)) + (g * da)).toInt();
    b = ((ab * (1.0 - da)) + (b * da)).toInt();
    a = ((aa * (1.0 - da)) + (a * da)).toInt();

    pixels[di++] = r;
    pixels[di++] = g;
    pixels[di++] = b;
    pixels[di++] = a;
  }

  static int _blendLighten(int a, int b) {
    return max(a, b);
  }

  static int _blendDarken(int a, int b) {
    return min(a, b);
  }

  static int _blendMultiply(int a, int b) {
    return (a * b) >> 8;
  }

  static int _blendOverlay(int a, int b, int aAlpha, int bAlpha) {
    double x = a / 255.0;
    double y = b / 255.0;
    double aa = aAlpha / 255.0;
    double ba = bAlpha / 255.0;

    double z;
    if (2.0 * x < aa) {
      z = 2.0 * y * x + y * (1.0 - aa) + x * (1.0 - ba);
    } else {
      z = ba * aa - 2.0 * (aa - x) * (ba - y) + y * (1.0 - aa) + x * (1.0 - ba);
    }

    return (z * 255.0).toInt().clamp(0, 255);
  }

  static int _blendColorBurn(int a, int b) {
    if (b == 0) {
      return 0; // We don't want to divide by zero
    }
    int c = (255.0 * (1.0 - (1.0 - (a / 255.0)) / (b / 255.0))).toInt();
    return c.clamp(0, 255);
  }

  static int _blendLinearBurn(int a, int b) {
    return (a + b - 255).clamp(0, 255);
  }

  static int _blendScreen(int a, int b) {
    return (255 - ((255 - b) * (255 - a))).clamp(0, 255);
  }

  static int _blendColorDodge(int a, int b) {
    if (b == 255) {
      return 255;
    }
    return (((a / 255) / (1.0 - (b / 255.0))) * 255.0).toInt().clamp(0, 255);
  }

  static int _blendLinearDodge(int a, int b) {
    return (b + a > 255) ? 0xff : a + b;
  }

  static int _blendSoftLight(int a, int b) {
    double aa = a / 255.0;
    double bb = b / 255.0;
    return (255.0 *
            ((1.0 - bb) * bb * aa + bb * (1.0 - (1.0 - bb) * (1.0 - aa))))
        .round();
  }

  static int _blendHardLight(int bottom, int top) {
    double a = top / 255.0;
    double b = bottom / 255.0;
    if (b < 0.5) {
      return (255.0 * 2.0 * a * b).round();
    } else {
      return (255.0 * (1.0 - 2.0 * (1.0 - a) * (1.0 - b))).round();
    }
  }

  static int _blendVividLight(int bottom, int top) {
    if (top < 128) {
      return _blendColorBurn(bottom, 2 * top);
    } else {
      return _blendColorDodge(bottom, 2 * (top - 128));
    }
  }

  static int _blendLinearLight(int bottom, int top) {
    if (top < 128) {
      return _blendLinearBurn(bottom, 2 * top);
    } else {
      return _blendLinearDodge(bottom, 2 * (top - 128));
    }
  }

  static int _blendPinLight(int bottom, int top) {
    return (top < 128)
        ? _blendDarken(bottom, 2 * top)
        : _blendLighten(bottom, 2 * (top - 128));
  }

  static int _blendHardMix(int bottom, int top) {
    return (top < 255 - bottom) ? 0 : 255;
  }

  static int _blendDifference(int bottom, int top) {
    return (top - bottom).abs();
  }

  static int _blendExclusion(int bottom, int top) {
    return (top + bottom - 2 * top * bottom / 255.0).round();
  }

  void _readHeader() {
    signature = _input.readUint32();
    version = _input.readUint16();

    // version should be 1 (2 for PSB files).
    if (version != 1) {
      signature = 0;
      return;
    }

    // padding should be all 0's
    InputBuffer padding = _input.readBytes(6);
    for (int i = 0; i < 6; ++i) {
      if (padding[i] != 0) {
        signature = 0;
        return;
      }
    }

    channels = _input.readUint16();
    height = _input.readUint32();
    width = _input.readUint32();
    depth = _input.readUint16();
    colorMode = _input.readUint16();
  }

  void _readColorModeData() {
    // TODO support indexed and duotone images.
  }

  void _readImageResources() {
    _imageResourceData.rewind();
    while (!_imageResourceData.isEOS) {
      int blockSignature = _imageResourceData.readUint32();
      int blockId = _imageResourceData.readUint16();

      int len = _imageResourceData.readByte();
      String blockName = _imageResourceData.readString(len);
      // name string is padded to an even size
      if (len & 1 == 0) {
        _imageResourceData.skip(1);
      }

      len = _imageResourceData.readUint32();
      InputBuffer blockData = _imageResourceData.readBytes(len);
      // blocks are padded to an even length.
      if (len & 1 == 1) {
        _imageResourceData.skip(1);
      }

      if (blockSignature == RESOURCE_BLOCK_SIGNATURE) {
        imageResources[blockId] =
            PsdImageResource(blockId, blockName, blockData);
      }
    }
  }

  void _readLayerAndMaskData() {
    _layerAndMaskData.rewind();
    int len = _layerAndMaskData.readUint32();
    if ((len & 1) != 0) {
      len++;
    }

    InputBuffer layerData = _layerAndMaskData.readBytes(len);

    layers = [];
    if (len > 0) {
      int count = layerData.readInt16();
      // If it is a negative number, its absolute value is the number of
      // layers and the first alpha channel contains the transparency data for
      // the merged result.
      if (count < 0) {
        hasAlpha = true;
        count = -count;
      }

      for (int i = 0; i < count; ++i) {
        PsdLayer layer = PsdLayer(layerData);
        layers.add(layer);
      }
    }

    for (int i = 0; i < layers.length; ++i) {
      layers[i].readImageData(layerData, this);
    }

    // Global layer mask info
    len = _layerAndMaskData.readUint32();
    InputBuffer maskData = _layerAndMaskData.readBytes(len);
    if (len > 0) {
      /*int colorSpace =*/ maskData.readUint16();
      /*int rc =*/ maskData.readUint16();
      /*int gc =*/ maskData.readUint16();
      /*int bc =*/ maskData.readUint16();
      /*int ac =*/ maskData.readUint16();
      /*int opacity =*/ maskData.readUint16(); // 0-100
      /*int kind =*/ maskData.readByte();
    }
  }

  void _readMergeImageData() {
    _imageData.rewind();
    int compression = _imageData.readUint16();

    Uint16List lineLengths;
    if (compression == PsdChannel.COMPRESS_RLE) {
      int numLines = height * this.channels;
      lineLengths = Uint16List(numLines);
      for (int i = 0; i < numLines; ++i) {
        lineLengths[i] = _imageData.readUint16();
      }
    }

    mergeImageChannels = [];
    for (int i = 0; i < channels; ++i) {
      mergeImageChannels.add(new PsdChannel.read(_imageData, i == 3 ? -1 : i,
          width, height, depth, compression, lineLengths, i));
    }

    mergedImage = createImageFromChannels(
        colorMode, depth, width, height, mergeImageChannels);
  }

  static int _ch(List<int> data, int si, int ns) {
    return ns == 1 ? data[si] : ((data[si] << 8) | data[si + 1]) >> 8;
  }

  static Image createImageFromChannels(int colorMode, int bitDepth, int width,
      int height, List<PsdChannel> channelList) {
    Image output = Image(width, height);
    Uint8List pixels = output.getBytes();

    Map<int, PsdChannel> channels = {};
    for (PsdChannel ch in channelList) {
      channels[ch.id] = ch;
    }

    int numChannels = channelList.length;
    int ns = (bitDepth == 8) ? 1 : (bitDepth == 16) ? 2 : -1;
    if (ns == -1) {
      throw new ImageException('PSD: unsupported bit depth: $bitDepth');
    }

    final channel0 = channels[0];
    final channel1 = channels[1];
    final channel2 = channels[2];
    final channel_1 = channels[-1];

    for (int y = 0, di = 0, si = 0; y < height; ++y) {
      for (int x = 0; x < width; ++x, si += ns) {
        switch (colorMode) {
          case COLORMODE_RGB:
            int xi = di;
            pixels[di++] = _ch(channel2.data, si, ns);
            pixels[di++] = _ch(channel1.data, si, ns);
            pixels[di++] = _ch(channel0.data, si, ns);
            pixels[di++] = numChannels >= 4 ? _ch(channel_1.data, si, ns) : 255;

            var b = pixels[xi];
            var g = pixels[xi + 1];
            var r = pixels[xi + 2];
            var a = pixels[xi + 3];
            if (a != 0) {
              // Photoshop/Gimp blend the image against white (argh!),
              // which is not what we want for compositing. Invert the blend
              // operation to try and undo the damage.
              pixels[xi] = (((b + a) - 255) * 255) ~/ a;
              pixels[xi + 1] = (((g + a) - 255) * 255) ~/ a;
              pixels[xi + 2] = (((r + a) - 255) * 255) ~/ a;
            }
            break;
          case COLORMODE_LAB:
            int L = _ch(channel0.data, si, ns) * 100 >> 8;
            int a = _ch(channel1.data, si, ns) - 128;
            int b = _ch(channel2.data, si, ns) - 128;
            int alpha = numChannels >= 4 ? _ch(channel_1.data, si, ns) : 255;
            List<int> rgb = labToRGB(L, a, b);
            pixels[di++] = rgb[2];
            pixels[di++] = rgb[1];
            pixels[di++] = rgb[0];
            pixels[di++] = alpha;
            break;
          case COLORMODE_GRAYSCALE:
            int gray = _ch(channel0.data, si, ns);
            int alpha = numChannels >= 2 ? _ch(channel_1.data, si, ns) : 255;
            pixels[di++] = gray;
            pixels[di++] = gray;
            pixels[di++] = gray;
            pixels[di++] = alpha;
            break;
          case COLORMODE_CMYK:
            int c = _ch(channel0.data, si, ns);
            int m = _ch(channel1.data, si, ns);
            int y = _ch(channel2.data, si, ns);
            int k = _ch(channels[numChannels == 4 ? -1 : 3].data, si, ns);
            int alpha = numChannels >= 5 ? _ch(channel_1.data, si, ns) : 255;
            List<int> rgb = cmykToRGB(255 - c, 255 - m, 255 - y, 255 - k);
            pixels[di++] = rgb[2];
            pixels[di++] = rgb[1];
            pixels[di++] = rgb[0];
            pixels[di++] = alpha;
            break;
          default:
            throw new ImageException('Unhandled color mode: $colorMode');
        }
      }
    }

    return output;
  }

  static const int RESOURCE_BLOCK_SIGNATURE = 0x3842494d; // '8BIM'

  InputBuffer _input;
  //InputBuffer _colorData;
  InputBuffer _imageResourceData;
  InputBuffer _layerAndMaskData;
  InputBuffer _imageData;
}
