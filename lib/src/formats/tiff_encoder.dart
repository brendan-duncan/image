import 'dart:typed_data';

import '../color/format.dart';
import '../exif/exif_tag.dart';
import '../exif/ifd_value.dart';
import '../image/image.dart';
import '../util/output_buffer.dart';
import 'encoder.dart';
import 'tiff/tiff_image.dart';

/// Encode am [Image] to the TIFF format.
class TiffEncoder extends Encoder {
  @override
  Uint8List encode(Image image, {bool singleFrame = false}) {
    final out = OutputBuffer();
    _writeHeader(out);
    _writeImage(out, image);
    out.writeUint32(0); // no offset to the next image
    return out.getBytes();
  }

  void _writeHeader(OutputBuffer out) {
    out
      ..writeUint16(littleEndian) // byteOrder
      ..writeUint16(signature) // TIFF signature
      ..writeUint32(8); // Offset to the start of the IFD tags
  }

  void _writeImage(OutputBuffer out, Image image) {
    out.writeUint16(11); // number of IFD entries

    _writeEntryUint32(out, exifTagNameToID['ImageWidth']!, image.width);
    _writeEntryUint32(out, exifTagNameToID['ImageLength']!, image.height);
    _writeEntryUint16(
        out, exifTagNameToID['BitsPerSample']!, image.bitsPerChannel);
    _writeEntryUint16(
        out, exifTagNameToID['Compression']!, TiffCompression.none);
    _writeEntryUint16(
        out,
        exifTagNameToID['PhotometricInterpretation']!,
        image.numChannels == 1
            ? TiffPhotometricType.blackIsZero.index
            : TiffPhotometricType.rgb.index);
    _writeEntryUint16(
        out, exifTagNameToID['SamplesPerPixel']!, image.numChannels);
    _writeEntryUint16(
        out, exifTagNameToID['SampleFormat']!, _getSampleFormat(image).index);

    _writeEntryUint32(out, exifTagNameToID['RowsPerStrip']!, image.height);
    _writeEntryUint16(out, exifTagNameToID['PlanarConfiguration']!, 1);
    _writeEntryUint32(out, exifTagNameToID['StripByteCounts']!,
        image.width * image.height * 4);
    _writeEntryUint32(out, exifTagNameToID['StripOffsets']!, out.length + 4);
    out.writeBytes(image.toUint8List());
  }

  TiffFormat _getSampleFormat(Image image) {
    switch (image.formatType) {
      case FormatType.uint:
        return TiffFormat.uint;
      case FormatType.int:
        return TiffFormat.int;
      case FormatType.float:
        return TiffFormat.float;
    }
  }

  void _writeEntryUint16(OutputBuffer out, int tag, int data) {
    out
      ..writeUint16(tag)
      ..writeUint16(IfdValueType.short.index)
      ..writeUint32(1) // number of values
      ..writeUint16(data)
      ..writeUint16(0); // pad to 4 bytes
  }

  void _writeEntryUint32(OutputBuffer out, int tag, int data) {
    out
      ..writeUint16(tag)
      ..writeUint16(IfdValueType.long.index)
      ..writeUint32(1) // number of values
      ..writeUint32(data);
  }

  static const littleEndian = 0x4949;
  static const signature = 42;
}
