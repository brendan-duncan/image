import 'dart:typed_data';

class JpegComponent {
  int hSamples;
  int vSamples;
  final List<Int16List> quantizationTableList;
  int quantizationIndex;
  int blocksPerLine;
  int blocksPerColumn;
  List blocks;
  List huffmanTableDC;
  List huffmanTableAC;
  int pred;

  JpegComponent(this.hSamples, this.vSamples, this.quantizationTableList,
      this.quantizationIndex);

  Int16List get quantizationTable => quantizationTableList[quantizationIndex];
}
