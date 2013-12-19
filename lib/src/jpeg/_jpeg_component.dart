part of dart_image;

class _JpegComponent {
  int h;
  int v;
  final Data.Int32List quantizationTable;
  int blocksPerLine;
  int blocksPerColumn;
  List blocks;
  List huffmanTableDC;
  List huffmanTableAC;
  int pred;

  _JpegComponent(this.h, this.v, this.quantizationTable);
}
