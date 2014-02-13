part of image;

/**
 * Decode a Targa TGA image. This only supports the 24-bit uncompressed format.
 * TODO add more TGA support.
 */
class TgaDecoder extends Decoder {
  /**
   * Is the given file a valid Targa image?
   */
  bool isValidFile(List<int> data) {
    InputStream input = new InputStream(data,
        byteOrder: BIG_ENDIAN);

    List<int> header = input.readBytes(18);
    if (header[2] != 2) {
      return false;
    }
    if (header[16] != 24) {
      return false;
    }

    return true;
  }

  Image decodeImage(List<int> data, {int frame: 0}) {
    InputStream input = new InputStream(data, byteOrder: BIG_ENDIAN);

    List<int> header = input.readBytes(18);
    if (header[2] != 2) {
      throw new ImageException('Unsupported color format: ${header[2]}');
    }
    if (header[16] != 24 && header[16] != 32) {
      throw new ImageException('Unsupported pixel format: ${header[16]}.');
    }

    int w = (header[12] & 0xff) | ((header[13] & 0xff) << 8);
    int h = (header[14] & 0xff) | ((header[15] & 0xff) << 8);

    Image image = new Image(w, h, Image.RGB);
    for (int y = image.height - 1; y >= 0; --y) {
      if (progressCallback != null) {
        progressCallback(0, 1, y - image.height - 1, image.height);
      }
      for (int x = 0; x < image.width; ++x) {
        int b = input.readByte();
        int g = input.readByte();
        int r = input.readByte();
        image.setPixel(x, y, getColor(r, g, b));
      }
    }

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
}
