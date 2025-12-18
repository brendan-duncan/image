import '../../util/_internal.dart';
import 'vp8l.dart';
import 'vp8l_bit_reader.dart';

@internal
class HuffmanCode {
  int bits;
  int value;

  HuffmanCode()
      : bits = 0,
        value = 0;

  HuffmanCode.from(HuffmanCode other)
      : bits = other.bits,
        value = other.value;
}

@internal
class HuffmanCode32 {
  int bits = 0;
  int value = 0;
}

@internal
class HuffmanCodeList {
  final List<HuffmanCode> htree;
  int offset;
  HuffmanCodeList(int size)
      : htree = List<HuffmanCode>.generate(size, (_) => HuffmanCode()),
        offset = 0;

  HuffmanCodeList.from(HuffmanCodeList other, int offset)
      : htree = other.htree,
        offset = other.offset + offset;

  int get length => htree.length - offset;

  HuffmanCode operator [](int index) => htree[offset + index];

  void operator []=(int index, HuffmanCode code) {
    htree[offset + index].bits = code.bits;
    htree[offset + index].value = code.value;
  }
}

// A group of huffman trees.
@internal
class HTreeGroup {
  final List<HuffmanCodeList> htrees;
  bool isTrivialLiteral = false;
  int literalArb = 0;
  bool isTrivialCode = false;
  bool usePackedTable = false;
  final List<HuffmanCode32> packedTable;

  HTreeGroup()
      : htrees = List<HuffmanCodeList>.generate(
            VP8L.huffmanCodesPerMetaCode, (_) => HuffmanCodeList(0),
            growable: false),
        packedTable = List<HuffmanCode32>.generate(
            VP8L.huffmanPackedTableSize, (_) => HuffmanCode32(),
            growable: false);

  HuffmanCodeList operator [](int index) => htrees[index];

  int readSymbol(int table, VP8LBitReader br) {
    var val = br.prefetchBits();
    var tableIndex = val & huffmanTableMask;
    final nbits = htrees[table][tableIndex].bits - huffmanTableBits;
    if (nbits > 0) {
      br.bitPos += huffmanTableBits;
      val = br.prefetchBits();
      tableIndex += htrees[table][tableIndex].value;
      tableIndex += val & ((1 << nbits) - 1);
    }
    br.bitPos += htrees[table][tableIndex].bits;
    return htrees[table][tableIndex].value;
  }

  static const huffmanTableBits = 8;
  static const huffmanTableMask = (1 << huffmanTableBits) - 1;
}

@internal
class HuffmanTablesSegment {
  HuffmanCodeList? start;
  HuffmanCodeList? currentTable;
  HuffmanTablesSegment? next;
  int currentOffset = 0;
  int size = 0;
}

@internal
class HuffmanTables {
  HuffmanTablesSegment root = HuffmanTablesSegment();
  HuffmanTablesSegment? currentSegment;

  HuffmanTables(int size) {
    currentSegment = root;
    final start = HuffmanCodeList(size);
    root
      ..next = null
      ..size = size
      ..start = start
      ..currentTable = start;
  }
}
