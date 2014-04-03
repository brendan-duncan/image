part of image_test;

void defineExrTests() {
  List<int> bytes = new Io.File('res/exr/grid.exr').readAsBytesSync();
  ImfImage input = new ImfImage(bytes);
}
