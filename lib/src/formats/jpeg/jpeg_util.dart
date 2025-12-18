import 'dart:typed_data';

import '../../exif/exif_data.dart';
import '../../util/input_buffer.dart';
import '../../util/output_buffer.dart';
import 'jpeg_marker.dart';

class JpegUtil {
  static const exifSignature = 0x45786966; // Exif\0\0

  ExifData? decodeExif(Uint8List jpeg) {
    final input = InputBuffer(jpeg, bigEndian: true);

    // Some other formats have embedded jpeg, or jpeg-like data.
    // Only validate if the image starts with the StartOfImage tag.
    final soiCheck = input.peekBytes(2);
    if (soiCheck[0] != 0xff || soiCheck[1] != 0xd8) {
      return null;
    }

    var marker = _nextMarker(input);
    if (marker != JpegMarker.soi) {
      return null;
    }

    ExifData? exif;
    marker = _nextMarker(input);
    while (marker != JpegMarker.eoi && !input.isEOS) {
      switch (marker) {
        case JpegMarker.app1:
          exif = _readExifData(_readBlock(input));
          if (exif != null) {
            return exif;
          }
          break;
        default:
          _skipBlock(input);
          break;
      }
      marker = _nextMarker(input);
    }

    return null;
  }

  Uint8List? injectExif(ExifData exif, Uint8List jpeg) {
    final input = InputBuffer(jpeg, bigEndian: true);

    // Some other formats have embedded jpeg, or jpeg-like data.
    // Only validate if the image starts with the StartOfImage tag.
    final soiCheck = input.peekBytes(2);
    if (soiCheck[0] != 0xff || soiCheck[1] != 0xd8) {
      return null;
    }

    final output = OutputBuffer(size: jpeg.length, bigEndian: true);

    var marker = _nextMarker(input);
    if (marker != JpegMarker.soi) {
      return null;
    }

    // Check to see if the JPEG file has an EXIF block

    var hasExifBlock = false;
    var exifBlockEndOffset = 0;
    final startOffset = input.offset;
    var exifBlockStartOffset = startOffset;
    marker = _nextMarker(input);
    while (!hasExifBlock && marker != JpegMarker.eoi && !input.isEOS) {
      if (marker == JpegMarker.app1) {
        final block = _readBlock(input);
        final signature = block?.readUint32();
        if (signature == exifSignature) {
          exifBlockEndOffset = input.offset;
          hasExifBlock = true;
          break;
        }
      } else {
        _skipBlock(input);
      }
      exifBlockStartOffset = startOffset;
      marker = _nextMarker(input);
    }

    input.offset = 0;

    // If the JPEG file does not have an EXIF block, add a new one.
    if (!hasExifBlock) {
      output.writeBuffer(input.readBytes(startOffset));
      // Write APP1 marker then the EXIF block. When there is no existing
      // APP1 segment the marker bytes won't have been written to `output`.
      _writeAPP1(output, exif);
      // No need to parse the remaining individual blocks, just write out
      // the remainder of the file.
      output.writeBuffer(input.readBytes(input.length));
      return output.getBytes();
    }

    // Write out the image file up until the exif block
    output.writeBuffer(input.readBytes(exifBlockStartOffset));
    // write the new exif block
    _writeAPP1(output, exif);
    // skip the exif block from the source
    input.offset = exifBlockEndOffset;
    // write out the remainder of the image file
    output.writeBuffer(input.readBytes(input.length));

    return output.getBytes();
  }

  ExifData? _readExifData(InputBuffer? block) {
    if (block == null) {
      return null;
    }
    // Exif Header
    final signature = block.readUint32();
    if (signature != exifSignature) {
      return null;
    }
    if (block.readUint16() != 0) {
      return null;
    }

    return ExifData.fromInputBuffer(block);
  }

  void _writeAPP1(OutputBuffer out, ExifData exif) {
    if (exif.isEmpty) {
      return;
    }

    final exifData = OutputBuffer();
    exif.write(exifData);
    final exifBytes = exifData.getBytes();

    out
      ..writeByte(0xff)
      ..writeByte(JpegMarker.app1)
      ..writeUint16(exifBytes.length + 8)
      ..writeUint32(exifSignature)
      ..writeUint16(0)
      ..writeBytes(exifBytes);
  }

  InputBuffer? _readBlock(InputBuffer input) {
    final length = input.readUint16();
    if (length < 2) {
      return null;
    }
    return input.readBytes(length - 2);
  }

  bool _skipBlock(InputBuffer input, [OutputBuffer? output]) {
    final length = input.readUint16();
    output?.writeUint16(length);
    if (length < 2) {
      return false;
    }
    if (output != null) {
      output.writeBuffer(input.readBytes(length - 2));
    } else {
      input.skip(length - 2);
    }
    return true;
  }

  int _nextMarker(InputBuffer input, [OutputBuffer? output]) {
    var c = 0;
    if (input.isEOS) {
      return c;
    }

    do {
      do {
        c = input.readByte();
        output?.writeByte(c);
      } while (c != 0xff && !input.isEOS);

      if (input.isEOS) {
        return c;
      }

      do {
        c = input.readByte();
        output?.writeByte(c);
      } while (c == 0xff && !input.isEOS);
    } while (c == 0 && !input.isEOS);

    return c;
  }
}
