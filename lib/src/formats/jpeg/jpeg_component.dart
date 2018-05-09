import 'dart:typed_data';

class JpegComponent {
  int h;
  int v;
  final List<Int16List> quantizationTableList;
  int quantizationIndex;
  int blocksPerLine;
  int blocksPerColumn;
  List blocks;
  List huffmanTableDC;
  List huffmanTableAC;
  int pred;

  JpegComponent(this.h, this.v, this.quantizationTableList,
      this.quantizationIndex);

  Int16List get quantizationTable =>
      quantizationTableList[quantizationIndex];
}
