part of image;

/**
 */
class ExrDecoder extends Decoder {
  ExrImage exrImage;

  bool isValidFile(List<int> data) {
    return ExrImage.isValid(data);
  }

  DecodeInfo startDecode(List<int> data) {
    exrImage = new ExrImage(data);
    return exrImage;
  }

  int numFrames() => exrImage != null ? 1 : 0;

  Image decodeFrame(int frame) {
    if (exrImage == null) {
      return null;
    }

    Image image = new Image(exrImage.width, exrImage.height);
    Uint8List pixels = image.getBytes();

    ExrSlice R = exrImage.part(0).framebuffer['R'];
    ExrSlice G = exrImage.part(0).framebuffer['G'];
    ExrSlice B = exrImage.part(0).framebuffer['B'];

    for (int y = 0, di = 0; y < exrImage.height; ++y) {
      for (int x = 0; x < exrImage.width; ++x) {
        double r = R.getPixel(x, y).toDouble();
        double g = G.getPixel(x, y).toDouble();
        double b = B.getPixel(x, y).toDouble();
        pixels[di++] = (r * 255.0).toInt().clamp(0, 255);
        pixels[di++] = (g * 255.0).toInt().clamp(0, 255);
        pixels[di++] = (b * 255.0).toInt().clamp(0, 255);
        pixels[di++] = 255;
      }
    }

    return image;
  }

  Image decodeImage(List<int> data, {int frame: 0}) {
    if (startDecode(data) == null) {
      return null;
    }

    return decodeFrame(frame);
  }

  Animation decodeAnimation(List<int> data) {
    Image image = decodeImage(data);
    if (image == null) {
      return null;
    }

    Animation anim = new Animation();
    anim.width = image.width;
    anim.height = image.height;
    anim.addFrame(image);

    return anim;
  }
}
