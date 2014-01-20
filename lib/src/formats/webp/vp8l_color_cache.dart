part of image;

class VP8LColorCache {
  final Data.Uint32List colors; // color entries
  final int hashShift; // Hash shift: 32 - hash_bits.

  VP8LColorCache(int hashBits) :
    colors = new Data.Uint32List(1 << hashBits),
    hashShift = 32 - hashBits;
}
