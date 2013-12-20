part of dart_image;


abstract class Encoder {
  void encodeToFileSync(String path, Image image) {
    Io.File fp = new Io.File(path);
    fp.createSync(recursive: true);
    List<int> bytes = encode(image);
    fp.writeAsBytesSync(bytes);
  }

  List<int> encode(Image image);
}
