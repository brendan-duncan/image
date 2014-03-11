part of image;

class JpegComponent {
  int h;
  int v;
  final List<Int32List> quantizationTableList;
  int quantizationIndex;
  int blocksPerLine;
  int blocksPerColumn;
  List blocks;
  List huffmanTableDC;
  List huffmanTableAC;
  int pred;

  JpegComponent(this.h, this.v, this.quantizationTableList,
      this.quantizationIndex);

  Int32List get quantizationTable =>
      quantizationTableList[quantizationIndex];
}
