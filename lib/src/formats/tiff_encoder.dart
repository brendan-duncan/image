import 'dart:typed_data';

import '../color/format.dart';
import '../exif/exif_data.dart';
import '../exif/ifd_value.dart';
import '../image/image.dart';
import '../util/output_buffer.dart';
import '_check_encode.dart';
import 'encoder.dart';
import 'tiff/tiff_image.dart';

/// Encode am [Image] to the TIFF format.
class TiffEncoder extends Encoder {
  @override
  Uint8List encode(Image image, {bool singleFrame = false}) {
    checkEncode(image);
    // TIFF is really just an EXIF structure (or, really, EXIF is just a TIFF
    // structure).

    final exif = ExifData();
    if (image.hasExif) {
      exif.imageIfd.copy(image.exif.imageIfd);
    }

    // TODO: support encoding HDR images to TIFF.
    if (image.isHdrFormat) {
      image = image.convert(format: Format.uint8);
    }

    final type = image.numChannels == 1
        ? TiffPhotometricType.blackIsZero.index
        : image.hasPalette
            ? TiffPhotometricType.palette.index
            : TiffPhotometricType.rgb.index;

    final nc = image.numChannels;

    final ifd0 = exif.imageIfd;
    ifd0['ImageWidth'] = image.width;
    ifd0['ImageHeight'] = image.height;
    ifd0['BitsPerSample'] = image.bitsPerChannel;
    ifd0['SampleFormat'] = _getSampleFormat(image).index;
    ifd0['SamplesPerPixel'] = image.hasPalette ? 1 : nc;
    ifd0['Compression'] = TiffCompression.none;
    ifd0['PhotometricInterpretation'] = type;
    ifd0['RowsPerStrip'] = image.height;
    ifd0['PlanarConfiguration'] = 1;
    // Layout and codec tags copied from the source EXIF no longer describe the
    // uncompressed strip data written here, and strict readers reject them.
    for (final tag in _staleLayoutTags) {
      ifd0[tag] = null;
    }
    if (!image.hasPalette && (nc == 2 || nc == 4)) {
      // The last channel is unassociated alpha.
      ifd0['ExtraSamples'] = 2;
    }
    ifd0['StripByteCounts'] = image.lengthInBytes;
    // The pixel data is written straight from the image, without a copy.
    ifd0['StripOffsets'] = IfdValueUndefined.view(image.toUint8List());

    if (image.hasPalette) {
      final p = image.palette!;
      // Only support RGB palettes
      const numCh = 3;
      final numC = p.numColors;
      final colorMap = Uint16List(numC * numCh);
      for (var c = 0, ci = 0; c < numCh; ++c) {
        for (var i = 0; i < numC; ++i) {
          colorMap[ci++] = p.get(i, c).toInt() << 8;
        }
      }
      ifd0['ColorMap'] = colorMap;
    }

    // The pixel data plus room for the IFD entries.
    final out = OutputBuffer(size: image.lengthInBytes + 0x2000);
    exif.write(out);

    return out.getBytes();
  }

  static const _staleLayoutTags = <Object>[
    'TileWidth',
    'TileLength',
    'TileOffsets',
    'TileByteCounts',
    'ExtraSamples',
    'ColorMap',
    'Predictor',
    'FillOrder',
    'T4Options',
    'T6Options',
    'YCbCrCoefficients',
    'YCbCrSubSampling',
    'YCbCrPositioning',
    'JPEGProc',
    'JPEGInterchangeFormat',
    'JPEGInterchangeFormatLength',
    0x014A, // SubIFDs
    0x015B, // JPEGTables
  ];

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
}
