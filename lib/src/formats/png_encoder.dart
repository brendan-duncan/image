import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../color/format.dart';
import '../image/icc_profile.dart';
import '../image/image.dart';
import '../image/palette.dart';
import '../util/neural_quantizer.dart';
import '../util/output_buffer.dart';
import '../util/quantizer.dart';
import 'encoder.dart';
import 'png/_png_deflate.dart' if (dart.library.io) 'png/_png_deflate_io.dart';
import 'png/png_info.dart';

enum PngFilter { none, sub, up, average, paeth }

/// Encode an image to the PNG format.
class PngEncoder extends Encoder {
  Quantizer? _globalQuantizer;

  PngEncoder(
      {this.filter = PngFilter.paeth,
      this.level,
      this.pixelDimensions,
      this.cicpData});

  // The most image data stored in each IDAT or fdAT chunk.
  static const _maxDataChunkSize = 0x10000;

  int _numChannels(Image image) => image.hasPalette ? 1 : image.numChannels;

  void addFrame(Image image) {
    // PNG can't encode HDR formats, and can only encode formats with fewer
    // than 8 bits if they have a palette. In the case of incompatible
    // formats, convert them to uint8.
    if ((image.isHdrFormat && image.format != Format.uint16) ||
        (image.bitsPerChannel < 8 &&
            !image.hasPalette &&
            image.numChannels > 1)) {
      image = image.convert(format: Format.uint8);
    }

    if (output == null) {
      output = OutputBuffer(bigEndian: true);

      _writeHeader(image);

      if (image.iccProfile != null) {
        _writeICCPChunk(output, image.iccProfile!);
      }

      if (cicpData != null) {
        _writeCicpChunk(output!, cicpData!);
      }

      if (image.hasPalette) {
        if (_globalQuantizer != null) {
          _writePalette(_globalQuantizer!.palette);
        } else {
          _writePalette(image.palette!);
        }
      }

      if (isAnimated) {
        _writeAnimationControlChunk();
      }
    }

    if (image.textData != null) {
      for (var key in image.textData!.keys) {
        _writeTextChunk(key, image.textData![key]!);
      }
    }

    if (pixelDimensions != null) {
      final phys = OutputBuffer(bigEndian: true)
        ..writeUint32(pixelDimensions!.xPxPerUnit)
        ..writeUint32(pixelDimensions!.yPxPerUnit)
        ..writeByte(pixelDimensions!.unitSpecifier);
      _writeChunk(output!, 'pHYs', phys.getBytes());
    }

    if (isAnimated) {
      _writeFrameControlChunk(image);
      sequenceNumber++;
    }

    // The first frame is stored in IDAT chunks, later animation frames in fdAT
    // chunks, which start with a sequence number.
    final isIdat = sequenceNumber <= 1;
    final dataStart = isIdat ? 0 : 4;
    final chunk = Uint8List(dataStart + _maxDataChunkSize);
    var chunkLength = dataStart;
    var chunksWritten = 0;

    void writeDataChunk() {
      if (isIdat) {
        _writeChunk(
            output!, 'IDAT', Uint8List.view(chunk.buffer, 0, chunkLength));
      } else {
        chunk
          ..[0] = (sequenceNumber >> 24) & 0xff
          ..[1] = (sequenceNumber >> 16) & 0xff
          ..[2] = (sequenceNumber >> 8) & 0xff
          ..[3] = sequenceNumber & 0xff;
        sequenceNumber++;
        _writeChunk(
            output!, 'fdAT', Uint8List.view(chunk.buffer, 0, chunkLength));
      }
      chunkLength = dataStart;
      chunksWritten++;
    }

    // Compressed data is written out in chunks as it's produced.
    final rowBytes = image.data!.rowStride;
    final deflater = PngDeflater(level, (rowBytes + 1) * image.height, (bytes) {
      var i = 0;
      while (i < bytes.length) {
        final n = min(bytes.length - i, chunk.length - chunkLength);
        chunk.setRange(chunkLength, chunkLength + n, bytes, i);
        chunkLength += n;
        i += n;
        if (chunkLength == chunk.length) {
          writeDataChunk();
        }
      }
    });

    _filter(image, deflater);
    deflater.close();

    if (chunkLength > dataStart || chunksWritten == 0) {
      writeDataChunk();
    }
  }

  /// Start encoding a PNG.
  ///
  /// Call this method once before calling addFrame.
  void start(int frameCount) {
    _frames = frameCount;
    isAnimated = frameCount > 1;
  }

  /// Finish encoding a PNG, and return the resulting bytes.
  ///
  /// Call this method to finalize the encoding, after all addFrame calls.
  Uint8List? finish() {
    Uint8List? bytes;

    if (output == null) {
      return bytes;
    }

    _writeChunk(output!, 'IEND', []);

    sequenceNumber = 0;

    bytes = output!.getBytes();
    output = null;
    return bytes;
  }

  /// Does this encoder support animation?
  @override
  bool get supportsAnimation => true;

  /// Encode [image] to the PNG format.
  @override
  Uint8List encode(Image image, {bool singleFrame = false}) {
    if (!image.hasAnimation || singleFrame) {
      start(1);
      addFrame(image);
    } else {
      start(image.frames.length);
      repeat = image.loopCount;

      if (image.hasPalette) {
        final q = NeuralQuantizer(image);
        _globalQuantizer = q;
        for (final frame in image.frames) {
          if (frame != image) {
            q.addImage(frame);
          }
        }
      }

      for (final frame in image.frames) {
        if (_globalQuantizer != null) {
          final newImage = _globalQuantizer!.getIndexImage(frame);
          addFrame(newImage);
        } else {
          addFrame(frame);
        }
      }
    }
    return finish()!;
  }

  void _writeHeader(Image image) {
    // PNG file signature
    output!.writeBytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

    // IHDR chunk
    final chunk = OutputBuffer(bigEndian: true)
      ..writeUint32(image.width) // width
      ..writeUint32(image.height) // height
      ..writeByte(image.bitsPerChannel) // bit depth
      ..writeByte(image.hasPalette
          ? PngColorType.indexed
          : image.numChannels == 1
              ? PngColorType.grayscale
              : image.numChannels == 2
                  ? PngColorType.grayscaleAlpha
                  : image.numChannels == 3
                      ? PngColorType.rgb
                      : PngColorType.rgba)
      ..writeByte(0) // compression method: 0:deflate
      ..writeByte(0) // filter method: 0:adaptive
      ..writeByte(0); // interlace method: 0:no interlace
    _writeChunk(output!, 'IHDR', chunk.getBytes());
  }

  void _writeAnimationControlChunk() {
    final chunk = OutputBuffer(bigEndian: true)
      ..writeUint32(_frames) // number of frames
      ..writeUint32(repeat); // loop count
    _writeChunk(output!, 'acTL', chunk.getBytes());
  }

  void _writeFrameControlChunk(Image image) {
    final chunk = OutputBuffer(bigEndian: true)
      ..writeUint32(sequenceNumber)
      ..writeUint32(image.width)
      ..writeUint32(image.height)
      ..writeUint32(0) // xOffset
      ..writeUint32(0) // yOffset
      ..writeUint16(image.frameDuration)
      ..writeUint16(1000) // delay denominator
      ..writeByte(1) // dispose method 0: APNG_DISPOSE_OP_NONE
      ..writeByte(0); // blend method 0: APNG_BLEND_OP_SOURCE
    _writeChunk(output!, 'fcTL', chunk.getBytes());
  }

  void _writeTextChunk(String keyword, String text) {
    final chunk = OutputBuffer(bigEndian: true)
      ..writeBytes(latin1.encode(keyword))
      ..writeByte(0)
      ..writeBytes(latin1.encode(text));
    _writeChunk(output!, 'tEXt', chunk.getBytes());
  }

  void _writePalette(Palette palette) {
    if (palette.format == Format.uint8 &&
        palette.numChannels == 3 &&
        palette.numColors == 256) {
      _writeChunk(output!, 'PLTE', palette.toUint8List());
    } else {
      final chunk = OutputBuffer(size: palette.numColors * 3, bigEndian: true);
      final nc = palette.numColors;
      for (var i = 0; i < nc; ++i) {
        chunk
          ..writeByte(palette.getRed(i).toInt())
          ..writeByte(palette.getGreen(i).toInt())
          ..writeByte(palette.getBlue(i).toInt());
      }
      _writeChunk(output!, 'PLTE', chunk.getBytes());
    }

    if (palette.numChannels == 4) {
      final chunk = OutputBuffer(size: palette.numColors, bigEndian: true);
      final nc = palette.numColors;
      for (var i = 0; i < nc; ++i) {
        final a = palette.getAlpha(i).toInt();
        chunk.writeByte(a);
      }
      _writeChunk(output!, 'tRNS', chunk.getBytes());
    }
  }

  void _writeCicpChunk(OutputBuffer out, PngCicpData cicp) {
    final chunk = OutputBuffer(bigEndian: true)
      ..writeByte(cicp.colorPrimaries)
      ..writeByte(cicp.transferCharacteristics)
      ..writeByte(cicp.matrixCoefficients)
      ..writeByte(cicp.videoFullRangeFlag);
    _writeChunk(out, 'cICP', chunk.getBytes());
  }

  /// A PNG keyword is 1 to 79 Latin-1 printable bytes with no leading,
  /// trailing or doubled space; a profile named otherwise gets a default
  static String _iccpKeyword(String name) {
    final units = name.codeUnits;
    var valid = units.isNotEmpty &&
        units.length <= 79 &&
        units.first != 0x20 &&
        units.last != 0x20;
    for (var i = 0; valid && i < units.length; i++) {
      final c = units[i];
      // The doubled space test reads units[i - 1], which at i == 0 would be
      // out of range. The check above already rejected a leading space, so at
      // i == 0 the byte is not a space and && stops before the read
      valid = (c >= 0x20 && c <= 0x7e || c >= 0xa1 && c <= 0xff) &&
          !(c == 0x20 && units[i - 1] == 0x20);
    }
    return valid ? name : 'ICC_PROFILE';
  }

  void _writeICCPChunk(OutputBuffer? out, IccProfile iccp) {
    final chunk = OutputBuffer(bigEndian: true)

      // name
      ..writeBytes(_iccpKeyword(iccp.name).codeUnits)
      ..writeByte(0)

      // compression
      ..writeByte(0) // 0 - deflate

      // profile data
      ..writeBytes(iccp.compressed());

    _writeChunk(output!, 'iCCP', chunk.getBytes());
  }

  void _writeChunk(OutputBuffer out, String type, List<int> chunk) {
    out
      ..writeUint32(chunk.length)
      ..writeBytes(type.codeUnits)
      ..writeBytes(chunk);
    final crc = _crc(type, chunk);
    out.writeUint32(crc);
  }

  // Filters each row of [image], passing it to [deflater] with its filter
  // type byte.
  void _filter(Image image, PngDeflater deflater) {
    final filter = image.hasPalette ? PngFilter.none : this.filter;
    final buffer = image.buffer;
    final rowStride = image.data!.rowStride;
    final nc = _numChannels(image);
    final bpp = ((nc * image.bitsPerChannel) + 7) >> 3;
    final bpc = (image.bitsPerChannel + 7) >> 3;

    // Each row is copied into one of two buffers, swapping multi-byte samples
    // to PNG's big-endian order. Keeping every row in the same kind of list
    // (not a view) keeps the filter loops fast.
    final rows = [Uint8List(rowStride), Uint8List(rowStride)];
    var prevRow = rows[1];
    final out = Uint8List(rowStride + 1);
    out[0] = filter.index;

    var rowOffset = 0;
    for (var y = 0; y < image.height; ++y, rowOffset += rowStride) {
      final src = Uint8List.view(buffer, rowOffset, rowStride);
      final row = rows[y & 1];
      if (bpc > 1) {
        for (var x = 0; x < rowStride; x += bpc) {
          for (var c = 0, c2 = bpc - 1; c < bpc; ++c, --c2) {
            row[x + c] = src[x + c2];
          }
        }
      } else {
        row.setRange(0, rowStride, src);
      }

      switch (filter) {
        case PngFilter.none:
          out.setRange(1, rowStride + 1, row);
          break;
        case PngFilter.sub:
          _filterSub(row, bpp, out);
          break;
        case PngFilter.up:
          _filterUp(row, prevRow, out);
          break;
        case PngFilter.average:
          _filterAverage(row, prevRow, bpp, out);
          break;
        case PngFilter.paeth:
          _filterPaeth(row, prevRow, bpp, out);
          break;
      }

      deflater.add(out);
      prevRow = row;
    }
  }

  // Each filter writes the filtered [row] to [out], after its filter type
  // byte. They're kept as separate small functions, which the compiler
  // optimizes much better than one large one.

  static void _filterSub(Uint8List row, int bpp, Uint8List out) {
    final n = row.length;
    var oi = 1;
    for (var x = 0; x < bpp && x < n; ++x) {
      out[oi++] = row[x];
    }
    for (var x = bpp; x < n; ++x) {
      out[oi++] = row[x] - row[x - bpp];
    }
  }

  static void _filterUp(Uint8List row, Uint8List prevRow, Uint8List out) {
    final n = row.length;
    var oi = 1;
    for (var x = 0; x < n; ++x) {
      out[oi++] = row[x] - prevRow[x];
    }
  }

  static void _filterAverage(
      Uint8List row, Uint8List prevRow, int bpp, Uint8List out) {
    final n = row.length;
    var oi = 1;
    for (var x = 0; x < bpp && x < n; ++x) {
      out[oi++] = row[x] - (prevRow[x] >> 1);
    }
    for (var x = bpp; x < n; ++x) {
      out[oi++] = row[x] - ((row[x - bpp] + prevRow[x]) >> 1);
    }
  }

  static void _filterPaeth(
      Uint8List row, Uint8List prevRow, int bpp, Uint8List out) {
    final n = row.length;
    var oi = 1;
    // With no left byte, the predictor is always the byte above.
    for (var x = 0; x < bpp && x < n; ++x) {
      out[oi++] = row[x] - prevRow[x];
    }
    for (var x = bpp; x < n; ++x) {
      final a = row[x - bpp];
      final b = prevRow[x];
      final c = prevRow[x - bpp];
      var pa = b - c;
      var pb = a - c;
      var pc = pa + pb;
      if (pa < 0) {
        pa = -pa;
      }
      if (pb < 0) {
        pb = -pb;
      }
      if (pc < 0) {
        pc = -pc;
      }
      out[oi++] = row[x] - (pa <= pb && pa <= pc ? a : (pb <= pc ? b : c));
    }
  }

  // Return the CRC of the bytes
  int _crc(String type, List<int> bytes) {
    final crc = getCrc32(type.codeUnits);
    return getCrc32(bytes, crc);
  }

  PngFilter filter;
  int repeat = 0;
  int? level;
  late int _frames;
  int sequenceNumber = 0;
  bool isAnimated = false;
  OutputBuffer? output;
  Map<String, String>? textData;
  PngPhysicalPixelDimensions? pixelDimensions;
  PngCicpData? cicpData;
}
