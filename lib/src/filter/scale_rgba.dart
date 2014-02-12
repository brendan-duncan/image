part of image;

Image scaleRGBA(Image src, int r, int g, int b, int a) {
  double dr = r / 255.0;
  double dg = g / 255.0;
  double db = b / 255.0;
  double da = a / 255.0;
  Uint8List bytes = src.getBytes();
  for (int i = 0, len = bytes.length; i < len; i += 4) {
    bytes[i] = (bytes[i] * dr).floor();
    bytes[i + 1] = (bytes[i + 1] * dg).floor();
    bytes[i + 2] = (bytes[i + 2] * db).floor();
    bytes[i + 3] = (bytes[i + 3] * da).floor();
  }
  return src;
}
