part of image;

/**
 * Decode a jpeg encoded image.
 */
class JpegDecoder extends Decoder {
  /**
   * Is the given file a valid JPEG image?
   */
  bool isValidFile(List<int> data) {
    Arc.InputStream input = new Arc.InputStream(data,
        byteOrder: Arc.BIG_ENDIAN);
    return new JpegData().validate(data);
  }

  Image decodeImage(List<int> data, {int frame: 0}) {
    JpegData jpeg = new JpegData();
    jpeg.read(data);

    if (jpeg.frames.length != 1) {
      throw 'only single frame JPEGs supported';
    }

    Image image = new Image(jpeg.width, jpeg.height, Image.RGB);

    _copyToImage(jpeg, image);

    return image;
  }

  Animation decodeAnimation(List<int> data) {
    Image image = decodeImage(data);
    if (image == null) {
      return null;
    }

    Animation anim = new Animation();
    anim.addFrame(image);

    return anim;
  }

  void _copyToImage(JpegData jpeg, Image imageData) {
    int width = imageData.width;
    int height = imageData.height;
    Data.Uint8List data = jpeg.getData(width, height);
    List components = jpeg.components;

    int i = 0;
    int j = 0;
    switch (components.length) {
      case 1: // Luminance
        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            int Y = data[i++];
            imageData[j++] = getColor(Y, Y, Y, 255);
          }
        }
        break;
      case 3: // RGB
        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            int R = data[i++];
            int G = data[i++];
            int B = data[i++];

            int c = getColor(R, G, B, 255);
            imageData[j++] = c;
          }
        }
        break;
      case 4: // CMYK
        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            int C = data[i++];
            int M = data[i++];
            int Y = data[i++];
            int K = data[i++];

            int R = 255 - _clamp(C * (1 - K ~/ 255) + K);
            int G = 255 - _clamp(M * (1 - K ~/ 255) + K);
            int B = 255 - _clamp(Y * (1 - K ~/ 255) + K);

            imageData[j++] = getColor(R, G, B, 255);
          }
        }
        break;
      default:
        throw 'Unsupported color mode';
    }
  }

  int _clamp(int i) {
    return i < 0 ? 0 : i > 255 ? 255 : i;
  }
}
