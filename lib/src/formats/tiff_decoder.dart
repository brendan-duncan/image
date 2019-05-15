import 'dart:typed_data';

import '../animation.dart';
import '../image.dart';
import '../hdr/hdr_image.dart';
import '../util/input_buffer.dart';
import 'decoder.dart';
import 'tiff/tiff_image.dart';
import 'tiff/tiff_info.dart';

class TiffDecoder extends Decoder {
  TiffInfo info;

  /// Is the given file a valid TIFF image?
  bool isValidFile(List<int> data) {
    return _readHeader(InputBuffer(data)) != null;
  }

  /// Validate the file is a Gif image and get information about it.
  /// If the file is not a valid Gif image, null is returned.
  TiffInfo startDecode(List<int> bytes) {
    _input = InputBuffer(Uint8List.fromList(bytes));
    info = _readHeader(_input);
    return info;
  }

  /// How many frames are available to be decoded. [startDecode] should have
  /// been called first. Non animated image files will have a single frame.
  int numFrames() => info != null ? info.images.length : 0;

  /// Decode a single frame from the data stat was set with [startDecode].
  /// If [frame] is out of the range of available frames, null is returned.
  /// Non animated image files will only have [frame] 0. An [AnimationFrame]
  /// is returned, which provides the image, and top-left coordinates of the
  /// image, as animated frames may only occupy a subset of the canvas.
  Image decodeFrame(int frame) {
    if (info == null) {
      return null;
    }

    return info.images[frame].decode(_input);
  }

  /// Decode the file and extract a single image from it. If the file is
  /// animated, the specified [frame] will be decoded. If there was a problem
  /// decoding the file, null is returned.
  Image decodeImage(List<int> data, {int frame = 0}) {
    InputBuffer ptr = InputBuffer(Uint8List.fromList(data));

    TiffInfo info = _readHeader(ptr);
    if (info == null) {
      return null;
    }

    return info.images[frame].decode(ptr);
  }

  HdrImage decodeHdrImage(List<int> data, {int frame = 0}) {
    InputBuffer ptr = InputBuffer(Uint8List.fromList(data));

    TiffInfo info = _readHeader(ptr);
    if (info == null) {
      return null;
    }

    return info.images[frame].decodeHdr(ptr);
  }

  /// Decode all of the frames from an animation. If the file is not an
  /// animation, a single frame animation is returned. If there was a problem
  /// decoding the file, null is returned.
  Animation decodeAnimation(List<int> data) {
    if (startDecode(data) == null) {
      return null;
    }

    Animation anim = Animation();
    anim.width = info.width;
    anim.height = info.height;
    anim.frameType = FrameType.page;
    for (int i = 0, len = numFrames(); i < len; ++i) {
      Image image = decodeFrame(i);
      if (i == null) {
        continue;
      }
      anim.addFrame(image);
    }

    return anim;
  }

  // Read the TIFF header and IFD blocks.
  TiffInfo _readHeader(InputBuffer p) {
    TiffInfo info = TiffInfo();
    int byteOrder = p.readUint16();
    if (byteOrder != TIFF_LITTLE_ENDIAN && byteOrder != TIFF_BIG_ENDIAN) {
      return null;
    }

    if (byteOrder == TIFF_BIG_ENDIAN) {
      p.bigEndian = true;
      info.bigEndian = true;
    } else {
      p.bigEndian = false;
      info.bigEndian = false;
    }

    info.signature = p.readUint16();
    if (info.signature != TIFF_SIGNATURE) {
      return null;
    }

    int offset = p.readUint32();
    info.ifdOffset = offset;

    InputBuffer p2 = InputBuffer.from(p);
    p2.offset = offset;

    while (offset != 0) {
      TiffImage img;
      try {
        img = TiffImage(p2);
        if (!img.isValid) {
          break;
        }
      } catch (error) {
        break;
      }
      info.images.add(img);
      if (info.images.length == 1) {
        info.width = info.images[0].width;
        info.height = info.images[0].height;
      }

      offset = p2.readUint32();
      if (offset != 0) {
        p2.offset = offset;
      }
    }

    return info.images.isNotEmpty ? info : null;
  }

  InputBuffer _input;

  static const int TIFF_SIGNATURE = 42;
  static const int TIFF_LITTLE_ENDIAN = 0x4949;
  static const int TIFF_BIG_ENDIAN = 0x4d4d;
}
