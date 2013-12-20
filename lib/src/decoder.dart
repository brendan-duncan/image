part of dart_image;

abstract class Decoder {
  /**
   * Decode the contents of a file.
   */
  Image decodeFileSync(String path) {
    Io.File file = new Io.File(path);
    file.openSync();
    var bytes = file.readAsBytesSync();
    return decode(bytes);
  }

  /**
   * Decode byte data.
   */
  Image decode(List<int> bytes);
}
