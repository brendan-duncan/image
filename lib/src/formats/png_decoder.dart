import 'dart:convert';
import 'dart:math' show min;
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../color/color_uint8.dart';
import '../color/format.dart';
import '../draw/blend_mode.dart';
import '../draw/composite_image.dart';
import '../draw/fill_rect.dart';
import '../image/icc_profile.dart';
import '../image/image.dart';
import '../image/image_data_uint16.dart';
import '../image/palette_uint8.dart';
import '../image/pixel.dart';
import '../util/image_exception.dart';
import '../util/input_buffer.dart';
import '_guard_decode.dart';
import '_max_pixels.dart';
import 'decode_info.dart';
import 'decoder.dart';
import 'image_format.dart';
import 'png/png_frame.dart';
import 'png/png_info.dart';

/// Decode a PNG encoded image.
class PngDecoder extends Decoder {
  final _info = InternalPngInfo();

  /// The maximum number of pixels (width * height) of the image, and of all
  /// the frames of a full animation decode. Larger images throw an
  /// [ImageException]. A value <= 0 disables the limit.
  final int maxPixels;

  PngDecoder({int? maxPixels})
      : maxPixels = maxPixels ?? Decoder.defaultMaxPixels;

  @override
  ImageFormat get format => ImageFormat.png;

  /// Is the given file a valid PNG image?
  @override
  bool isValidFile(Uint8List data) {
    if (data.length < 8) {
      return false;
    }
    const pngHeader = [137, 80, 78, 71, 13, 10, 26, 10];
    for (var i = 0; i < 8; ++i) {
      if (data[i] != pngHeader[i]) {
        return false;
      }
    }
    return true;
  }

  PngInfo get info => _info;

  /// Start decoding the data as an animation sequence, but don't actually
  /// process the frames until they are requested with decodeFrame.
  @override
  DecodeInfo? startDecode(Uint8List data) =>
      guardDecode(() => _startDecode(data));

  DecodeInfo? _startDecode(Uint8List data) {
    _input = InputBuffer(data, bigEndian: true);

    final pngHeader = _input.readBytes(8);
    const expectedHeader = [137, 80, 78, 71, 13, 10, 26, 10];
    for (var i = 0; i < 8; ++i) {
      if (pngHeader[i] != expectedHeader[i]) {
        return null;
      }
    }

    while (true) {
      final inputPos = _input.position;
      var chunkSize = _input.readUint32();
      final chunkType = _input.readString(4);
      switch (chunkType) {
        case 'tEXt':
          final txtData = _input.readBytes(chunkSize).toUint8List();
          final l = txtData.length;
          for (var i = 0; i < l; ++i) {
            if (txtData[i] == 0) {
              final key = latin1.decode(txtData.sublist(0, i));
              final text = latin1.decode(txtData.sublist(i + 1));
              _info.textData[key] = text;
              break;
            }
          }
          _input.skip(4); //crc
          break;
        case 'pHYs':
          final physData = InputBuffer.from(_input.readBytes(chunkSize));
          final x = physData.readUint32();
          final y = physData.readUint32();
          final unit = physData.readByte();
          _info.pixelDimensions = PngPhysicalPixelDimensions(
              xPxPerUnit: x, yPxPerUnit: y, unitSpecifier: unit);
          _input.skip(4); // CRC
          break;
        case 'IHDR':
          final hdr = InputBuffer.from(_input.readBytes(chunkSize));
          final Uint8List hdrBytes = hdr.toUint8List();
          _info.width = hdr.readUint32();
          _info.height = hdr.readUint32();
          checkPixels(_info.width, _info.height, maxPixels);
          _info.bits = hdr.readByte();
          _info.colorType = hdr.readByte();
          _info.compressionMethod = hdr.readByte();
          _info.filterMethod = hdr.readByte();
          _info.interlaceMethod = hdr.readByte();

          // Validate some of the info in the header to make sure we support
          // the proposed image data.
          if (!PngColorType.isValid(_info.colorType)) {
            return null;
          }

          if (_info.filterMethod != 0) {
            return null;
          }

          switch (_info.colorType) {
            case PngColorType.grayscale:
              if (![1, 2, 4, 8, 16].contains(_info.bits)) {
                return null;
              }
              break;
            case PngColorType.rgb:
              if (![8, 16].contains(_info.bits)) {
                return null;
              }
              break;
            case PngColorType.indexed:
              if (![1, 2, 4, 8].contains(_info.bits)) {
                return null;
              }
              break;
            case PngColorType.grayscaleAlpha:
              if (![8, 16].contains(_info.bits)) {
                return null;
              }
              break;
            case PngColorType.rgba:
              if (![8, 16].contains(_info.bits)) {
                return null;
              }
              break;
          }

          final crc = _input.readUint32();
          final computedCrc = _crc(chunkType, hdrBytes);
          if (crc != computedCrc) {
            throw ImageException('Invalid $chunkType checksum');
          }
          break;
        case 'PLTE':
          _info.palette = _input.readBytes(chunkSize).toUint8List();
          final crc = _input.readUint32();
          final computedCrc = _crc(chunkType, _info.palette as List<int>);
          if (crc != computedCrc) {
            throw ImageException('Invalid $chunkType checksum');
          }
          break;
        case 'tRNS':
          _info.transparency = _input.readBytes(chunkSize).toUint8List();
          final crc = _input.readUint32();
          final computedCrc = _crc(chunkType, _info.transparency!);
          if (crc != computedCrc) {
            throw ImageException('Invalid $chunkType checksum');
          }
          break;
        case 'IEND':
          // End of the image.
          _input.skip(4); // CRC
          break;
        /*case 'eXif': // TODO: parse exif
          {
            final exifData = _input.readBytes(chunkSize);
            final exif = ExifData.fromInputBuffer(exifData);
            _input.skip(4); // CRC
            break;
          }*/
        case 'gAMA':
          if (chunkSize != 4) {
            throw ImageException('Invalid gAMA chunk');
          }
          final gammaInt = _input.readUint32();
          _input.skip(4); // CRC
          // A gamma of 1.0 doesn't have any affect, so pretend we didn't get
          // a gamma in that case.
          if (gammaInt != 100000) {
            _info.gamma = gammaInt / 100000.0;
          }
          break;
        case 'IDAT':
          _info.idat.add(inputPos);
          _input
            ..skip(chunkSize)
            ..skip(4); // CRC
          break;
        case 'acTL': // Animation control chunk
          _info.numFrames = _input.readUint32();
          _info.repeat = _input.readUint32();
          _input.skip(4); // CRC
          break;
        case 'fcTL': // Frame control chunk
          final sequenceNumber = _input.readUint32();
          final width = _input.readUint32();
          final height = _input.readUint32();
          final xOffset = _input.readUint32();
          final yOffset = _input.readUint32();
          final delayNum = _input.readUint16();
          final delayDen = _input.readUint16();
          final dispose = _input.readByte();
          final blend = _input.readByte();
          final frame = InternalPngFrame(
              sequenceNumber: sequenceNumber,
              width: width,
              height: height,
              xOffset: xOffset,
              yOffset: yOffset,
              delayNum: delayNum,
              delayDen: delayDen,
              dispose: PngDisposeMode.values[dispose],
              blend: PngBlendMode.values[blend]);
          _info.frames.add(frame);
          _input.skip(4); // CRC
          break;
        case 'fdAT':
          /*int sequenceNumber =*/ _input.readUint32();
          final frame = _info.frames.last as InternalPngFrame;
          frame.fdat.add(inputPos);
          _input
            ..skip(chunkSize - 4)
            ..skip(4); // CRC
          break;
        case 'bKGD':
          if (_info.colorType == PngColorType.indexed) {
            final paletteIndex = _input.readByte();
            chunkSize--;
            final p3 = paletteIndex * 3;
            final r = _info.palette![p3]!;
            final g = _info.palette![p3 + 1]!;
            final b = _info.palette![p3 + 2]!;
            if (_info.transparency != null) {
              final isTransparent = _info.transparency!.contains(paletteIndex);
              _info.backgroundColor =
                  ColorRgba8(r, g, b, isTransparent ? 0 : 255);
            } else {
              _info.backgroundColor = ColorRgb8(r, g, b);
            }
          } else if (_info.colorType == PngColorType.grayscale ||
              _info.colorType == PngColorType.grayscaleAlpha) {
            /*int gray =*/ _input.readUint16();
            chunkSize -= 2;
          } else if (_info.colorType == PngColorType.rgb ||
              _info.colorType == PngColorType.rgba) {
            /*int r =*/ _input
              ..readUint16()
              /*int g =*/
              ..readUint16()
              /*int b =*/
              ..readUint16();
            chunkSize -= 24;
          }
          if (chunkSize > 0) {
            _input.skip(chunkSize);
          }
          _input.skip(4); // CRC
          break;
        case 'iCCP':
          _info.iccpName = _input.readString();
          _info.iccpCompression = _input.readByte(); // 0: deflate
          chunkSize -= _info.iccpName.length + 2;
          final profile = _input.readBytes(chunkSize);
          _info.iccpData = profile.toUint8List();
          _input.skip(4); // CRC
          break;
        case 'cICP':
          // Coding-independent code points (PNG spec 1.3 / ITU-T H.273).
          // The chunk is exactly 4 bytes: color primaries, transfer
          // characteristics, matrix coefficients, video full range flag.
          if (chunkSize == 4) {
            _info.cicpData = PngCicpData(
              colorPrimaries: _input.readByte(),
              transferCharacteristics: _input.readByte(),
              matrixCoefficients: _input.readByte(),
              videoFullRangeFlag: _input.readByte(),
            );
          } else {
            _input.skip(chunkSize);
          }
          _input.skip(4); // CRC
          break;
        default:
          //print('Skipping $chunkType');
          _input
            ..skip(chunkSize)
            ..skip(4); // CRC
          break;
      }

      if (chunkType == 'IEND') {
        break;
      }

      if (_input.isEOS) {
        return null;
      }
    }

    return _info;
  }

  /// The number of frames that can be decoded.
  @override
  int numFrames() => _info.numFrames;

  /// Decode the frame (assuming [startDecode] has already been called).
  @override
  Image? decodeFrame(int frame) => guardDecode(() => _decodeFrame(frame));

  Image? _decodeFrame(int frame) {
    Uint8List imageData;

    int? width = _info.width;
    int? height = _info.height;

    if (!_info.isAnimated || frame == 0) {
      final dataBlocks = <Uint8List>[];
      var totalSize = 0;
      final len = _info.idat.length;
      for (var i = 0; i < len; ++i) {
        _input.offset = _info.idat[i];
        final chunkSize = _input.readUint32();
        final chunkType = _input.readString(4);
        final data = _input.readBytes(chunkSize).toUint8List();
        totalSize += data.length;
        dataBlocks.add(data);
        final crc = _input.readUint32();
        final computedCrc = _crc(chunkType, data);
        if (crc != computedCrc) {
          throw ImageException('Invalid $chunkType checksum');
        }
      }
      imageData = Uint8List(totalSize);
      var offset = 0;
      for (var data in dataBlocks) {
        imageData.setAll(offset, data);
        offset += data.length;
      }
    } else {
      if (frame < 0 || frame >= _info.frames.length) {
        throw ImageException('Invalid Frame Number: $frame');
      }

      final f = _info.frames[frame] as InternalPngFrame;
      width = f.width;
      height = f.height;
      checkPixels(width, height, maxPixels);
      var totalSize = 0;
      final dataBlocks = <Uint8List>[];
      for (var i = 0; i < f.fdat.length; ++i) {
        _input.offset = f.fdat[i];
        final chunkSize = _input.readUint32();
        _input
          ..readString(4) // fDat chunk header
          ..skip(4); // sequence number
        final data = _input.readBytes(chunkSize - 4).toUint8List();
        totalSize += data.length;
        dataBlocks.add(data);
      }
      imageData = Uint8List(totalSize);
      var offset = 0;
      for (var data in dataBlocks) {
        imageData.setAll(offset, data);
        offset += data.length;
      }
    }

    var numChannels = _info.colorType == PngColorType.indexed
        ? 1
        : _info.colorType == PngColorType.grayscale
            ? 1
            : _info.colorType == PngColorType.grayscaleAlpha
                ? 2
                : _info.colorType == PngColorType.rgba
                    ? 4
                    : 3;

    // The image data is inflated as the rows are read, so the whole
    // decompressed image is never held in memory.
    final input = const ZLibDecoder().decodeLazy(InputMemoryStream(imageData));
    _resetBits();

    PaletteUint8? palette;

    // Non-indexed PNGs may have a palette, but it only provides a suggested
    // set of colors to which an RGB color can be quantized if not displayed
    // directly. In this case, just ignore the palette.
    if (_info.colorType == PngColorType.indexed) {
      if (_info.palette != null) {
        final p = _info.palette!;
        final numColors = p.length ~/ 3;
        final t = _info.transparency;
        final tl = t != null ? t.length : 0;
        final nc = t != null ? 4 : 3;
        palette = PaletteUint8(numColors, nc);
        for (var i = 0, pi = 0; i < numColors; ++i, pi += 3) {
          var a = 255;
          if (nc == 4 && i < tl) {
            a = t![i];
          }
          palette.setRgba(i, p[pi]!, p[pi + 1]!, p[pi + 2]!, a);
        }
      }
    }

    // grayscale images with no palette but with transparency, get
    // converted to a indexed palette image.
    if (_info.colorType == PngColorType.grayscale &&
        _info.transparency != null &&
        palette == null &&
        _info.bits <= 8) {
      final t = _info.transparency!;
      final nt = t.length;
      final numColors = 1 << _info.bits;
      palette = PaletteUint8(numColors, 4);
      // palette color are 8-bit, so convert the grayscale bit value to the
      // 8-bit palette value.
      final to8bit = _info.bits == 1
          ? 255
          : _info.bits == 2
              ? 85
              : _info.bits == 4
                  ? 17
                  : 1;
      for (var i = 0; i < numColors; ++i) {
        final g = i * to8bit;
        palette.setRgba(i, g, g, g, 255);
      }
      for (var i = 0; i < nt; i += 2) {
        final ti = ((t[i] & 0xff) << 8) | (t[i + 1] & 0xff);
        if (ti < numColors) {
          palette.set(ti, 3, 0);
        }
      }
    }

    final format = _info.bits == 1
        ? Format.uint1
        : _info.bits == 2
            ? Format.uint2
            : _info.bits == 4
                ? Format.uint4
                : _info.bits == 16
                    ? Format.uint16
                    : Format.uint8;

    if (_info.colorType == PngColorType.grayscale &&
        _info.transparency != null &&
        _info.bits > 8) {
      numChannels = 4;
    }

    if (_info.colorType == PngColorType.rgb && _info.transparency != null) {
      numChannels = 4;
    }

    final image = Image(
        width: width,
        height: height,
        numChannels: numChannels,
        palette: palette,
        format: format);

    final origW = _info.width;
    final origH = _info.height;
    _info
      ..width = width
      ..height = height;

    final w = width;
    final h = height;
    _progressY = 0;
    try {
      if (_info.interlaceMethod != 0) {
        _processPass(input, image, 0, 0, 8, 8, (w + 7) >> 3, (h + 7) >> 3);
        _processPass(input, image, 4, 0, 8, 8, (w + 3) >> 3, (h + 7) >> 3);
        _processPass(input, image, 0, 4, 4, 8, (w + 3) >> 2, (h + 3) >> 3);
        _processPass(input, image, 2, 0, 4, 4, (w + 1) >> 2, (h + 3) >> 2);
        _processPass(input, image, 0, 2, 2, 4, (w + 1) >> 1, (h + 1) >> 2);
        _processPass(input, image, 1, 0, 2, 2, w >> 1, (h + 1) >> 1);
        _processPass(input, image, 0, 1, 1, 2, w, h >> 1);
      } else {
        _process(input, image);
      }
    } on ArchiveException {
      // Invalid compressed data.
      return null;
    } on FormatException {
      // Invalid compressed data, from the platform's zlib.
      return null;
    } on _TruncatedData {
      return null;
    } finally {
      input.closeSync();
      _info
        ..width = origW
        ..height = origH;
    }

    if (_info.iccpData != null) {
      image.iccProfile = IccProfile(
          _info.iccpName, IccProfileCompression.deflate, _info.iccpData!);
    }

    if (_info.textData.isNotEmpty) {
      image.addTextData(_info.textData);
    }

    return image;
  }

  @override
  Image? decode(Uint8List bytes, {int? frame}) =>
      guardDecode(() => _decode(bytes, frame: frame));

  Image? _decode(Uint8List bytes, {int? frame}) {
    if (startDecode(bytes) == null) {
      return null;
    }

    if (!_info.isAnimated || frame != null) {
      return decodeFrame(frame ?? 0);
    }

    Image? firstImage;
    Image? lastImage;
    final budget = PixelBudget(maxPixels);
    final numFrames = min(_info.numFrames, _info.frames.length);
    for (var i = 0; i < numFrames; ++i) {
      final frame = _info.frames[i];
      final image = decodeFrame(i);
      if (image == null) {
        continue;
      }
      budget.add(_info.width, _info.height);

      if (firstImage == null || lastImage == null) {
        firstImage = image.convert(numChannels: image.numChannels);
        lastImage = firstImage
          // Convert to MS
          ..frameDuration = (frame.delay * 1000).toInt();
        continue;
      }

      final prevFrame = _info.frames[i - 1];

      if (image.width == lastImage.width &&
          image.height == lastImage.height &&
          frame.xOffset == 0 &&
          frame.yOffset == 0 &&
          frame.blend == PngBlendMode.source) {
        lastImage = image
          // Convert to MS
          ..frameDuration = (frame.delay * 1000).toInt();
        firstImage.addFrame(lastImage);
        continue;
      }

      lastImage = Image.from(firstImage.getFrame(i - 1));

      final dispose = prevFrame.dispose;
      if (dispose == PngDisposeMode.background) {
        fillRect(lastImage,
            x1: prevFrame.xOffset,
            y1: prevFrame.yOffset,
            x2: prevFrame.xOffset + prevFrame.width - 1,
            y2: prevFrame.yOffset + prevFrame.height - 1,
            color: _info.backgroundColor ?? ColorRgba8(0, 0, 0, 0),
            alphaBlend: false);
      } else if (dispose == PngDisposeMode.previous && i > 1) {
        final prevImage = firstImage.getFrame(i - 2);
        lastImage = compositeImage(lastImage, prevImage,
            dstX: prevFrame.xOffset,
            dstY: prevFrame.yOffset,
            dstW: prevFrame.width,
            dstH: prevFrame.height,
            srcX: prevFrame.xOffset,
            srcY: prevFrame.yOffset,
            srcW: prevFrame.width,
            srcH: prevFrame.height);
      }

      // Convert to MS
      lastImage.frameDuration = (frame.delay * 1000).toInt();

      lastImage = compositeImage(lastImage, image,
          dstX: frame.xOffset,
          dstY: frame.yOffset,
          blend: frame.blend == PngBlendMode.over
              ? BlendMode.alpha
              : BlendMode.direct);

      firstImage.addFrame(lastImage);
    }

    return firstImage;
  }

  // The number of channels in the PNG data.
  int get _pngChannels => (_info.colorType == PngColorType.grayscaleAlpha)
      ? 2
      : (_info.colorType == PngColorType.rgb)
          ? 3
          : (_info.colorType == PngColorType.rgba)
              ? 4
              : 1;

  // Process a pass of an interlaced image.
  void _processPass(InputStream input, Image image, int xOffset, int yOffset,
      int xStep, int yStep, int passWidth, int passHeight) {
    // An image less than 5 pixels wide or high has empty passes. No filter
    // type bytes are present in an empty pass, so there is nothing to read.
    if (passWidth == 0 || passHeight == 0) {
      return;
    }

    final pixelDepth = _pngChannels * _info.bits;
    final bpp = (pixelDepth + 7) >> 3;
    final rowBytes = (pixelDepth * passWidth + 7) >> 3;
    final writeRows = _info.bits == 8 || _info.bits == 16;

    final pixel = [0, 0, 0, 0];
    Pixel? p;
    Uint8List? prevRow;

    for (var srcY = 0, dstY = yOffset;
        srcY < passHeight;
        ++srcY, dstY += yStep, _progressY++) {
      final filterType = PngFilterType.values[input.readByte()];
      final row = input.readBytes(rowBytes).toUint8List();
      if (row.length != rowBytes) {
        throw const _TruncatedData();
      }

      // Before the image is compressed, it was filtered to improve compression.
      // Reverse the filter now.
      _unfilter(filterType, bpp, row, prevRow);
      prevRow = row;

      if (writeRows) {
        _writeRow(row, image, dstY, xOffset, xStep, passWidth);
        continue;
      }

      // Scanlines are always on byte boundaries, so for bit depths < 8,
      // reset the bit stream counter.
      _resetBits();

      final rowInput = InputBuffer(row, bigEndian: true);
      for (var srcX = 0, dstX = xOffset;
          srcX < passWidth;
          ++srcX, dstX += xStep) {
        _readPixel(rowInput, pixel);
        p = image.getPixel(dstX, dstY, p);
        _setPixel(p, pixel);
      }
    }
  }

  void _process(InputStream input, Image image) {
    final pixelDepth = _pngChannels * _info.bits;

    final w = _info.width;
    final h = _info.height;

    final rowBytes = (w * pixelDepth + 7) >> 3;
    final bpp = (pixelDepth + 7) >> 3;
    final writeRows = _info.bits == 8 || _info.bits == 16;

    final pixel = [0, 0, 0, 0];
    Uint8List? prevRow;

    final pIter = image.iterator..moveNext();
    for (var y = 0; y < h; ++y) {
      final filterType = PngFilterType.values[input.readByte()];
      final row = input.readBytes(rowBytes).toUint8List();
      if (row.length != rowBytes) {
        throw const _TruncatedData();
      }

      // Before the image is compressed, it was filtered to improve compression.
      // Reverse the filter now.
      _unfilter(filterType, bpp, row, prevRow);
      prevRow = row;

      if (writeRows) {
        _writeRow(row, image, y, 0, 1, w);
        continue;
      }

      // Scanlines are always on byte boundaries, so for bit depths < 8,
      // reset the bit stream counter.
      _resetBits();

      final rowInput = InputBuffer(row, bigEndian: true);
      for (var x = 0; x < w; ++x) {
        _readPixel(rowInput, pixel);
        _setPixel(pIter.current, pixel);
        pIter.moveNext();
      }
    }
  }

  // Write the [n] pixels of an unfiltered 8 or 16-bit [row] to [image], at
  // (x0 + i * xStep, y).
  void _writeRow(Uint8List row, Image image, int y, int x0, int xStep, int n) {
    final pc = _pngChannels;
    // The channels stored in the image data; for a palette image, the index.
    final ic = image.data!.numChannels;
    final t = _info.transparency;

    if (_info.bits == 8) {
      final data = image.data!.toUint8List();
      var di = y * image.data!.rowStride + x0 * ic;
      final dStep = xStep * ic;
      if (ic == pc) {
        if (xStep == 1) {
          data.setRange(di, di + n * pc, row);
          return;
        }
        for (var i = 0, si = 0; i < n; ++i, di += dStep) {
          for (var c = 0; c < pc; ++c) {
            data[di + c] = row[si++];
          }
        }
        return;
      }
      // RGB with a tRNS color, expanded to RGBA.
      final tr = ((t![0] & 0xff) << 8) | (t[1] & 0xff);
      final tg = ((t[2] & 0xff) << 8) | (t[3] & 0xff);
      final tb = ((t[4] & 0xff) << 8) | (t[5] & 0xff);
      for (var i = 0, si = 0; i < n; ++i, si += 3, di += dStep) {
        final r = row[si];
        final g = row[si + 1];
        final b = row[si + 2];
        data[di] = r;
        data[di + 1] = g;
        data[di + 2] = b;
        data[di + 3] = r == tr && g == tg && b == tb ? 0 : 255;
      }
      return;
    }

    // 16-bit samples are big-endian.
    final data = (image.data! as ImageDataUint16).data;
    var di = (y * image.width + x0) * ic;
    final dStep = xStep * ic;
    if (ic == pc) {
      for (var i = 0, si = 0; i < n; ++i, di += dStep) {
        for (var c = 0; c < pc; ++c, si += 2) {
          data[di + c] = (row[si] << 8) | row[si + 1];
        }
      }
    } else if (pc == 3) {
      // RGB with a tRNS color, expanded to RGBA.
      final tr = ((t![0] & 0xff) << 8) | (t[1] & 0xff);
      final tg = ((t[2] & 0xff) << 8) | (t[3] & 0xff);
      final tb = ((t[4] & 0xff) << 8) | (t[5] & 0xff);
      for (var i = 0, si = 0; i < n; ++i, si += 6, di += dStep) {
        final r = (row[si] << 8) | row[si + 1];
        final g = (row[si + 2] << 8) | row[si + 3];
        final b = (row[si + 4] << 8) | row[si + 5];
        data[di] = r;
        data[di + 1] = g;
        data[di + 2] = b;
        data[di + 3] = r == tr && g == tg && b == tb ? 0 : 0xffff;
      }
    } else {
      // Grayscale with a tRNS value, expanded to RGBA.
      final tg = ((t![0] & 0xff) << 8) | (t[1] & 0xff);
      for (var i = 0, si = 0; i < n; ++i, si += 2, di += dStep) {
        final g = (row[si] << 8) | row[si + 1];
        data[di] = g;
        data[di + 1] = g;
        data[di + 2] = g;
        data[di + 3] = g == tg ? 0 : 0xffff;
      }
    }
  }

  void _unfilter(
      PngFilterType filterType, int bpp, Uint8List row, Uint8List? prevRow) {
    final rowBytes = row.length;
    final n = bpp < rowBytes ? bpp : rowBytes;

    switch (filterType) {
      case PngFilterType.none:
        break;
      case PngFilterType.sub:
        for (var x = bpp; x < rowBytes; ++x) {
          row[x] = row[x] + row[x - bpp];
        }
        break;
      case PngFilterType.up:
        if (prevRow != null) {
          for (var x = 0; x < rowBytes; ++x) {
            row[x] = row[x] + prevRow[x];
          }
        }
        break;
      case PngFilterType.average:
        if (prevRow == null) {
          for (var x = bpp; x < rowBytes; ++x) {
            row[x] = row[x] + (row[x - bpp] >> 1);
          }
        } else {
          for (var x = 0; x < n; ++x) {
            row[x] = row[x] + (prevRow[x] >> 1);
          }
          for (var x = bpp; x < rowBytes; ++x) {
            row[x] = row[x] + ((row[x - bpp] + prevRow[x]) >> 1);
          }
        }
        break;
      case PngFilterType.paeth:
        if (prevRow == null) {
          // With no previous row, the predictor is always the left byte.
          for (var x = bpp; x < rowBytes; ++x) {
            row[x] = row[x] + row[x - bpp];
          }
        } else {
          // With no left byte, the predictor is always the byte above.
          for (var x = 0; x < n; ++x) {
            row[x] = row[x] + prevRow[x];
          }
          for (var x = bpp; x < rowBytes; ++x) {
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
            row[x] = row[x] + (pa <= pb && pa <= pc ? a : (pb <= pc ? b : c));
          }
        }
        break;
    }
  }

  // Return the CRC of the bytes
  int _crc(String type, List<int> bytes) {
    final crc = getCrc32(type.codeUnits);
    return getCrc32(bytes, crc);
  }

  int _bitBuffer = 0;
  int _bitBufferLen = 0;

  void _resetBits() {
    _bitBuffer = 0;
    _bitBufferLen = 0;
  }

  // Read a number of bits from the input stream.
  int _readBits(InputBuffer input, int numBits) {
    if (numBits == 0) {
      return 0;
    }

    if (numBits == 8) {
      return input.readByte();
    }

    if (numBits == 16) {
      return input.readUint16();
    }

    // not enough buffer
    while (_bitBufferLen < numBits) {
      if (input.isEOS) {
        throw ImageException('Invalid PNG data.');
      }

      // input byte
      final octet = input.readByte();

      // concat octet
      _bitBuffer = octet << _bitBufferLen;
      _bitBufferLen += 8;
    }

    // output byte
    final mask = (numBits == 1)
        ? 1
        : (numBits == 2)
            ? 3
            : (numBits == 4)
                ? 0xf
                : (numBits == 8)
                    ? 0xff
                    : (numBits == 16)
                        ? 0xffff
                        : 0;

    final octet = (_bitBuffer >> (_bitBufferLen - numBits)) & mask;

    _bitBufferLen -= numBits;

    return octet;
  }

  // Read the next pixel from the input stream.
  void _readPixel(InputBuffer input, List<int> pixel) {
    switch (_info.colorType) {
      case PngColorType.grayscale:
        pixel[0] = _readBits(input, _info.bits);
        return;
      case PngColorType.rgb:
        pixel[0] = _readBits(input, _info.bits);
        pixel[1] = _readBits(input, _info.bits);
        pixel[2] = _readBits(input, _info.bits);
        return;
      case PngColorType.indexed:
        pixel[0] = _readBits(input, _info.bits);
        return;
      case PngColorType.grayscaleAlpha:
        pixel[0] = _readBits(input, _info.bits);
        pixel[1] = _readBits(input, _info.bits);
        return;
      case PngColorType.rgba:
        pixel[0] = _readBits(input, _info.bits);
        pixel[1] = _readBits(input, _info.bits);
        pixel[2] = _readBits(input, _info.bits);
        pixel[3] = _readBits(input, _info.bits);
        return;
    }

    throw ImageException('Invalid color type: ${_info.colorType}.');
  }

  // Get the color with the list of components.
  void _setPixel(Pixel p, List<int> raw) {
    switch (_info.colorType) {
      case PngColorType.grayscale:
        if (_info.transparency != null && _info.bits > 8) {
          final t = _info.transparency!;
          final a = ((t[0] & 0xff) << 8) | (t[1] & 0xff);
          final g = raw[0];
          p.setRgba(g, g, g, g != a ? p.maxChannelValue : 0);
          return;
        }
        p.setRgb(raw[0], 0, 0);
        return;
      case PngColorType.rgb:
        final r = raw[0];
        final g = raw[1];
        final b = raw[2];

        if (_info.transparency != null) {
          final t = _info.transparency!;
          final tr = ((t[0] & 0xff) << 8) | (t[1] & 0xff);
          final tg = ((t[2] & 0xff) << 8) | (t[3] & 0xff);
          final tb = ((t[4] & 0xff) << 8) | (t[5] & 0xff);
          if (raw[0] != tr || raw[1] != tg || raw[2] != tb) {
            p.setRgba(r, g, b, p.maxChannelValue);
            return;
          }
        }

        p.setRgb(r, g, b);
        return;
      case PngColorType.indexed:
        p.index = raw[0];
        return;
      case PngColorType.grayscaleAlpha:
        p.setRgba(raw[0], 0, 0, raw[1]);
        return;
      case PngColorType.rgba:
        p.setRgba(raw[0], raw[1], raw[2], raw[3]);
        return;
    }

    throw ImageException('Invalid color type: ${_info.colorType}.');
  }

  late InputBuffer _input;
  int _progressY = 0;
}

// Thrown when the decompressed image data ends before the last row.
class _TruncatedData implements Exception {
  const _TruncatedData();
}
