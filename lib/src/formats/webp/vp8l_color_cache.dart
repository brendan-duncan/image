import 'dart:typed_data';

class VP8LColorCache {
  final Uint32List colors; // color entries
  final int hashShift; // Hash shift: 32 - hash_bits.

  VP8LColorCache(int hashBits) :
    colors = new Uint32List(1 << hashBits),
    hashShift = 32 - hashBits;

  void insert(int argb) {
    final int a = (argb * _HASH_MUL) & 0xffffffff;
    final int key = (a >> hashShift);
    colors[key] = argb;
  }

  int lookup(int key) {
    return colors[key];
  }

  static const int _HASH_MUL = 0x1e35a7bd;
}
