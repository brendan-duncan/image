part of image;

/**
 * Convert a high dynamic range image to a low dynamic range image,
 * using gamma tone mapping.
 */
Image gammaToneMap(HdrImage hdr, {double exposure: 1.0}) {
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

  Image image = new Image(hdr.width, hdr.height);
  Uint8List pixels = image.getBytes();

  if (!hdr.hasColor) {
    throw new ImageException('Only RGB[A] images are currently supported.');
  }

  double m = Math.pow(2.0, (exposure + 2.47393).clamp(-20.0, 20.0));

  for (int y = 0, di = 0; y < hdr.height; ++y) {
    for (int x = 0; x < hdr.width; ++x) {
      double r = hdr.red == null ? 0.0 : hdr.red.getFloatSample(x, y);
      double g = hdr.green == null ? 0.0 : hdr.green.getFloatSample(x, y);
      double b = hdr.blue == null ? 0.0 : hdr.blue.getFloatSample(x, y);

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

      if (hdr.alpha != null) {
        double a = hdr.alpha.getFloatSample(x, y);
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
