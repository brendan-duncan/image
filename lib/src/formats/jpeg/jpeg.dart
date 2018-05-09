class Jpeg {
  static const List<int> dctZigZag = const [
      0,  1,  8, 16,  9,  2,  3, 10,
      17, 24, 32, 25, 18, 11,  4,  5,
      12, 19, 26, 33, 40, 48, 41, 34,
      27, 20, 13,  6,  7, 14, 21, 28,
      35, 42, 49, 56, 57, 50, 43, 36,
      29, 22, 15, 23, 30, 37, 44, 51,
      58, 59, 52, 45, 38, 31, 39, 46,
      53, 60, 61, 54, 47, 55, 62, 63,
      63, 63, 63, 63, 63, 63, 63, 63, // extra entries for safety in decoder
      63, 63, 63, 63, 63, 63, 63, 63 ];

  static const int DCTSIZE = 8; // The basic DCT block is 8x8 samples
  static const int DCTSIZE2 = 64;  // DCTSIZE squared; # of elements in a block
  static const int NUM_QUANT_TBLS = 4; // Quantization tables are numbered 0..3
  static const int NUM_HUFF_TBLS = 4; // Huffman tables are numbered 0..3
  static const int NUM_ARITH_TBLS = 16;  // Arith-coding tables are numbered 0..15
  static const int MAX_COMPS_IN_SCAN = 4; // JPEG limit on # of components in one scan
  static const int MAX_SAMP_FACTOR = 4; // JPEG limit on sampling factors

  static const int M_SOF0  = 0xc0;
  static const int M_SOF1  = 0xc1;
  static const int M_SOF2  = 0xc2;
  static const int M_SOF3  = 0xc3;

  static const int M_SOF5  = 0xc5;
  static const int M_SOF6  = 0xc6;
  static const int M_SOF7  = 0xc7;

  static const int M_JPG   = 0xc8;
  static const int M_SOF9  = 0xc9;
  static const int M_SOF10 = 0xca;
  static const int M_SOF11 = 0xcb;

  static const int M_SOF13 = 0xcd;
  static const int M_SOF14 = 0xce;
  static const int M_SOF15 = 0xcf;

  static const int M_DHT   = 0xc4;

  static const int M_DAC   = 0xcc;

  static const int M_RST0  = 0xd0;
  static const int M_RST1  = 0xd1;
  static const int M_RST2  = 0xd2;
  static const int M_RST3  = 0xd3;
  static const int M_RST4  = 0xd4;
  static const int M_RST5  = 0xd5;
  static const int M_RST6  = 0xd6;
  static const int M_RST7  = 0xd7;

  static const int M_SOI   = 0xd8;
  static const int M_EOI   = 0xd9;
  static const int M_SOS   = 0xda;
  static const int M_DQT   = 0xdb;
  static const int M_DNL   = 0xdc;
  static const int M_DRI   = 0xdd;
  static const int M_DHP   = 0xde;
  static const int M_EXP   = 0xdf;

  static const int M_APP0  = 0xe0; // JFIF
  static const int M_APP1  = 0xe1; //
  static const int M_APP2  = 0xe2;
  static const int M_APP3  = 0xe3;
  static const int M_APP4  = 0xe4;
  static const int M_APP5  = 0xe5;
  static const int M_APP6  = 0xe6;
  static const int M_APP7  = 0xe7;
  static const int M_APP8  = 0xe8;
  static const int M_APP9  = 0xe9;
  static const int M_APP10 = 0xea;
  static const int M_APP11 = 0xeb;
  static const int M_APP12 = 0xec;
  static const int M_APP13 = 0xed;
  static const int M_APP14 = 0xee; // ADOBE
  static const int M_APP15 = 0xef;

  static const int M_JPG0  = 0xf0;
  static const int M_JPG13 = 0xfd;
  static const int M_COM   = 0xfe;

  static const int M_TEM   = 0x01;

  static const int M_ERROR = 0x100;
}
