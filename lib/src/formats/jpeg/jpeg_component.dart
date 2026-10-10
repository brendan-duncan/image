import 'dart:typed_data';

import '_jpeg_huffman.dart';

class JpegComponent {
  int hSamples;
  int vSamples;
  final List<Int16List?> quantizationTableList;
  int quantizationIndex;
  late int blocksPerLine;
  late int blocksPerColumn;

  /// The number of blocks per line and column of [coefficients], including
  /// the blocks that pad the component out to whole MCUs.
  late int blocksPerLineForMcu;
  late int blocksPerColumnForMcu;

  /// The DCT coefficients, 64 per block, with blocks stored in row-major
  /// order. The coefficient for block (row, col) starts at
  /// `(row * blocksPerLineForMcu + col) * 64`.
  late Int16List coefficients;

  /// Whether [coefficients] only holds the DC coefficient of each block, at
  /// `row * blocksPerLineForMcu + col`, for decoding at 1/8 scale.
  bool dcOnly = false;
  late List<HuffmanNode?> huffmanTableDC;
  late List<HuffmanNode?> huffmanTableAC;

  /// Lookahead tables for [huffmanTableDC] and [huffmanTableAC].
  late Uint16List huffmanLookupDC;
  late Uint16List huffmanLookupAC;
  late int pred;

  JpegComponent(this.hSamples, this.vSamples, this.quantizationTableList,
      this.quantizationIndex);

  Int16List? get quantizationTable => quantizationTableList[quantizationIndex];
}
