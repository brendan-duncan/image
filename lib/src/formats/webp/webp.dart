part of image;

class WebP {
  // VP8 related static constants.
  // max size of mode partition
  static const int VP8_MAX_PARTITION0_SIZE = (1 << 19);
  // max size for token partition
  static const int VP8_MAX_PARTITION_SIZE = (1 << 24);
  // Size of the frame header within VP8 data.
  static const int VP8_FRAME_HEADER_SIZE = 10;

  static const int MAX_PALETTE_SIZE = 256;
  static const int MAX_CACHE_BITS = 11;
  static const int HUFFMAN_CODES_PER_META_CODE = 5;
  static const int ARGB_BLACK = 0xff000000;

  static const int DEFAULT_CODE_LENGTH = 8;
  static const int MAX_ALLOWED_CODE_LENGTH = 15;

  static const int NUM_LITERAL_CODES = 256;
  static const int NUM_LENGTH_CODES = 24;
  static const int NUM_DISTANCE_CODES = 40;
  static const int CODE_LENGTH_CODES = 19;

  // enum VP8LImageTransformType
  static const int PREDICTOR_TRANSFORM  = 0;
  static const int CROSS_COLOR_TRANSFORM = 1;
  static const int SUBTRACT_GREEN = 2;
  static const int COLOR_INDEXING_TRANSFORM = 3;

  // Filters.
  static const int FILTER_NONE = 0;
  static const int FILTER_HORIZONTAL = 1;
  static const int FILTER_VERTICAL = 2;
  static const int FILTER_GRADIENT = 3;
  static const int FILTER_LAST = FILTER_GRADIENT + 1;  // end marker
  static const int FILTER_BEST = 5;
  static const int FILTER_FAST = 6;
}

/**
 * Binary conversion of a uint8 to an int8.  This is equivalent in C to
 * typecasting an unsigned char to a char.
 */
int _uint8ToInt8(int d) {
  d &= 0xff;
  return (d < 128) ? d : -(256 - d);
}

/**
 * Binary conversion of an int32 to a uint32. This is equivalent in C to
 * typecasting an int to an unsigned int.
 */
int _int32ToUint32(int d) {
  _int32ToUint32_int32[0] = d;
  return _int32ToUint32_uint32[0];
}

final Data.Int32List _int32ToUint32_int32 = new Data.Int32List(1);
final Data.Uint32List _int32ToUint32_uint32 =
    new Data.Uint32List.view(_int32ToUint32_int32.buffer);
