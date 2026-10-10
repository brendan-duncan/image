import 'dart:typed_data';

import '../image/image.dart';
import '../util/input_buffer.dart';
import '../util/output_buffer.dart';
import '_guard_decode.dart';
import '_max_pixels.dart';
import 'bmp/bmp_info.dart';
import 'bmp_decoder.dart';
import 'decode_info.dart';
import 'decoder.dart';
import 'ico/ico_info.dart';
import 'image_format.dart';
import 'png_decoder.dart';

/// Decodes an ICO formatted [Image].
/// Note that ICO files are always decoded to rgba8 32-bit Images in order
/// to support how they encode transparency.
class IcoDecoder extends Decoder {
  InputBuffer? _input;
  IcoInfo? _icoInfo;

  /// The maximum number of pixels (width * height) of an image, and of all
  /// the images of a full decode. Larger images throw an ImageException.
  /// A value <= 0 disables the limit.
  final int maxPixels;

  IcoDecoder({int? maxPixels})
      : maxPixels = maxPixels ?? Decoder.defaultMaxPixels;

  @override
  ImageFormat get format => ImageFormat.ico;

  @override
  bool isValidFile(Uint8List bytes) {
    _input = InputBuffer(bytes);
    try {
      _icoInfo = IcoInfo.read(_input!);
    } catch (_) {
      _icoInfo = null;
    }
    return _icoInfo != null;
  }

  @override
  DecodeInfo? startDecode(Uint8List bytes) =>
      guardDecode(() => _startDecode(bytes));

  DecodeInfo? _startDecode(Uint8List bytes) {
    _input = InputBuffer(bytes);
    return _icoInfo = IcoInfo.read(_input!);
  }

  @override
  Image? decode(Uint8List bytes, {int? frame}) =>
      guardDecode(() => _decode(bytes, frame: frame));

  Image? _decode(Uint8List bytes, {int? frame}) {
    final info = startDecode(bytes);
    if (info == null) {
      return null;
    }

    if (_icoInfo!.images.length == 1 || frame != null) {
      return decodeFrame(frame ?? 0);
    }

    Image? firstImage;
    final budget = PixelBudget(maxPixels);
    for (var i = 0; i < _icoInfo!.images.length; i++) {
      final frame = decodeFrame(i);
      if (frame == null) {
        continue;
      }
      budget.add(frame.width, frame.height);
      if (firstImage == null) {
        firstImage = frame..frameType = FrameType.sequence;
      } else {
        firstImage.addFrame(frame);
      }
    }

    return firstImage;
  }

  @override
  Image? decodeFrame(int frame) => guardDecode(() => _decodeFrame(frame));

  Image? _decodeFrame(int frame) {
    if (_input == null || _icoInfo == null || frame >= _icoInfo!.numFrames) {
      return null;
    }

    final imageInfo = _icoInfo!.images[frame];
    final imageBuffer = _input!.buffer.sublist(
        _input!.start + imageInfo.bytesOffset,
        _input!.start + imageInfo.bytesOffset + imageInfo.bytesSize);

    final png = PngDecoder(maxPixels: maxPixels);
    if (png.isValidFile(imageBuffer as Uint8List)) {
      return png.decode(imageBuffer, frame: 0);
    }

    // should be bmp.
    final dummyBmpHeader = OutputBuffer(size: 14)
      ..writeUint16(BmpFileHeader.signature)
      ..writeUint32(imageInfo.bytesSize)
      ..writeUint32(0)
      ..writeUint32(0);

    final bmpInfo = IcoBmpInfo(InputBuffer(imageBuffer),
        fileHeader: BmpFileHeader(InputBuffer(dummyBmpHeader.getBytes())));

    if (bmpInfo.headerSize != 40 && bmpInfo.planes != 1) {
      // invalid header.
      return null;
    }

    int offset;
    if (bmpInfo.totalColors == 0 && bmpInfo.bitsPerPixel <= 8) {
      offset = /*14 +*/ 40 + 4 * (1 << bmpInfo.bitsPerPixel);
    } else {
      offset = /*14 +*/ 40 + 4 * bmpInfo.totalColors;
    }

    bmpInfo.header.imageOffset = offset;
    dummyBmpHeader
      ..length -= 4
      ..writeUint32(offset);
    final inp = InputBuffer(imageBuffer);
    final bmp = DibDecoder(inp, bmpInfo, forceRgba: true, maxPixels: maxPixels);

    final image = bmp.decodeFrame(0);

    if (bmpInfo.bitsPerPixel >= 32) {
      return image;
    }

    final padding = 32 - bmpInfo.width % 32;
    final rowLength =
        (padding == 32 ? bmpInfo.width : bmpInfo.width + padding) ~/ 8;

    // AND bitmask
    for (var y = 0; y < bmpInfo.height; y++) {
      final line = bmpInfo.readBottomUp ? y : image.height - 1 - y;
      final row = inp.readBytes(rowLength);
      final p = image.getPixel(0, line);
      for (var x = 0; x < bmpInfo.width;) {
        final b = row.readByte();
        for (var j = 7; j > -1 && x < bmpInfo.width; j--) {
          if (b & (1 << j) != 0) {
            // set the pixel to completely transparent.
            p.a = 0;
          }
          p.moveNext();
          x++;
        }
      }
    }

    return image;
  }

  /// decodes the largest frame.
  Image? decodeImageLargest(Uint8List bytes) =>
      guardDecode(() => _decodeImageLargest(bytes));

  Image? _decodeImageLargest(Uint8List bytes) {
    final info = startDecode(bytes);
    if (info == null) {
      return null;
    }
    var largestFrame = 0;
    var largestSize = 0;
    for (var i = 0; i < _icoInfo!.images.length; i++) {
      final image = _icoInfo!.images[i];
      final size = image.width * image.height;
      if (size > largestSize) {
        largestSize = size;
        largestFrame = i;
      }
    }
    return decodeFrame(largestFrame);
  }

  @override
  int numFrames() => _icoInfo?.numFrames ?? 0;
}
