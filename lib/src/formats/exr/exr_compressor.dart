part of image;

abstract class ExrCompressor {
  static const int NATIVE = 1;
  static const int XDR = 0;

  static const int NO_COMPRESSION = 0;
  static const int RLE_COMPRESSION = 1;
  static const int ZIPS_COMPRESSION = 2;
  static const int ZIP_COMPRESSION = 3;
  static const int PIZ_COMPRESSION = 4;
  static const int PXR24_COMPRESSION = 5;
  static const int B44_COMPRESSION = 6;
  static const int B44A_COMPRESSION = 7;

  factory ExrCompressor(int type, int maxScanLineSize, ExrHeader hdr) {
    switch (type) {
      case RLE_COMPRESSION:
        return new ExrRleCompressor(hdr, maxScanLineSize);
      case ZIPS_COMPRESSION:
        return new ExrZipCompressor(hdr, maxScanLineSize, 1);
      case ZIP_COMPRESSION:
        return new ExrZipCompressor(hdr, maxScanLineSize, 16);
      case PIZ_COMPRESSION:
        return new ExrPizCompressor(hdr, maxScanLineSize, 32);
      case PXR24_COMPRESSION:
        return new ExrPxr24Compressor(hdr, maxScanLineSize, 16);
      case B44_COMPRESSION:
        return new ExrB44Compressor(hdr, maxScanLineSize, 32, false);
      case B44A_COMPRESSION:
        return new ExrB44Compressor(hdr, maxScanLineSize, 32, true);
      default:
        throw new ImageException('Invalid compression type: $type');
    }
  }

  factory ExrCompressor.tile(int type, int tileLineSize, int numTileLines,
                             ExrHeader hdr) {
    switch (type) {
      case RLE_COMPRESSION:
        return new ExrRleCompressor(hdr, (tileLineSize * numTileLines));
      case ZIPS_COMPRESSION:
      case ZIP_COMPRESSION:
        return new ExrZipCompressor(hdr, tileLineSize, numTileLines);
      case PIZ_COMPRESSION:
        return new ExrPizCompressor(hdr, tileLineSize, numTileLines);
      case PXR24_COMPRESSION:
        return new ExrPxr24Compressor(hdr, tileLineSize, numTileLines);
      case B44_COMPRESSION:
        return new ExrB44Compressor(hdr, tileLineSize, numTileLines, false);
      case B44A_COMPRESSION:
        return new ExrB44Compressor(hdr, tileLineSize, numTileLines, true);
      default:
        throw new ImageException('Invalid compression type: $type');
    }
  }

  ExrCompressor._(this._header);

  int numScanLines();

  int format() => XDR;

  Uint8List compress(InputBuffer inPtr, int minY);

  Uint8List compressTile(InputBuffer inPtr, List<int> range) {
    return compress(inPtr, range[1]);
  }

  Uint8List uncompress(InputBuffer inPtr, int minY);

  Uint8List uncompressTile(InputBuffer inPtr, List<int> range) {
    return uncompress(inPtr, range[1]);
  }

  ExrHeader _header;
}
