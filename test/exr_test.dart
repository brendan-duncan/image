part of image_test;

void defineExrTests() {
  List<int> bytes = new Io.File('res/exr/grid.exr').readAsBytesSync();

  ExrDecoder dec = new ExrDecoder();
  ExrImage exrImg = dec.startDecode(bytes);
  Image img = dec.decodeFrame(0);

  List<int> png = new PngEncoder().encodeImage(img);
  new Io.File('out/exr/grid.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);
}
