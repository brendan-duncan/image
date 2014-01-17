library webp;

class WebP {
  // Create fourcc of the chunk from the chunk tag characters.
  static int MKFOURCC(a, b, c, d) => ((a) | (b) << 8 | (c) << 16 | (d) << 24);

  // VP8 related constants.
  static const int VP8_SIGNATURE = 0x9d012a; // Signature in VP8 data.
  // max size of mode partition
  static const int VP8_MAX_PARTITION0_SIZE = (1 << 19);
  // max size for token partition
  static const int VP8_MAX_PARTITION_SIZE = (1 << 24);
  // Size of the frame header within VP8 data.
  static const int VP8_FRAME_HEADER_SIZE = 10;

  // VP8L related constants.
  static const int VP8L_SIGNATURE_SIZE = 1; // VP8L signature size.
  static const int VP8L_MAGIC_BYTE = 0x2f;   // VP8L signature byte.
  // Number of bits used to store width and height.
  static const int VP8L_IMAGE_SIZE_BITS = 14;

  // 3 bits reserved for version.
  static const int VP8L_VERSION_BITS = 3;
  static const int VP8L_VERSION = 0; // version 0
  // Size of the VP8L frame header.
  static const int VP8L_FRAME_HEADER_SIZE = 5;

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

  static const int MIN_HUFFMAN_BITS = 2;  // min number of Huffman bits
  static const int MAX_HUFFMAN_BITS = 9;  // max number of Huffman bits

  // The bit to be written when next data to be read is a transform.
  static const int TRANSFORM_PRESENT = 1;
  // Maximum number of allowed transform in a bitstream.
  static const int NUM_TRANSFORMS = 4;

  // enum VP8LImageTransformType
  static const int PREDICTOR_TRANSFORM  = 0;
  static const int CROSS_COLOR_TRANSFORM = 1;
  static const int SUBTRACT_GREEN = 2;
  static const int COLOR_INDEXING_TRANSFORM = 3;

  // Alpha related constants.
  static const int ALPHA_HEADER_LEN = 1;
  static const int ALPHA_NO_COMPRESSION = 0;
  static const int ALPHA_LOSSLESS_COMPRESSION = 1;
  static const int ALPHA_PREPROCESSED_LEVELS = 1;

  // Mux related constants.
  // Size of a chunk tag (e.g. "VP8L").
  static const int TAG_SIZE = 4;
  // Size needed to store chunk's size.
  static const int CHUNK_SIZE_BYTES = 4;
  // Size of a chunk header.
  static const int CHUNK_HEADER_SIZE = 8;
  // Size of the RIFF header ("RIFFnnnnWEBP").
  static const int RIFF_HEADER_SIZE = 12;
  // Size of an ANMF chunk.
  static const int ANMF_CHUNK_SIZE = 16;
  // Size of an ANIM chunk.
  static const int ANIM_CHUNK_SIZE = 6;
  // Size of a FRGM chunk.
  static const int FRGM_CHUNK_SIZE = 6;
  // Size of a VP8X chunk.
  static const int VP8X_CHUNK_SIZE = 10;

  // 24-bit max for VP8X width/height.
  static const int MAX_CANVAS_SIZE = (1 << 24);
  // 32-bit max for width x height.
  static const int MAX_IMAGE_AREA = (1 << 32);
  // maximum value for loop-count
  static const int MAX_LOOP_COUNT = (1 << 16);
  // maximum duration
  static const int MAX_DURATION = (1 << 24);
  // maximum frame/fragment x/y offset
  static const int MAX_POSITION_OFFSET = (1 << 24);

  // Maximum chunk payload is such that adding the header and padding won't
  // overflow a uint32.
  static const int MAX_CHUNK_PAYLOAD = 0xfffffff6;
}
