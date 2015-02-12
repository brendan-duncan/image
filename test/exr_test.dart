part of image_test;

void defineExrTests() {
  Io.File script = new Io.File(Io.Platform.script.toFilePath());
  String path = script.parent.path;

  List<int> bytes = new Io.File(path + '/res/exr/grid.exr').readAsBytesSync();

  ExrDecoder dec = new ExrDecoder();
  ExrImage exrImg = dec.startDecode(bytes);
  Image img = dec.decodeFrame(0);

  List<int> png = new PngEncoder().encodeImage(img);
  new Io.File(path + '/out/exr/grid.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);
}
