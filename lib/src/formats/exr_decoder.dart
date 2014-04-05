part of image;

/**
 */
class ExrDecoder extends Decoder {
  ExrImage exrImage;

  bool isValidFile(List<int> data) {
    return ExrImage.isValidFile(data);
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
    ExrFrameBuffer fb = exrImage.getPart(0).framebuffer;

    if (fb.red == null && fb.green == null && fb.blue == null) {
      throw new ImageException('Only RGB[A] images are currently supported.');
    }

    for (int y = 0, di = 0; y < exrImage.height; ++y) {
      for (int x = 0; x < exrImage.width; ++x) {
        double r = fb.red == null ? 0.0 : fb.red.getFloatSample(x, y);
        double g = fb.green == null ? 0.0 : fb.green.getFloatSample(x, y);
        double b = fb.blue == null ? 0.0 : fb.blue.getFloatSample(x, y);

        pixels[di++] = (r * 255.0).toInt().clamp(0, 255);
        pixels[di++] = (g * 255.0).toInt().clamp(0, 255);
        pixels[di++] = (b * 255.0).toInt().clamp(0, 255);

        if (fb.alpha != null) {
          double a = fb.alpha.getFloatSample(x, y);
          pixels[di++] = (a * 255.0).toInt().clamp(0, 255);
        } else {
          pixels[di++] = 255;
        }
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
