part of image;

class PsdLayer {
  int top;
  int left;
  int bottom;
  int right;
  int width;
  int height;
  int blendMode;
  int opacity;
  int clipping;
  int flags;
  int compression;
  String name;
  List<PsdChannel> channels;
  PsdMask mask;
  PsdBlendingRanges blendingRanges;
  Map<String, PsdLayerData> additionalData = {};
  List<PsdLayer> children = [];
  PsdLayer parent;

  static const int SIGNATURE = 0x3842494d; // '8BIM'

  static const int BLEND_PASSTHROUGH = 0x70617373; // 'pass'
  static const int BLEND_NORMAL = 0x6e6f726d; // 'norm'
  static const int BLEND_DISSOLVE = 0x64697373; // 'diss'
  static const int BLEND_DARKEN = 0x6461726b; // 'dark'
  static const int BLEND_MULTIPLY = 0x6d756c20; // 'mul '
  static const int BLEND_COLOR_BURN = 0x69646976; // 'idiv'
  static const int BLEND_LINEAR_BURN = 0x6c62726e; // 'lbrn'
  static const int BLEND_DARKEN_COLOR = 0x646b436c; // 'dkCl'
  static const int BLEND_LIGHTEN = 0x6c697465; // 'lite'
  static const int BLEND_SCREEN = 0x7363726e; // 'scrn'
  static const int BLEND_COLOR_DODGE = 0x64697620; // 'div '
  static const int BLEND_LINEAR_DODGE = 0x6c646467; // 'lddg'
  static const int BLEND_LIGHTER_COLOR = 0x6c67436c; // 'lgCl'
  static const int BLEND_OVERLAY = 0x6f766572; // 'over'
  static const int BLEND_SOFT_LIGHT = 0x734c6974; // 'sLit'
  static const int BLEND_HARD_LIGHT = 0x684c6974; // 'hLit'
  static const int BLEND_VIVID_LIGHT = 0x764c6974; // 'vLit'
  static const int BLEND_LINEAR_LIGHT = 0x6c4c6974; // lLit'
  static const int BLEND_PIN_LIGHT = 0x704c6974; // 'pLit'
  static const int BLEND_HARD_MIX = 0x684d6978; // 'hMix'
  static const int BLEND_DIFFERENCE = 0x64696666; // 'diff'
  static const int BLEND_EXCLUSION = 0x736d7564; // 'smud'
  static const int BLEND_SUBTRACT = 0x66737562; // 'fsub'
  static const int BLEND_DIVIDE = 0x66646976; // 'fdiv'
  static const int BLEND_HUE = 0x68756520; // 'hue '
  static const int BLEND_SATURATION = 0x73617420; // 'sat '
  static const int BLEND_COLOR = 0x636f6c72; // 'colr'
  static const int BLEND_LUMINOSITY = 0x6c756d20; // 'lum '

  static const int FLAG_TRANSPARENCY_PROTECTED = 1;
  static const int FLAG_VISIBLE = 2;
  static const int FLAG_OBSOLETE = 4;
  static const int FLAG_PHOTOSHOP_5 = 8;
  static const int FLAG_PIXEL_DATA_IRRELEVANT_TO_APPEARANCE = 16;


  PsdLayer([InputBuffer input]) {
    if (input == null) {
      return;
    }

    top = input.readUint32();
    left = input.readUint32();
    bottom = input.readUint32();
    right = input.readUint32();
    width = right - left;
    height = bottom - top;

    channels = [];
    int numChannels = input.readUint16();
    for (int i = 0; i < numChannels; ++i) {
      int id = input.readInt16();
      int len = input.readUint32();
      channels.add(new PsdChannel(id, len));
    }

    int sig = input.readUint32();
    if (sig != SIGNATURE) {
      throw new ImageException('Invalid PSD layer signature: '
                               '${sig.toRadixString(16)}');
    }

    blendMode = input.readUint32();
    opacity = input.readByte();
    clipping = input.readByte();
    flags = input.readByte();

    int filler = input.readByte(); // should be 0
    if (filler != 0) {
      throw new ImageException('Invalid PSD layer data');
    }

    int len = input.readUint32();
    InputBuffer extra = input.readBytes(len);

    if (len > 0) {
      len = extra.readUint32();
      if (len > 0) {
        InputBuffer maskData = extra.readBytes(len);
        mask = new PsdMask(maskData);
      }

      len = extra.readUint32();
      if (len > 0) {
        InputBuffer data = extra.readBytes(len);
        blendingRanges = new PsdBlendingRanges(data);
      }

      len = extra.readByte();
      name = extra.readString(len);
      int padding = (((len + 1 + 3) & ~0x03) - 1) - len;
      if (padding > 0) {
        extra.skip(padding);
      }

      // Additional layer sections
      while (!extra.isEOS) {
        int sig = extra.readUint32();
        if (sig != SIGNATURE) {
          throw new ImageException('PSD invalid signature for layer additional '
                                   'data: ${sig.toRadixString(16)}');
        }

        String tag = extra.readString(4);

        len = extra.readUint32();
        InputBuffer data = extra.readBytes(len);
        if (len & 1 == 1) {
          extra.skip(1);
        }

        additionalData[tag] = new PsdLayerData(tag, data);
      }
    }
  }

  /**
   * Is this layer visible?
   */
  bool isVisible() => flags & FLAG_VISIBLE != 0;

  /**
   * Is this layer a folder?
   */
  int type() {
    if (additionalData.containsKey(PsdLayerSectionDivider.TAG)) {
      PsdLayerSectionDivider section = additionalData[PsdLayerSectionDivider.TAG];
      return section.type;
    }
    return PsdLayerSectionDivider.NORMAL;
  }

  /**
   * Get the channel for the given [id].
   * Returns null if the layer does not have the given channel.
   */
  PsdChannel getChannel(int id) {
    for (int i = 0; i < channels.length; ++i) {
      if (channels[i].id == id) {
        return channels[i];
      }
    }
    return null;
  }

  Image toImage() {
    Image image = new Image(width, height);

    PsdChannel red = getChannel(PsdChannel.RED);
    PsdChannel green = getChannel(PsdChannel.GREEN);
    PsdChannel blue = getChannel(PsdChannel.BLUE);
    PsdChannel alpha = getChannel(PsdChannel.ALPHA);

    Uint8List pixels = image.getBytes();
    for (int y = 0, di = 0, si = 0; y < height; ++y) {
      for (int x = 0; x < width; ++x, di += 4) {
        pixels[di] = (red != null) ? red.data[si] : 0;
        pixels[di + 1] = (green != null) ? green.data[si] : 0;
        pixels[di + 2] = (blue != null) ? blue.data[si] : 0;
        pixels[di + 3] = (alpha != null) ? alpha.data[si] : 255;
      }
    }

    return image;
  }

  void readImageData(InputBuffer input) {
    for (int i = 0; i < channels.length; ++i) {
      PsdChannel channel = channels[i];
      switch (channel.id) {
        case PsdChannel.ALPHA:
        case PsdChannel.RED:
        case PsdChannel.GREEN:
        case PsdChannel.BLUE:
          channel.readPlane(input, width, height);
          break;
        default:
          break;
      }
    }
  }
}
