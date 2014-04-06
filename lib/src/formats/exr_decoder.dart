part of image;

/**
 * Decode an OpenEXR formatted image.
 *
 * OpenEXR stores high dynamic range (HDR) images in floating-point channels.
 * The HDR image is tone-mapped to a low dynamic range (LDR) for creating
 * an [Image].
 */
class ExrDecoder extends Decoder {
  ExrImage exrImage;
  /// Exposure for tone-mapping the hdr image to an [Image], applied during
  /// [decodeFrame].
  double exposure = 1.0;

  ExrDecoder({this.exposure: 1.0});

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

    double m = Math.pow(2.0, (exposure + 2.47393).clamp(-20.0, 20.0));

    for (int y = 0, di = 0; y < exrImage.height; ++y) {
      for (int x = 0; x < exrImage.width; ++x) {
        double r = fb.red == null ? 0.0 : fb.red.getFloatSample(x, y);
        double g = fb.green == null ? 0.0 : fb.green.getFloatSample(x, y);
        double b = fb.blue == null ? 0.0 : fb.blue.getFloatSample(x, y);

        if (r.isInfinite || r.isNaN) {
          r = 0.0;
        }
        if (g.isInfinite || g.isNaN) {
          g = 0.0;
        }
        if (b.isInfinite || b.isNaN) {
          b = 0.0;
        }

        pixels[di++] = _gamma(r, m);
        pixels[di++] = _gamma(g, m);
        pixels[di++] = _gamma(b, m);

        if (fb.alpha != null) {
          double a = fb.alpha.getFloatSample(x, y);
          if (a.isInfinite || a.isNaN) {
            a = 1.0;
          }
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

  double _knee(double x, double f) {
    return Math.log(x * f + 1.0) / f;
  }


  int _gamma(double h, double m) {
    double x = Math.max(0.0, h * m);

    if (x > 1.0) {
      x = 1 + _knee(x - 1, 0.184874);
    }

    return (Math.pow(x, 0.4545) * 84.66).toInt().clamp(0, 255);
  }
}
