part of image;

class PsdImage extends DecodeInfo {
  // SIGNATURE is '8BPS'
  static const int SIGNATURE = 0x38425053;

  static const int COLORMODE_BITMAP = 0;
  static const int COLORMODE_GRAYSCALE = 1;
  static const int COLORMODE_INDEXED = 2;
  static const int COLORMODE_RGB = 3;
  static const int COLORMODE_CMYK = 4;
  static const int COLORMODE_MULTICHANNEL = 7;
  static const int COLORMODE_DUOTONE = 8;
  static const int COLORMODE_LAB = 9;

  InputBuffer input;
  int signature;
  int version;
  int channels;
  int depth;
  int colorMode;
  InputBuffer colorData;
  InputBuffer imageResourceData;
  InputBuffer layerAndMaskData;
  InputBuffer imageData;
  List<PsdLayer> layers;
  List<PsdChannel> baseImage;

  PsdImage(List<int> bytes) {
    input = new InputBuffer(bytes, bigEndian: true);

    _readHeader();
    if (!isValid) {
      return;
    }

    int len = input.readUint32();
    colorData = input.readBytes(len);

    len = input.readUint32();
    imageResourceData = input.readBytes(len);

    len = input.readUint32();
    layerAndMaskData = input.readBytes(len);

    len = input.readUint32();
    imageData = input.readBytes(len);
  }

  bool get isValid => signature == SIGNATURE;

  /// The number of frames that can be decoded.
  int get numFrames => 1;

  /**
   * Decode the raw psd structure without rendering the output image.
   * Use [renderImage] to render the output image.
   */
  bool decode() {
    if (!isValid) {
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

    _readBaseLayer();

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

    Uint8List pixels = output.getBytes();

    for (int y = 0, di = 0, si = 0; y < height; ++y) {
      for (int x = 0; x < width; ++x, ++si) {
        int r = baseImage[0].data[si];
        int g = baseImage[1].data[si];
        int b = baseImage[2].data[si];
        int a = baseImage[3].data[si];
        pixels[di++] = r;
        pixels[di++] = g;
        pixels[di++] = b;
        pixels[di++] = a;
      }
    }

    for (int li = 0; li < layers.length; ++li) {
      PsdLayer layer = layers[li];
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
              int blendMode, double opacity, Uint8List pixels, int di) {
    int r = br;
    int g = bg;
    int b = bb;
    int a = ba;
    double da = (ba / 255.0) * opacity;

    switch (blendMode) {
      case PsdLayer.BLEND_OVERLAY:
        double ard = ar / 255.0;
        double agd = ag / 255.0;
        double abd = ab / 255.0;
        double aad = aa / 255.0;
        double brd = br / 255.0;
        double bgd = bg / 255.0;
        double bbd = bb / 255.0;
        double bad = ba / 255.0;

        double _ra;
        if (2.0 * ard < aad) {
          _ra = 2.0 * brd * ard + brd * (1.0 - aad) + ard * (1.0 - bad);
        } else {
          _ra = bad * aad - 2.0 * (aad - ard) * (bad - brd) +
                brd * (1.0 - aad) + ard * (1.0 - bad);
        }

        double _ga;
        if (2.0 * agd < aad) {
          _ga = 2.0 * bgd * agd + bgd * (1.0 - aad) + agd * (1.0 - bad);
        } else {
          _ga = bad * aad - 2.0 * (aad - agd) * (bad - bgd) +
                bgd * (1.0 - aad) + agd * (1.0 - bad);
        }

        double _ba;
        if (2.0 * abd < aad) {
          _ba = 2.0 * bbd * abd + bbd * (1.0 - aad) + abd * (1.0 - bad);
        } else {
          _ba = bad * aad - 2.0 * (aad - abd) * (bad - bbd) +
                bbd * (1.0 - aad) + abd * (1.0 - bad);
        }

        r = (_ra * 255.0).toInt();
        g = (_ga * 255.0).toInt();
        b = (_ba * 255.0).toInt();
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

  void _readHeader() {
    signature = input.readUint32();
    version = input.readUint16();

    // version should be 1 (2 for PSB files).
    if (version != 1) {
      signature = 0;
      return;
    }

    // padding should be all 0's
    InputBuffer padding = input.readBytes(6);
    for (int i = 0; i < 6; ++i) {
      if (padding[i] != 0) {
        signature = 0;
        return;
      }
    }

    channels = input.readUint16();
    height = input.readUint32();
    width = input.readUint32();
    depth = input.readUint16();
    colorMode = input.readUint16();
  }

  void _readColorModeData() {
    // TODO support indexed and duotone images.
  }

  void _readImageResources() {
    imageResourceData.rewind();
    while (!imageResourceData.isEOS) {
      int blockSignature = imageResourceData.readUint32();
      int blockId = imageResourceData.readUint16();

      int len = imageResourceData.readByte();
      String blockName = imageResourceData.readString(len);
      // name string is padded to an even size
      if (len & 1 == 0) {
        imageResourceData.skip(1);
      }

      len = imageResourceData.readUint32();
      InputBuffer blockData = imageResourceData.readBytes(len);
      // blocks are padded to an even length.
      if (len & 1 == 1) {
        imageResourceData.skip(1);
      }

      if (blockSignature == RESOURCE_BLOCK_SIGNATURE) {
        imageResources[blockId] = new PsdImageResource(blockId, blockName,
                                                       blockData);
      }
    }
  }

  void _readLayerAndMaskData() {
    layerAndMaskData.rewind();
    int len = layerAndMaskData.readUint32();
    if ((len & 1) != 0) {
      len++;
    }

    layers = [];
    if (len > 0) {
      int count = layerAndMaskData.readUint16();
      for (int i = 0; i < count; ++i) {
        PsdLayer layer = new PsdLayer(layerAndMaskData);
        layers.add(layer);
      }
    }

    for (int i = 0; i < layers.length; ++i) {
      layers[i].readImageData(layerAndMaskData);
    }
  }

  void _readBaseLayer() {
    imageData.rewind();
    const List<int> channelIds = const [PsdChannel.RED,
                                        PsdChannel.GREEN,
                                        PsdChannel.BLUE,
                                        PsdChannel.ALPHA];

    int compression = imageData.readUint16() == 1 ? 1 : 0;

    Uint16List lineLengths;
    if (compression == PsdChannel.COMPRESS_RLE) {
      int numLines = height * this.channels;
      lineLengths = new Uint16List(numLines);
      for (int i = 0; i < numLines; ++i) {
        lineLengths[i] = imageData.readUint16();
      }
    }

    baseImage = [];

    int planeNumber = 0;
    for (int i = 0; i < channelIds.length; ++i) {
      baseImage.add(new PsdChannel.base(imageData, channelIds[i], width, height,
                                        compression, lineLengths, i));
    }
  }

  static const int RESOURCE_BLOCK_SIGNATURE = 0x3842494d; // '8BIM'

  Map<int, PsdImageResource> imageResources = {};
}
