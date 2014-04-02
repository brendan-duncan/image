part of image;

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
  bool hasAlpha = false;
  bool hasMergedImage = true;
  List<PsdLayer> layers;
  List<PsdChannel> baseImage;
  Map<int, PsdImageResource> imageResources = {};

  PsdImage(List<int> bytes) {
    _input = new InputBuffer(bytes, bigEndian: true);

    _readHeader();
    if (!isValid) {
      return;
    }

    int len = _input.readUint32();
    _colorData = _input.readBytes(len);

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

    if (hasMergedImage) {
      _readImageData();
    }

    _input = null;
    _colorData = null;
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
    Image output = new Image(width, height);
    output.fill(0x00ffffff);

    Uint8List pixels = output.getBytes();

    if (baseImage != null /*&& layers.isEmpty*/) {
      for (int y = 0, di = 0, si = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x, ++si) {
          int r = baseImage[0].data[si];
          int g = baseImage[1].data[si];
          int b = baseImage[2].data[si];
          int a = hasAlpha ? baseImage[3].data[si] : 255;
          pixels[di++] = r;
          pixels[di++] = g;
          pixels[di++] = b;
          pixels[di++] = a;
        }
      }
      return output;
    }

    for (int li = 0; li < layers.length; ++li) {
      PsdLayer layer = layers[li];
      /*if (!layer.isVisible()) {
        continue;
      }*/

      PsdChannel red = layer.getChannel(PsdChannel.RED);
      PsdChannel green = layer.getChannel(PsdChannel.GREEN);
      PsdChannel blue = layer.getChannel(PsdChannel.BLUE);
      PsdChannel alpha = layer.getChannel(PsdChannel.ALPHA);

      double opacity = layer.opacity / 255.0;
      int blendMode = layer.blendMode;

      for (int y = layer.top, si = 0; y < layer.bottom; ++y) {
        int di = y * width * 4 + layer.left * 4;
        for (int x = layer.left; x < layer.right; ++x, ++si, di += 4) {
          int br = (red != null) ? red.data[si] : 0;
          int bg = (green != null) ? green.data[si] : 0;
          int bb = (blue != null) ? blue.data[si] : 0;
          int ba = (alpha != null) ? alpha.data[si] : 255;

          int ar = pixels[di];
          int ag = pixels[di + 1];
          int ab = pixels[di + 2];
          int aa = pixels[di + 3];

          _blend(ar, ag, ab, aa, br, bg, bb, ba, blendMode, opacity,
                 pixels, di);
        }
      }
    }

    return output;
  }

  void _blend(int ar, int ag, int ab, int aa,
              int br, int bg, int bb, int ba,
              int blendMode, double opacity,
              Uint8List pixels, int di) {
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
    a = aa;//Math.max(aa, bb);
    //a = ((aa * (1.0 - da)) + (a * da)).toInt();

    pixels[di++] = r;
    pixels[di++] = g;
    pixels[di++] = b;
    pixels[di++] = a;
  }

  static int _blendLighten(int a, int b) {
    return Math.max(a, b);
  }

  static int _blendDarken(int a, int b) {
    return Math.min(a,  b);
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
      z = ba * aa - 2.0 * (aa - x) * (ba - y) +
          y * (1.0 - aa) + x * (1.0 - ba);
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
    return (255.0 * ((1.0 - bb) * bb * aa +
                     bb * (1.0 - (1.0 - bb) * (1.0 - aa)))).round();
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
    if ( top < 128) {
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
    return (top < 128) ?
           _blendDarken(bottom, 2 * top) :
           _blendLighten(bottom, 2 * (top - 128));
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
        if (blockId == 0x0421) { // Version Info
          int version = blockData.readInt32();
          hasMergedImage = blockData.readByte() != 0;
          blockData.rewind();
        }
        imageResources[blockId] = new PsdImageResource(blockId, blockName,
                                                       blockData);
      }
    }
  }

  void _readLayerAndMaskData() {
    _layerAndMaskData.rewind();
    int len = _layerAndMaskData.readUint32();
    if ((len & 1) != 0) {
      len++;
    }

    layers = [];
    if (len > 0) {
      int count = _layerAndMaskData.readInt16();
      if (count < 0) {
        hasAlpha = true;
        count = -count;
      }
      for (int i = 0; i < count; ++i) {
        PsdLayer layer = new PsdLayer(_layerAndMaskData);
        layers.add(layer);
      }
    }

    for (int i = 0; i < layers.length; ++i) {
      layers[i].readImageData(_layerAndMaskData);
    }

    // Global layer mask info
    len = _layerAndMaskData.readUint32();
    if (len > 0) {
      InputBuffer globalMaskData = _layerAndMaskData.readBytes(len);

      int colorSpace = globalMaskData.readUint16();
      int rc = globalMaskData.readUint16();
      int gc = globalMaskData.readUint16();
      int bc = globalMaskData.readUint16();
      int ac = globalMaskData.readUint16();
      int opacity = globalMaskData.readUint16(); // 0-100
      int kind = globalMaskData.readByte();
    }
  }

  void _readImageData() {
    _imageData.rewind();
    const List<int> channelIds = const [PsdChannel.RED,
                                        PsdChannel.GREEN,
                                        PsdChannel.BLUE,
                                        PsdChannel.ALPHA];

    int compression = _imageData.readUint16();

    Uint16List lineLengths;
    if (compression == PsdChannel.COMPRESS_RLE) {
      int numLines = height * this.channels;
      lineLengths = new Uint16List(numLines);
      for (int i = 0; i < numLines; ++i) {
        lineLengths[i] = _imageData.readUint16();
      }
    }

    hasAlpha = true;
    baseImage = [];
    int numChannels = 3 + (hasAlpha ? 1 : 0);

    for (int i = 0; i < numChannels; ++i) {
      baseImage.add(new PsdChannel.read(_imageData, channelIds[i],
                                        width, height, compression,
                                        lineLengths, i));
    }
  }

  static const int RESOURCE_BLOCK_SIGNATURE = 0x3842494d; // '8BIM'

  InputBuffer _input;
  InputBuffer _colorData;
  InputBuffer _imageResourceData;
  InputBuffer _layerAndMaskData;
  InputBuffer _imageData;
}
