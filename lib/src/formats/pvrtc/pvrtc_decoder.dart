import 'dart:typed_data';

import '../../color.dart';
import '../../image.dart';
import '../../util/input_buffer.dart';
import 'pvrtc_color.dart';
import 'pvrtc_packet.dart';

/**
 * Ported from Jeffrey Lim's PVRTC encoder/decoder,
 * https://bitbucket.org/jthlim/pvrtccompressor
 */
class PvrtcDecoder {
  Image decodePvr(List<int> data) {
    // Use a heuristic to detect potential apple PVRTC formats
    if (_countBits(data.length) == 1) {
      // very likely to be apple PVRTC
      var image = decodeApplePVRTC(data);
      if (image != null) {
         return image;
      }
    }

    var input = InputBuffer(data, bigEndian: false);
    var magic = input.readUint32();
    if (magic == 0x03525650) {
      return decodePVR3(data);
    }

    return decodePVR2(data);
  }

  Image decodeApplePVRTC(List<int> data) {
    // additional heuristic
    const int HEADER_SIZE = 52;
    if (data.length > HEADER_SIZE) {
      InputBuffer input = InputBuffer(data, bigEndian: false);
      // Header
      int size = input.readUint32();
      if (size == HEADER_SIZE) {
        return null;
      }
      /*int height =*/ input.readUint32();
      /*int width =*/ input.readUint32();
      /*int mipcount =*/ input.readUint32();
      /*int flags =*/ input.readUint32();
      /*int texdatasize =*/ input.readUint32();
      /*int bpp =*/ input.readUint32();
      /*int rmask =*/ input.readUint32();
      /*int gmask =*/ input.readUint32();
      /*int bmask =*/ input.readUint32();
      int magic = input.readUint32();
      if (magic == 0x21525650) {
        // this looks more like a PowerVR file.
        return null;
      }
    }

    //const int PVRTC2 = 1;
    //const int PVRTC4 = 2;

    int mode = 1;
    int res = 8;
    int size = data.length;
    //int format = 0;

    // this is a tough one, could be 2bpp 8x8, 4bpp 8x8
    if (size == 32) {
      // assume 4bpp, 8x8
      mode = 0;
      res = 8;
    } else {
      // Detect if it's 2bpp or 4bpp
      int shift = 0;
      int test2bpp = 0x40; // 16x16
      int test4bpp = 0x80; // 16x16

      while (shift < 10) {
        int s2 = shift << 1;

        if ((test2bpp << s2) & size != 0) {
          res = 16 << shift;
          mode = 1;
          //format = PVRTC2;
          break;
        }

        if ((test4bpp << s2) & size != 0) {
          res = 16 << shift;
          mode = 0;
          //format = PVRTC4;
          break;
        }

        ++shift;
      }

      if (shift == 10) {
        // no mode could be found.
        return null;
      }
    }

    // there is no reliable way to know if it's a 2bpp or 4bpp file. Assuming
    int width = res;
    int height = res;
    int bpp = (mode + 1) * 2;
    //int numMips = 0;

    if (bpp == 4) {
      // 2bpp is currently unsupported
      return null;
    }

    return decodeRgba4bpp(width, height, data as TypedData);
  }

  Image decodePVR2(List<int> data) {
    int length = data.length;

    const int HEADER_SIZE = 52;
    const int PVRTEX_CUBEMAP = (1 << 12);
    const int PVR_PIXELTYPE_MASK  = 0xff;
    const int PVR_TYPE_RGBA4444   = 0x10;
    const int PVR_TYPE_RGBA5551   = 0x11;
    const int PVR_TYPE_RGBA8888   = 0x12;
    const int PVR_TYPE_RGB565     = 0x13;
    const int PVR_TYPE_RGB555     = 0x14;
    const int PVR_TYPE_RGB888     = 0x15;
    const int PVR_TYPE_I8         = 0x16;
    const int PVR_TYPE_AI8        = 0x17;
    const int PVR_TYPE_PVRTC2     = 0x18;
    const int PVR_TYPE_PVRTC4     = 0x19;

    if (length < HEADER_SIZE) {
      return null;
    }

    InputBuffer input = InputBuffer(data, bigEndian: false);
    // Header
    int size = input.readUint32();
    int height = input.readUint32();
    int width = input.readUint32();
    /*int mipcount =*/ input.readUint32();
    int flags = input.readUint32();
    /*int texdatasize =*/ input.readUint32();
    int bpp = input.readUint32();
    /*int rmask =*/ input.readUint32();
    /*int gmask =*/ input.readUint32();
    /*int bmask =*/ input.readUint32();
    int amask = input.readUint32();
    int magic = input.readUint32();
    int numtex = input.readUint32();

    if (size != HEADER_SIZE || magic != 0x21525650) {
      return null;
    }

    if (numtex < 1) {
      numtex = (flags & PVRTEX_CUBEMAP) != 0 ? 6 : 1;
    }

    if (numtex != 1) {
      // only 1 surface supported currently
      return null;
    }

    if (width * height * bpp / 8 > length - HEADER_SIZE) {
      return null;
    }

    int ptype = flags & PVR_PIXELTYPE_MASK;

    switch (ptype) {
      case PVR_TYPE_RGBA4444:
        Image image = Image(width, height);
        Uint8List out = image.getBytes();
        int oi = 0;
        for (int y = 0; y < height; ++y) {
          for (int x = 0; x < width; ++x) {
            int v1 = input.readByte();
            int v2 = input.readByte();
            int a = (v1 & 0x0f) << 4;
            int b = (v1 & 0xf0);
            int g = (v2 & 0x0f) << 4;
            int r = (v2 & 0xf0);

            out[oi++] = r;
            out[oi++] = g;
            out[oi++] = b;
            out[oi++] = a;
          }
        }
        return image;
      case PVR_TYPE_RGBA5551:
        Image image = Image(width, height);
        Uint8List out = image.getBytes();
        int oi = 0;
        for (int y = 0; y < height; ++y) {
          for (int x = 0; x < width; ++x) {
            int v = input.readUint16();

            int r = (v & 0xf800) >> 8;
            int g = (v & 0x07c0) >> 3;
            int b = (v & 0x003e) << 2;
            int a = (v & 0x0001) != 0 ? 255 : 0;

            out[oi++] = r;
            out[oi++] = g;
            out[oi++] = b;
            out[oi++] = a;
          }
        }
        return image;
      case PVR_TYPE_RGBA8888:
        Image image = Image(width, height);
        Uint8List out = image.getBytes();
        int oi = 0;
        for (int y = 0; y < height; ++y) {
          for (int x = 0; x < width; ++x) {
            out[oi++] = input.readByte();
            out[oi++] = input.readByte();
            out[oi++] = input.readByte();
            out[oi++] = input.readByte();
          }
        }
        return image;
      case PVR_TYPE_RGB565:
        Image image = Image(width, height);
        Uint8List out = image.getBytes();
        int oi = 0;
        for (int y = 0; y < height; ++y) {
          for (int x = 0; x < width; ++x) {
            int v = input.readUint16();
            int b = (v & 0x001f) << 3;
            int g = (v & 0x07e0) >> 3;
            int r = (v & 0xf800) >> 8;
            int a = 255;
            out[oi++] = r;
            out[oi++] = g;
            out[oi++] = b;
            out[oi++] = a;
          }
        }
        return image;
      case PVR_TYPE_RGB555:
        Image image = Image(width, height);
        Uint8List out = image.getBytes();
        int oi = 0;
        for (int y = 0; y < height; ++y) {
          for (int x = 0; x < width; ++x) {
            int v = input.readUint16();
            int r = (v & 0x001f) << 3;
            int g = (v & 0x03e0) >> 2;
            int b = (v & 0x7c00) >> 7;
            int a = 255;
            out[oi++] = r;
            out[oi++] = g;
            out[oi++] = b;
            out[oi++] = a;
          }
        }
        return image;
      case PVR_TYPE_RGB888:
        Image image = Image(width, height);
        Uint8List out = image.getBytes();
        int oi = 0;
        for (int y = 0; y < height; ++y) {
          for (int x = 0; x < width; ++x) {
            out[oi++] = input.readByte();
            out[oi++] = input.readByte();
            out[oi++] = input.readByte();
            out[oi++] = 255;
          }
        }
        return image;
      case PVR_TYPE_I8:
        Image image = Image(width, height);
        Uint8List out = image.getBytes();
        int oi = 0;
        for (int y = 0; y < height; ++y) {
          for(int x = 0; x < width; ++x) {
            int i = input.readByte();
            out[oi++] = i;
            out[oi++] = i;
            out[oi++] = i;
            out[oi++] = 255;
          }
        }
        return image;
      case PVR_TYPE_AI8:
        Image image = Image(width, height);
        Uint8List out = image.getBytes();
        int oi = 0;
        for (int y = 0; y < height; ++y) {
          for(int x = 0; x < width; ++x) {
            int i = input.readByte();
            int a = input.readByte();
            out[oi++] = i;
            out[oi++] = i;
            out[oi++] = i;
            out[oi++] = a;
          }
        }
        return image;
      case PVR_TYPE_PVRTC2:
        // Currently unsupported
        return null;
      case PVR_TYPE_PVRTC4:
        return amask == 0 ? decodeRgb4bpp(width, height, input.toUint8List()) :
               decodeRgba4bpp(width, height, input.toUint8List());
    }

    // Unknown format
    return null;
  }

  Image decodePVR3(List<int> data) {
    //const int PVR3_PVRTC_2BPP_RGB = 0;
    //const int PVR3_PVRTC_2BPP_RGBA = 1;
    const int PVR3_PVRTC_4BPP_RGB = 2;
    const int PVR3_PVRTC_4BPP_RGBA = 3;
    /*const int PVR3_PVRTC2_2BPP = 4;
    const int PVR3_PVRTC2_4BPP = 5;
    const int PVR3_ETC1 = 6;
    const int PVR3_DXT1 = 7;
    const int PVR3_DXT2 = 8;
    const int PVR3_DXT3 = 9;
    const int PVR3_DXT4 = 10;
    const int PVR3_DXT5 = 11;
    const int PVR3_BC1 = 7;
    const int PVR3_BC2 = 9;
    const int PVR3_BC3 = 11;
    const int PVR3_BC4 = 12;
    const int PVR3_BC5 = 13;
    const int PVR3_BC6 = 14;
    const int PVR3_BC7 = 15;
    const int PVR3_UYVY = 16;
    const int PVR3_YUY2 = 17;
    const int PVR3_BW_1BPP = 18;
    const int PVR3_R9G9B9E5 = 19;
    const int PVR3_RGBG8888 = 20;
    const int PVR3_GRGB8888 = 21;
    const int PVR3_ETC2_RGB = 22;
    const int PVR3_ETC2_RGBA = 23;
    const int PVR3_ETC2_RGB_A1 = 24;
    const int PVR3_EAC_R11_U = 25;
    const int PVR3_EAC_R11_S = 26;
    const int PVR3_EAC_RG11_U = 27;
    const int PVR3_EAC_RG11_S = 28;*/

    InputBuffer input = InputBuffer(data);

    // Header
    int version = input.readUint32();
    if (version != 0x03525650) {
      return null;
    }

    /*int flags =*/ input.readUint32();
    var format = input.readUint32();
    var order = [input.readByte(), input.readByte(),
                 input.readByte(), input.readByte()];
    /*int colorspace =*/ input.readUint32();
    /*int channeltype =*/ input.readUint32();
    int height = input.readUint32();
    int width = input.readUint32();
    /*int depth =*/ input.readUint32();
    /*int num_surfaces =*/ input.readUint32();
    /*int num_faces =*/ input.readUint32();
    /*int mipcount =*/ input.readUint32();
    int metadata_size = input.readUint32();

    input.skip(metadata_size);

    if (order[0] == 0) {
      switch (format) {
        case PVR3_PVRTC_4BPP_RGB:
          return decodeRgb4bpp(width, height, input.toUint8List());
        case PVR3_PVRTC_4BPP_RGBA:
          return decodeRgba4bpp(width, height, input.toUint8List());
        /*case PVR3_PVRTC_2BPP_RGB:
          return null;
        case PVR3_PVRTC_2BPP_RGBA:
          return null;
        case PVR3_PVRTC2_2BPP:
          return null;
        case PVR3_PVRTC2_4BPP:
          return null;
        case PVR3_ETC1:
          return null;
        case PVR3_DXT1:
          return null;
        case PVR3_DXT2:
          return null;
        case PVR3_DXT3:
          return null;
        case PVR3_DXT4:
          return null;
        case PVR3_DXT5:
          return null;
        case PVR3_BC1:
          return null;
        case PVR3_BC2:
          return null;
        case PVR3_BC3:
          return null;
        case PVR3_BC4:
          return null;
        case PVR3_BC5:
          return null;
        case PVR3_BC6:
          return null;
        case PVR3_BC7:
          return null;
        case PVR3_UYVY:
          return null;
        case PVR3_YUY2:
          return null;
        case PVR3_BW_1BPP:
          return null;
        case PVR3_R9G9B9E5:
          return null;
        case PVR3_RGBG8888:
          return null;
        case PVR3_GRGB8888:
          return null;
        case PVR3_ETC2_RGB:
          return null;
        case PVR3_ETC2_RGBA:
          return null;
        case PVR3_ETC2_RGB_A1:
          return null;
        case PVR3_EAC_R11_U:
          return null;
        case PVR3_EAC_R11_S:
          return null;
        case PVR3_EAC_RG11_U:
          return null;
        case PVR3_EAC_RG11_S:
          return null;*/
      }
    }

    return null;
  }

  int _countBits(int x) {
    x = (x - ((x >> 1) & 0x55555555)) & 0xffffffff;
    x = ((x & 0x33333333) + ((x >> 2) & 0x33333333)) & 0xffffffff;
    x = (x + (x >> 4)) & 0xffffffff;
    x &= 0xf0f0f0f;
    x = ((x * 0x01010101) & 0xffffffff) >> 24;
    return x;
  }

  Image decodeRgb4bpp(int width, int height, TypedData data) {
    var result = Image(width, height, Image.RGB);

    final int blocks = width ~/ 4;
    final int blockMask = blocks - 1;

    final packet = PvrtcPacket(data);
    final p0 = PvrtcPacket(data);
    final p1 = PvrtcPacket(data);
    final p2 = PvrtcPacket(data);
    final p3 = PvrtcPacket(data);
    final c = PvrtcColorRgb();
    const factors = PvrtcPacket.BILINEAR_FACTORS;
    const weights = PvrtcPacket.WEIGHTS;

    for (int y = 0; y < blocks; ++y) {
      for (int x = 0; x < blocks; ++x) {
        packet.setBlock(x, y);

        int mod = packet.modulationData;
        int weightIndex = 4 * packet.usePunchthroughAlpha;
        int factorIndex = 0;

        for (int py = 0; py < 4; ++py) {
          int yOffset = (py < 2) ? -1 : 0;
          int y0 = (y + yOffset) & blockMask;
          int y1 = (y0 + 1) & blockMask;
          int pyi = (py + y * 4) * width;

          for (int px = 0; px < 4; ++px) {
            int xOffset = (px < 2) ? -1 : 0;
            int x0 = (x + xOffset) & blockMask;
            int x1 = (x0 + 1) & blockMask;

            p0.setBlock(x0, y0);
            p1.setBlock(x1, y0);
            p2.setBlock(x0, y1);
            p3.setBlock(x1, y1);

            var ca = p0.getColorRgbA() * factors[factorIndex][0] +
                     p1.getColorRgbA() * factors[factorIndex][1] +
                     p2.getColorRgbA() * factors[factorIndex][2] +
                     p3.getColorRgbA() * factors[factorIndex][3];

            var cb = p0.getColorRgbB() * factors[factorIndex][0] +
                     p1.getColorRgbB() * factors[factorIndex][1] +
                     p2.getColorRgbB() * factors[factorIndex][2] +
                     p3.getColorRgbB() * factors[factorIndex][3];

            var w = weights[weightIndex + mod & 3];

            c.r = (ca.r * w[0] + cb.r * w[1]) >> 7;
            c.g = (ca.g * w[0] + cb.g * w[1]) >> 7;
            c.b = (ca.b * w[0] + cb.b * w[1]) >> 7;

            int pi = (pyi + (px + x * 4));

            result[pi] = getColor(c.r, c.g, c.b, 255);

            mod >>= 2;
            factorIndex++;
          }
        }
      }
    }

    return result;
  }

  Image decodeRgba4bpp(int width, int height, TypedData data) {
    var result = Image(width, height, Image.RGBA);

    final int blocks = width ~/ 4;
    final int blockMask = blocks - 1;

    final packet = PvrtcPacket(data);
    final p0 = PvrtcPacket(data);
    final p1 = PvrtcPacket(data);
    final p2 = PvrtcPacket(data);
    final p3 = PvrtcPacket(data);
    final c = PvrtcColorRgba();
    const factors = PvrtcPacket.BILINEAR_FACTORS;
    const weights = PvrtcPacket.WEIGHTS;

    for (int y = 0; y < blocks; ++y) {
      for (int x = 0; x < blocks; ++x) {
        packet.setBlock(x, y);

        int mod = packet.modulationData;
        int weightIndex = 4 * packet.usePunchthroughAlpha;
        int factorIndex = 0;

        for (int py = 0; py < 4; ++py) {
          int yOffset = (py < 2) ? -1 : 0;
          int y0 = (y + yOffset) & blockMask;
          int y1 = (y0 + 1) & blockMask;
          int pyi = (py + y * 4) * width;

          for (int px = 0; px < 4; ++px) {
            int xOffset = (px < 2) ? -1 : 0;
            int x0 = (x + xOffset) & blockMask;
            int x1 = (x0 + 1) & blockMask;

            p0.setBlock(x0, y0);
            p1.setBlock(x1, y0);
            p2.setBlock(x0, y1);
            p3.setBlock(x1, y1);

            var ca = p0.getColorRgbaA() * factors[factorIndex][0] +
                     p1.getColorRgbaA() * factors[factorIndex][1] +
                     p2.getColorRgbaA() * factors[factorIndex][2] +
                     p3.getColorRgbaA() * factors[factorIndex][3];

            var cb = p0.getColorRgbaB() * factors[factorIndex][0] +
                     p1.getColorRgbaB() * factors[factorIndex][1] +
                     p2.getColorRgbaB() * factors[factorIndex][2] +
                     p3.getColorRgbaB() * factors[factorIndex][3];

            var w = weights[weightIndex + mod & 3];

            c.r = (ca.r * w[0] + cb.r * w[1]) >> 7;
            c.g = (ca.g * w[0] + cb.g * w[1]) >> 7;
            c.b = (ca.b * w[0] + cb.b * w[1]) >> 7;
            c.a = (ca.a * w[2] + cb.a * w[3]) >> 7;

            int pi = (pyi + (px + x * 4));

            result[pi] = getColor(c.r, c.g, c.b, c.a);

            mod >>= 2;
            factorIndex++;
          }
        }
      }
    }

    return result;
  }
}
