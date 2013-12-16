part of dart_image;

/**
 * Encode an image to the JPEG format.
 *
 * Derived from:
 * https://github.com/owencm/javascript-jpeg-encoder
 */
class JpegEncoder {
  JpegEncoder([int quality = 100]) {
    _initHuffmanTbl();
    _initCategoryNumber();
    _initRGBYUVTable();
    setQuality(quality);
  }

  void setQuality(int quality) {
    quality = quality.clamp(0, 100);

    if (currentQuality == quality) {
      return; // don't recalc if unchanged
    }

    int sf = 0;
    if (quality < 50) {
      sf = (5000 / quality).floor();
    } else {
      sf = (200 - quality * 2).floor();
    }

    _initQuantTables(sf);
    currentQuality = quality;
  }

  List<int> encode(Image image) {
    _ByteBuffer out = new _ByteBuffer();

    // Add JPEG headers
    out.writeUint16(0xFFD8); // SOI
    _writeAPP0(out);
    _writeDQT(out);
    _writeSOF0(out, image.width, image.height);
    _writeDHT(out);
    _writeSOS(out);

    // Encode 8x8 macroblocks
    int DCY = 0;
    int DCU = 0;
    int DCV = 0;

    out.resetBits();

    int width = image.width;
    int height = image.height;

    int y = 0;
    while (y < height) {
      int sx = width * y;
      int x = 0;
      while (x < width) {
        int start = sx + x;
        for (int pos = 0; pos < 64; pos++) {
          int row = pos >> 3; // / 8
          int col = (pos & 7); // % 8

          int x2 = x + col;
          if (x2 >= width) {
            x2 = (x + col) - width;
          }

          int y2 = y + row;
          if (y2 >= height) {
            y2 = (y + row) - height;
          }

          int c = image.getPixel(x2, y2);
          int r = red(c);
          int g = green(c);
          int b = blue(c);

          // calculate YUV values
          YDU[pos] = ((RGB_YUV_TABLE[r] +
                       RGB_YUV_TABLE[(g +  256)] +
                       RGB_YUV_TABLE[(b +  512)]) >> 16) - 128.0;

          UDU[pos] = ((RGB_YUV_TABLE[(r +  768)] +
                       RGB_YUV_TABLE[(g + 1024)] +
                       RGB_YUV_TABLE[(b + 1280)]) >> 16) - 128.0;

          VDU[pos] = ((RGB_YUV_TABLE[(r + 1280)] +
                       RGB_YUV_TABLE[(g + 1536)] +
                       RGB_YUV_TABLE[(b + 1792)]) >> 16) - 128.0;
        }

        DCY = _processDU(out, YDU, fdtbl_Y, DCY, YDC_HT, YAC_HT);
        DCU = _processDU(out, UDU, fdtbl_UV, DCU, UVDC_HT, UVAC_HT);
        DCV = _processDU(out, VDU, fdtbl_UV, DCV, UVDC_HT, UVAC_HT);

        x += 8;
      }

      y += 8;
    }

    ////////////////////////////////////////////////////////////////

    // Do the bit alignment of the EOI marker
    if (out._bytepos >= 0) {
      final fillbits = [(1 << (out._bytepos + 1)) - 1,
                        out._bytepos + 1];
      out.writeBits(fillbits);
    }

    out.writeUint16(0xFFD9); //EOI

    return out.buffer;
  }

  final YTable = new List(64);
  final UVTable = new List(64);
  final fdtbl_Y = new List(64);
  final fdtbl_UV = new List(64);
  List YDC_HT;
  List UVDC_HT;
  List YAC_HT;
  List UVAC_HT;

  final bitcode = new List(65535);
  final category = new List(65535);
  final outputfDCTQuant = new List<int>(64);
  final DU = new List(64);

  final List<double> YDU = new List<double>(64);
  final List<double> UDU = new List<double>(64);
  final List<double> VDU = new List<double>(64);
  final charLookupTable = new List(256);
  final RGB_YUV_TABLE = new List(2048);
  int currentQuality;

  static const List<int> ZigZag = const [
      0, 1, 5, 6, 14, 15, 27, 28,
      2, 4, 7, 13, 16, 26, 29, 42,
      3, 8, 12, 17, 25, 30, 41, 43,
      9, 11, 18, 24, 31, 40, 44, 53,
      10, 19, 23, 32, 39, 45, 52, 54,
      20, 22, 33, 38, 46, 51, 55, 60,
      21, 34, 37, 47, 50, 56, 59, 61,
      35, 36, 48, 49, 57, 58, 62, 63 ];

  static const List<int> std_dc_luminance_nrcodes = const [
      0, 0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0 ];

  static const List<int> std_dc_luminance_values = const [
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 ];

  static const List<int> std_ac_luminance_nrcodes = const [
      0, 0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 0x7d ];

  static const List<int> std_ac_luminance_values = const [
      0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12,
      0x21, 0x31, 0x41, 0x06, 0x13, 0x51, 0x61, 0x07,
      0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xa1, 0x08,
      0x23, 0x42, 0xb1, 0xc1, 0x15, 0x52, 0xd1, 0xf0,
      0x24, 0x33, 0x62, 0x72, 0x82, 0x09, 0x0a, 0x16,
      0x17, 0x18, 0x19, 0x1a, 0x25, 0x26, 0x27, 0x28,
      0x29, 0x2a, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
      0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49,
      0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
      0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
      0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79,
      0x7a, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
      0x8a, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98,
      0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7,
      0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6,
      0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3, 0xc4, 0xc5,
      0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2, 0xd3, 0xd4,
      0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xe1, 0xe2,
      0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea,
      0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8,
      0xf9, 0xfa ];

  static const List<int> std_dc_chrominance_nrcodes = const [
      0, 0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0 ];

  static const List<int> std_dc_chrominance_values = const [
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 ];

  static const List<int> std_ac_chrominance_nrcodes = const [
      0, 0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 0x77 ];

  static const List<int> std_ac_chrominance_values = const [
      0x00, 0x01, 0x02, 0x03, 0x11, 0x04, 0x05, 0x21,
      0x31, 0x06, 0x12, 0x41, 0x51, 0x07, 0x61, 0x71,
      0x13, 0x22, 0x32, 0x81, 0x08, 0x14, 0x42, 0x91,
      0xa1, 0xb1, 0xc1, 0x09, 0x23, 0x33, 0x52, 0xf0,
      0x15, 0x62, 0x72, 0xd1, 0x0a, 0x16, 0x24, 0x34,
      0xe1, 0x25, 0xf1, 0x17, 0x18, 0x19, 0x1a, 0x26,
      0x27, 0x28, 0x29, 0x2a, 0x35, 0x36, 0x37, 0x38,
      0x39, 0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,
      0x49, 0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58,
      0x59, 0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68,
      0x69, 0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78,
      0x79, 0x7a, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
      0x88, 0x89, 0x8a, 0x92, 0x93, 0x94, 0x95, 0x96,
      0x97, 0x98, 0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5,
      0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4,
      0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3,
      0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2,
      0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda,
      0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9,
      0xea, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8,
      0xf9, 0xfa ];

  void _initQuantTables(int sf) {
    const List<int> YQT = const [
        16, 11, 10, 16, 24, 40, 51, 61,
        12, 12, 14, 19, 26, 58, 60, 55,
        14, 13, 16, 24, 40, 57, 69, 56,
        14, 17, 22, 29, 51, 87, 80, 62,
        18, 22, 37, 56, 68,109,103, 77,
        24, 35, 55, 64, 81,104,113, 92,
        49, 64, 78, 87,103,121,120,101,
        72, 92, 95, 98,112,100,103, 99 ];

    for (int i = 0; i < 64; i++) {
      int t = ((YQT[i] * sf + 50) / 100).floor();
      if (t < 1) {
        t = 1;
      } else if (t > 255) {
        t = 255;
      }
      YTable[ZigZag[i]] = t;
    }

    const List<int> UVQT = const [
        17, 18, 24, 47, 99, 99, 99, 99,
        18, 21, 26, 66, 99, 99, 99, 99,
        24, 26, 56, 99, 99, 99, 99, 99,
        47, 66, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99 ];

    for (int j = 0; j < 64; j++) {
      int u = ((UVQT[j] * sf + 50) / 100).floor();
      if (u < 1) {
        u = 1;
      } else if (u > 255) {
        u = 255;
      }
      UVTable[ZigZag[j]] = u;
    }

    const List<double> aasf = const [
        1.0, 1.387039845, 1.306562965, 1.175875602,
        1.0, 0.785694958, 0.541196100, 0.275899379 ];

    int k = 0;
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        fdtbl_Y[k] = (1.0 / (YTable [ZigZag[k]] * aasf[row] * aasf[col] * 8.0));
        fdtbl_UV[k] = (1.0 / (UVTable[ZigZag[k]] * aasf[row] * aasf[col] * 8.0));
        k++;
      }
    }
  }

  List _computeHuffmanTbl(List nrcodes, List std_table) {
    int codevalue = 0;
    int pos_in_table = 0;
    List HT = new List();
    for (int k = 1; k <= 16; k++) {
      for (int j = 1; j <= nrcodes[k]; j++) {
        int index = std_table[pos_in_table];
        if (HT.length <= index) {
          HT.length = index + 1;
        }
        HT[index] = [codevalue, k];
        pos_in_table++;
        codevalue++;
      }
      codevalue *= 2;
    }
    return HT;
  }

  void _initHuffmanTbl() {
    YDC_HT = _computeHuffmanTbl(std_dc_luminance_nrcodes,
                                std_dc_luminance_values);
    UVDC_HT = _computeHuffmanTbl(std_dc_chrominance_nrcodes,
                                 std_dc_chrominance_values);
    YAC_HT = _computeHuffmanTbl(std_ac_luminance_nrcodes,
                                std_ac_luminance_values);
    UVAC_HT = _computeHuffmanTbl(std_ac_chrominance_nrcodes,
                                 std_ac_chrominance_values);
  }

  void _initCategoryNumber() {
    int nrlower = 1;
    int nrupper = 2;
    for (int cat = 1; cat <= 15; cat++) {
      // Positive numbers
      for (int nr = nrlower; nr < nrupper; nr++) {
        category[32767 + nr] = cat;
        bitcode[32767 + nr] = [nr, cat];
      }
      // Negative numbers
      for (int nrneg = -(nrupper-1); nrneg <= -nrlower; nrneg++) {
        category[32767 + nrneg] = cat;
        bitcode[32767 + nrneg] = [nrupper - 1 + nrneg, cat];
      }
      nrlower <<= 1;
      nrupper <<= 1;
    }
  }

  void _initRGBYUVTable() {
    for (int i = 0; i < 256; i++) {
      RGB_YUV_TABLE[i] = 19595 * i;
      RGB_YUV_TABLE[(i + 256)] = 38470 * i;
      RGB_YUV_TABLE[(i + 512)] = 7471 * i + 0x8000;
      RGB_YUV_TABLE[(i + 768)] = -11059 * i;
      RGB_YUV_TABLE[(i + 1024)] = -21709 * i;
      RGB_YUV_TABLE[(i + 1280)] =  32768 * i + 0x807FFF;
      RGB_YUV_TABLE[(i + 1536)] = -27439 * i;
      RGB_YUV_TABLE[(i + 1792)] = -5329 * i;
    }
  }

  // DCT & quantization core
  List<int> _fDCTQuant(List<double> data, List<double> fdtbl) {
    // Pass 1: process rows.
    int dataOff = 0;
    const I8 = 8;
    const I64 = 64;
    for (int i = 0; i < I8; ++i) {
      double d0 = data[dataOff];
      double d1 = data[dataOff + 1];
      double d2 = data[dataOff + 2];
      double d3 = data[dataOff + 3];
      double d4 = data[dataOff + 4];
      double d5 = data[dataOff + 5];
      double d6 = data[dataOff + 6];
      double d7 = data[dataOff + 7];

      double tmp0 = d0 + d7;
      double tmp7 = d0 - d7;
      double tmp1 = d1 + d6;
      double tmp6 = d1 - d6;
      double tmp2 = d2 + d5;
      double tmp5 = d2 - d5;
      double tmp3 = d3 + d4;
      double tmp4 = d3 - d4;

      // Even part
      double tmp10 = tmp0 + tmp3; // phase 2
      double tmp13 = tmp0 - tmp3;
      double tmp11 = tmp1 + tmp2;
      double tmp12 = tmp1 - tmp2;

      data[dataOff] = tmp10 + tmp11; // phase 3
      data[dataOff + 4] = tmp10 - tmp11;

      double z1 = (tmp12 + tmp13) * 0.707106781; // c4
      data[dataOff + 2] = tmp13 + z1; // phase 5
      data[dataOff + 6] = tmp13 - z1;

      // Odd part
      tmp10 = tmp4 + tmp5; // phase 2
      tmp11 = tmp5 + tmp6;
      tmp12 = tmp6 + tmp7;

      // The rotator is modified from fig 4-8 to avoid extra negations.
      double z5 = (tmp10 - tmp12) * 0.382683433; // c6
      double z2 = 0.541196100 * tmp10 + z5; // c2 - c6
      double z4 = 1.306562965 * tmp12 + z5; // c2 + c6
      double z3 = tmp11 * 0.707106781; // c4

      double z11 = tmp7 + z3; // phase 5
      double z13 = tmp7 - z3;

      data[dataOff + 5] = z13 + z2; // phase 6
      data[dataOff + 3] = z13 - z2;
      data[dataOff + 1] = z11 + z4;
      data[dataOff + 7] = z11 - z4;

      dataOff += 8; // advance pointer to next row
    }

    // Pass 2: process columns.
    dataOff = 0;
    for (int i = 0; i < I8; ++i) {
      double d0 = data[dataOff];
      double d1 = data[dataOff + 8];
      double d2 = data[dataOff + 16];
      double d3 = data[dataOff + 24];
      double d4 = data[dataOff + 32];
      double d5 = data[dataOff + 40];
      double d6 = data[dataOff + 48];
      double d7 = data[dataOff + 56];

      double tmp0p2 = d0 + d7;
      double tmp7p2 = d0 - d7;
      double tmp1p2 = d1 + d6;
      double tmp6p2 = d1 - d6;
      double tmp2p2 = d2 + d5;
      double tmp5p2 = d2 - d5;
      double tmp3p2 = d3 + d4;
      double tmp4p2 = d3 - d4;

      // Even part
      double tmp10p2 = tmp0p2 + tmp3p2;        // phase 2
      double tmp13p2 = tmp0p2 - tmp3p2;
      double tmp11p2 = tmp1p2 + tmp2p2;
      double tmp12p2 = tmp1p2 - tmp2p2;

      data[dataOff] = tmp10p2 + tmp11p2; // phase 3
      data[dataOff + 32] = tmp10p2 - tmp11p2;

      double z1p2 = (tmp12p2 + tmp13p2) * 0.707106781; // c4
      data[dataOff + 16] = tmp13p2 + z1p2; // phase 5
      data[dataOff + 48] = tmp13p2 - z1p2;

      // Odd part
      tmp10p2 = tmp4p2 + tmp5p2; // phase 2
      tmp11p2 = tmp5p2 + tmp6p2;
      tmp12p2 = tmp6p2 + tmp7p2;

      // The rotator is modified from fig 4-8 to avoid extra negations.
      double z5p2 = (tmp10p2 - tmp12p2) * 0.382683433; // c6
      double z2p2 = 0.541196100 * tmp10p2 + z5p2; // c2 - c6
      double z4p2 = 1.306562965 * tmp12p2 + z5p2; // c2 + c6
      double z3p2 = tmp11p2 * 0.707106781; // c4

      double z11p2 = tmp7p2 + z3p2;        // phase 5
      double z13p2 = tmp7p2 - z3p2;

      data[dataOff + 40] = z13p2 + z2p2; // phase 6
      data[dataOff + 24] = z13p2 - z2p2;
      data[dataOff + 8] = z11p2 + z4p2;
      data[dataOff + 56] = z11p2 - z4p2;

      dataOff++; // advance pointer to next column
    }

    // Quantize/descale the coefficients
    for (int i = 0; i < I64; ++i) {
      // Apply the quantization and scaling factor & Round to nearest integer
      double fDCTQuant = data[i] * fdtbl[i];
      outputfDCTQuant[i] = (fDCTQuant > 0.0) ?
                           ((fDCTQuant + 0.5).floor()) :
                           ((fDCTQuant - 0.5).floor());
    }

    return outputfDCTQuant;
  }

  void _writeAPP0(_ByteBuffer out) {
    out.writeUint16(0xFFE0); // marker
    out.writeUint16(16); // length
    out.writeByte(0x4A); // J
    out.writeByte(0x46); // F
    out.writeByte(0x49); // I
    out.writeByte(0x46); // F
    out.writeByte(0); // = "JFIF",'\0'
    out.writeByte(1); // versionhi
    out.writeByte(1); // versionlo
    out.writeByte(0); // xyunits
    out.writeUint16(1); // xdensity
    out.writeUint16(1); // ydensity
    out.writeByte(0); // thumbnwidth
    out.writeByte(0); // thumbnheight
  }

  void _writeSOF0(_ByteBuffer out, int width, int height) {
    out.writeUint16(0xFFC0); // marker
    out.writeUint16(17);   // length, truecolor YUV JPG
    out.writeByte(8);    // precision
    out.writeUint16(height);
    out.writeUint16(width);
    out.writeByte(3);    // nrofcomponents
    out.writeByte(1);    // IdY
    out.writeByte(0x11); // HVY
    out.writeByte(0);    // QTY
    out.writeByte(2);    // IdU
    out.writeByte(0x11); // HVU
    out.writeByte(1);    // QTU
    out.writeByte(3);    // IdV
    out.writeByte(0x11); // HVV
    out.writeByte(1);    // QTV
  }

  void _writeDQT(_ByteBuffer out) {
    out.writeUint16(0xFFDB); // marker
    out.writeUint16(132); // length
    out.writeByte(0);
    for (int i = 0; i < 64; i++) {
      out.writeByte(YTable[i]);
    }
    out.writeByte(1);
    for (int j = 0; j < 64; j++) {
      out.writeByte(UVTable[j]);
    }
  }

  void _writeDHT(_ByteBuffer out) {
    out.writeUint16(0xFFC4); // marker
    out.writeUint16(0x01A2); // length

    out.writeByte(0); // HTYDCinfo
    for (int i = 0; i < 16; i++) {
      out.writeByte(std_dc_luminance_nrcodes[i + 1]);
    }
    for (int j = 0; j <= 11; j++) {
      out.writeByte(std_dc_luminance_values[j]);
    }

    out.writeByte(0x10); // HTYACinfo
    for (int k = 0; k < 16; k++) {
      out.writeByte(std_ac_luminance_nrcodes[k + 1]);
    }
    for (int l = 0; l <= 161; l++) {
      out.writeByte(std_ac_luminance_values[l]);
    }

    out.writeByte(1); // HTUDCinfo
    for (int m = 0; m < 16; m++) {
      out.writeByte(std_dc_chrominance_nrcodes[m + 1]);
    }
    for (int n = 0; n <= 11; n++) {
      out.writeByte(std_dc_chrominance_values[n]);
    }

    out.writeByte(0x11); // HTUACinfo
    for (int o = 0; o < 16; o++) {
      out.writeByte(std_ac_chrominance_nrcodes[o + 1]);
    }
    for (int p = 0; p <= 161; p++) {
      out.writeByte(std_ac_chrominance_values[p]);
    }
  }

  _writeSOS(_ByteBuffer out) {
    out.writeUint16(0xFFDA); // marker
    out.writeUint16(12); // length
    out.writeByte(3); // nrofcomponents
    out.writeByte(1); // IdY
    out.writeByte(0); // HTY
    out.writeByte(2); // IdU
    out.writeByte(0x11); // HTU
    out.writeByte(3); // IdV
    out.writeByte(0x11); // HTV
    out.writeByte(0); // Ss
    out.writeByte(0x3f); // Se
    out.writeByte(0); // Bf
  }

  int _processDU(_ByteBuffer out, List<double> CDU, List<double> fdtbl,
                 int DC, HTDC, HTAC) {
    List EOB = HTAC[0x00];
    List M16zeroes = HTAC[0xF0];
    int pos;
    const I16 = 16;
    const I63 = 63;
    const I64 = 64;
    List DU_DCT = _fDCTQuant(CDU, fdtbl);

    // ZigZag reorder
    for (int j = 0; j < I64; ++j) {
      DU[ZigZag[j]] = DU_DCT[j];
    }

    int Diff = DU[0] - DC;
    DC = DU[0];
    // Encode DC
    if (Diff == 0) {
      out.writeBits(HTDC[0]); // Diff might be 0
    } else {
      pos = 32767 + Diff;
      out.writeBits(HTDC[category[pos]]);
      out.writeBits(bitcode[pos]);
    }

    // Encode ACs
    int end0pos = 63;
    for (; (end0pos > 0) && (DU[end0pos] == 0); end0pos--) {};
    //end0pos = first element in reverse order !=0
    if ( end0pos == 0) {
      out.writeBits(EOB);
      return DC;
    }

    int i = 1;
    int lng;
    while (i <= end0pos) {
      int startpos = i;
      for (; (DU[i] == 0) && (i <= end0pos); ++i);

      int nrzeroes = i - startpos;
      if (nrzeroes >= I16) {
        lng = nrzeroes >> 4;
        for (int nrmarker = 1; nrmarker <= lng; ++nrmarker) {
          out.writeBits(M16zeroes);
        }
        nrzeroes = nrzeroes & 0xF;
      }
      pos = 32767 + DU[i];
      out.writeBits(HTAC[(nrzeroes << 4) + category[pos]]);
      out.writeBits(bitcode[pos]);
      i++;
    }

    if (end0pos != I63) {
      out.writeBits(EOB);
    }

    return DC;
  }
}
