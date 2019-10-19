import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../color.dart';
import '../animation.dart';
import '../icc_profile_data.dart';
import '../image.dart';
import '../util/output_buffer.dart';
import 'encoder.dart';

/// Encode an image to the PNG format.
class PngEncoder extends Encoder {
  PngEncoder({this.filter = FILTER_PAETH, this.level});

  void addFrame(Image image) {
    xOffset = image.xOffset;
    yOffset = image.xOffset;
    delay = image.duration;
    disposeMethod = image.disposeMethod;
    blendMethod = image.blendMethod;

    if (output == null) {
      output = OutputBuffer(bigEndian: true);

      channels = image.channels;
      _width = image.width;
      _height = image.height;

      _writeHeader(_width, _height);

      _writeICCPChunk(output, image.iccProfile);

      if (isAnimated) {
        _writeAnimationControlChunk();
      }
    }

    // Include room for the filter bytes (1 byte per row).
    var filteredImage = Uint8List(
        (image.width * image.height * image.numberOfChannels) + image.height);

    _filter(image, filteredImage);

    List<int> compressed = ZLibEncoder().encode(filteredImage, level: level);

    if (isAnimated) {
      _writeFrameControlChunk();
      sequenceNumber++;
    }

    if (sequenceNumber <= 1) {
      _writeChunk(output, 'IDAT', compressed);
    } else {
      // fdAT chunk
      OutputBuffer fdat = OutputBuffer(bigEndian: true);
      fdat.writeUint32(sequenceNumber);
      fdat.writeBytes(compressed);
      _writeChunk(output, 'fdAT', fdat.getBytes());

      sequenceNumber++;
    }
  }

  List<int> finish() {
    List<int> bytes;

    if (output == null) {
      return bytes;
    }

    _writeChunk(output, 'IEND', []);

    sequenceNumber = 0;

    bytes = output.getBytes();
    output = null;
    return bytes;
  }

  /// Does this encoder support animation?
  bool get supportsAnimation => true;

  /// Encode an animation.
  List<int> encodeAnimation(Animation anim) {
    isAnimated = true;
    _frames = anim.frames.length;
    repeat = anim.loopCount;

    for (Image f in anim) {
      addFrame(f);
    }
    return finish();
  }

  /// Encode a single frame image.
  List<int> encodeImage(Image image) {
    isAnimated = false;
    addFrame(image);
    return finish();
  }

  void _writeHeader(int width, int height) {
    // PNG file signature
    output.writeBytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

    // IHDR chunk
    OutputBuffer chunk = OutputBuffer(bigEndian: true);
    chunk.writeUint32(width);
    chunk.writeUint32(height);
    chunk.writeByte(8);
    chunk.writeByte(channels == Channels.rgb ? 2 : 6);
    chunk.writeByte(0); // compression method
    chunk.writeByte(0); // filter method
    chunk.writeByte(0); // interlace method
    _writeChunk(output, 'IHDR', chunk.getBytes());
  }

  void _writeAnimationControlChunk() {
    OutputBuffer chunk = OutputBuffer(bigEndian: true);
    chunk.writeUint32(_frames); // number of frames
    chunk.writeUint32(repeat); // loop count
    _writeChunk(output, 'acTL', chunk.getBytes());
  }

  void _writeFrameControlChunk() {
    OutputBuffer chunk = OutputBuffer(bigEndian: true);
    chunk.writeUint32(sequenceNumber);
    chunk.writeUint32(_width);
    chunk.writeUint32(_height);
    chunk.writeUint32(xOffset);
    chunk.writeUint32(yOffset);
    chunk.writeUint16(delay);
    chunk.writeUint16(0); // delay denominator
    chunk.writeByte(disposeMethod.index);
    chunk.writeByte(blendMethod.index);
    _writeChunk(output, 'fcTL', chunk.getBytes());
  }

  void _writeICCPChunk(OutputBuffer out, ICCProfileData iccp) {
    if (iccp == null || iccp.data == null) {
      return;
    }

    OutputBuffer chunk = OutputBuffer(bigEndian: true);

    // name
    chunk.writeBytes(iccp.name.codeUnits);
    chunk.writeByte(0);

    // compression
    chunk.writeByte(0); // 0 - deflate

    // profile data
    chunk.writeBytes(iccp.compressed());

    _writeChunk(output, 'iCCP', chunk.getBytes());
  }

  void _writeChunk(OutputBuffer out, String type, List<int> chunk) {
    out.writeUint32(chunk.length);
    out.writeBytes(type.codeUnits);
    out.writeBytes(chunk);
    int crc = _crc(type, chunk);
    out.writeUint32(crc);
  }

  void _filter(Image image, List<int> out) {
    int oi = 0;
    for (int y = 0; y < image.height; ++y) {
      switch (filter) {
        case FILTER_SUB:
          oi = _filterSub(image, oi, y, out);
          break;
        case FILTER_UP:
          oi = _filterUp(image, oi, y, out);
          break;
        case FILTER_AVERAGE:
          oi = _filterAverage(image, oi, y, out);
          break;
        case FILTER_PAETH:
          oi = _filterPaeth(image, oi, y, out);
          break;
        case FILTER_AGRESSIVE:
          // TODO Apply all five filters and select the filter that produces
          // the smallest sum of absolute values per row.
          oi = _filterPaeth(image, oi, y, out);
          break;
        default:
          oi = _filterNone(image, oi, y, out);
          break;
      }
    }
  }

  int _filterNone(Image image, int oi, int row, List<int> out) {
    out[oi++] = FILTER_NONE;
    for (int x = 0; x < image.width; ++x) {
      int c = image.getPixel(x, row);
      out[oi++] = getRed(c);
      out[oi++] = getGreen(c);
      out[oi++] = getBlue(c);
      if (image.channels == Channels.rgba) {
        out[oi++] = getAlpha(image.getPixel(x, row));
      }
    }
    return oi;
  }

  int _filterSub(Image image, int oi, int row, List<int> out) {
    out[oi++] = FILTER_SUB;

    out[oi++] = getRed(image.getPixel(0, row));
    out[oi++] = getGreen(image.getPixel(0, row));
    out[oi++] = getBlue(image.getPixel(0, row));
    if (image.channels == Channels.rgba) {
      out[oi++] = getAlpha(image.getPixel(0, row));
    }

    for (int x = 1; x < image.width; ++x) {
      int ar = getRed(image.getPixel(x - 1, row));
      int ag = getGreen(image.getPixel(x - 1, row));
      int ab = getBlue(image.getPixel(x - 1, row));

      int r = getRed(image.getPixel(x, row));
      int g = getGreen(image.getPixel(x, row));
      int b = getBlue(image.getPixel(x, row));

      out[oi++] = ((r - ar)) & 0xff;
      out[oi++] = ((g - ag)) & 0xff;
      out[oi++] = ((b - ab)) & 0xff;
      if (image.channels == Channels.rgba) {
        int aa = getAlpha(image.getPixel(x - 1, row));
        int a = getAlpha(image.getPixel(x, row));
        out[oi++] = ((a - aa)) & 0xff;
      }
    }

    return oi;
  }

  int _filterUp(Image image, int oi, int row, List<int> out) {
    out[oi++] = FILTER_UP;

    for (int x = 0; x < image.width; ++x) {
      int br = (row == 0) ? 0 : getRed(image.getPixel(x, row - 1));
      int bg = (row == 0) ? 0 : getGreen(image.getPixel(x, row - 1));
      int bb = (row == 0) ? 0 : getBlue(image.getPixel(x, row - 1));

      int xr = getRed(image.getPixel(x, row));
      int xg = getGreen(image.getPixel(x, row));
      int xb = getBlue(image.getPixel(x, row));

      out[oi++] = (xr - br) & 0xff;
      out[oi++] = (xg - bg) & 0xff;
      out[oi++] = (xb - bb) & 0xff;
      if (image.channels == Channels.rgba) {
        int ba = (row == 0) ? 0 : getAlpha(image.getPixel(x, row - 1));
        int xa = getAlpha(image.getPixel(x, row));
        out[oi++] = (xa - ba) & 0xff;
        ;
      }
    }

    return oi;
  }

  int _filterAverage(Image image, int oi, int row, List<int> out) {
    out[oi++] = FILTER_AVERAGE;

    for (int x = 0; x < image.width; ++x) {
      int ar = (x == 0) ? 0 : getRed(image.getPixel(x - 1, row));
      int ag = (x == 0) ? 0 : getGreen(image.getPixel(x - 1, row));
      int ab = (x == 0) ? 0 : getBlue(image.getPixel(x - 1, row));

      int br = (row == 0) ? 0 : getRed(image.getPixel(x, row - 1));
      int bg = (row == 0) ? 0 : getGreen(image.getPixel(x, row - 1));
      int bb = (row == 0) ? 0 : getBlue(image.getPixel(x, row - 1));

      int xr = getRed(image.getPixel(x, row));
      int xg = getGreen(image.getPixel(x, row));
      int xb = getBlue(image.getPixel(x, row));

      out[oi++] = (xr - ((ar + br) >> 1)) & 0xff;
      out[oi++] = (xg - ((ag + bg) >> 1)) & 0xff;
      out[oi++] = (xb - ((ab + bb) >> 1)) & 0xff;
      if (image.channels == Channels.rgba) {
        int aa = (x == 0) ? 0 : getAlpha(image.getPixel(x - 1, row));
        int ba = (row == 0) ? 0 : getAlpha(image.getPixel(x, row - 1));
        int xa = getAlpha(image.getPixel(x, row));
        out[oi++] = (xa - ((aa + ba) >> 1)) & 0xff;
        ;
      }
    }

    return oi;
  }

  int _paethPredictor(int a, int b, int c) {
    int p = a + b - c;
    int pa = (p > a) ? p - a : a - p;
    int pb = (p > b) ? p - b : b - p;
    int pc = (p > c) ? p - c : c - p;
    if (pa <= pb && pa <= pc) {
      return a;
    } else if (pb <= pc) {
      return b;
    }
    return c;
  }

  int _filterPaeth(Image image, int oi, int row, List<int> out) {
    out[oi++] = FILTER_PAETH;

    for (int x = 0; x < image.width; ++x) {
      int ar = (x == 0) ? 0 : getRed(image.getPixel(x - 1, row));
      int ag = (x == 0) ? 0 : getGreen(image.getPixel(x - 1, row));
      int ab = (x == 0) ? 0 : getBlue(image.getPixel(x - 1, row));

      int br = (row == 0) ? 0 : getRed(image.getPixel(x, row - 1));
      int bg = (row == 0) ? 0 : getGreen(image.getPixel(x, row - 1));
      int bb = (row == 0) ? 0 : getBlue(image.getPixel(x, row - 1));

      int cr =
          (row == 0 || x == 0) ? 0 : getRed(image.getPixel(x - 1, row - 1));
      int cg =
          (row == 0 || x == 0) ? 0 : getGreen(image.getPixel(x - 1, row - 1));
      int cb =
          (row == 0 || x == 0) ? 0 : getBlue(image.getPixel(x - 1, row - 1));

      int xr = getRed(image.getPixel(x, row));
      int xg = getGreen(image.getPixel(x, row));
      int xb = getBlue(image.getPixel(x, row));

      int pr = _paethPredictor(ar, br, cr);
      int pg = _paethPredictor(ag, bg, cg);
      int pb = _paethPredictor(ab, bb, cb);

      out[oi++] = (xr - pr) & 0xff;
      out[oi++] = (xg - pg) & 0xff;
      out[oi++] = (xb - pb) & 0xff;
      if (image.channels == Channels.rgba) {
        int aa = (x == 0) ? 0 : getAlpha(image.getPixel(x - 1, row));
        int ba = (row == 0) ? 0 : getAlpha(image.getPixel(x, row - 1));
        int ca =
            (row == 0 || x == 0) ? 0 : getAlpha(image.getPixel(x - 1, row - 1));
        int xa = getAlpha(image.getPixel(x, row));
        int pa = _paethPredictor(aa, ba, ca);
        out[oi++] = (xa - pa) & 0xff;
      }
    }

    return oi;
  }

  // Return the CRC of the bytes
  int _crc(String type, List<int> bytes) {
    int crc = getCrc32(type.codeUnits);
    return getCrc32(bytes, crc);
  }

  Channels channels;
  int filter;
  int repeat;
  int level;
  int xOffset;
  int yOffset;
  int delay;
  DisposeMode disposeMethod;
  BlendMode blendMethod;
  int _width;
  int _height;
  int _frames;
  int sequenceNumber = 0;
  bool isAnimated;
  OutputBuffer output;

  static const int FILTER_NONE = 0;
  static const int FILTER_SUB = 1;
  static const int FILTER_UP = 2;
  static const int FILTER_AVERAGE = 3;
  static const int FILTER_PAETH = 4;
  static const int FILTER_AGRESSIVE = 5;

  // Table of CRCs of all 8-bit messages.
  //final List<int> _crcTable = List<int>(256);
}
