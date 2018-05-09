import 'dart:math' as Math;
import 'dart:typed_data';

import '../image.dart';
import '../image_exception.dart';
import 'hdr_image.dart';

/**
 * Convert a high dynamic range image to a low dynamic range image,
 * with optional exposure control.
 */
Image hdrToImage(HdrImage hdr, {double exposure}) {
  double _knee(double x, double f) {
    return Math.log(x * f + 1.0) / f;
  }

  double _gamma(double h, double m) {
    double x = Math.max(0.0, h * m);

    if (x > 1.0) {
      x = 1.0 + _knee(x - 1, 0.184874);
    }

    return (Math.pow(x, 0.4545) * 84.66);
  }

  Image image = new Image(hdr.width, hdr.height);
  Uint8List pixels = image.getBytes();

  if (!hdr.hasColor) {
    throw new ImageException('Only RGB[A] images are currently supported.');
  }

  double m = exposure != null ?
             Math.pow(2.0, (exposure + 2.47393).clamp(-20.0, 20.0)) :
             1.0;

  for (int y = 0, di = 0; y < hdr.height; ++y) {
    for (int x = 0; x < hdr.width; ++x) {
      double r = hdr.getRed(x, y);
      double g = hdr.getGreen(x, y);
      double b = hdr.getBlue(x, y);

      if (r.isInfinite || r.isNaN) {
        r = 0.0;
      }
      if (g.isInfinite || g.isNaN) {
        g = 0.0;
      }
      if (b.isInfinite || b.isNaN) {
        b = 0.0;
      }

      double ri, gi, bi;
      if (exposure != null) {
        ri = _gamma(r, m);
        gi = _gamma(g, m);
        bi = _gamma(b, m);
      } else {
        ri = (r * 255.0);
        gi = (g * 255.0);
        bi = (b * 255.0);
      }

      // Normalize the color
      double mi = Math.max(ri, Math.max(gi, bi));
      if (mi > 255.0) {
        ri = 255.0 * (ri / mi);
        gi = 255.0 * (gi / mi);
        bi = 255.0 * (bi / mi);
      }

      pixels[di++] = ri.toInt().clamp(0, 255);
      pixels[di++] = gi.toInt().clamp(0, 255);
      pixels[di++] = bi.toInt().clamp(0, 255);

      if (hdr.alpha != null) {
        double a = hdr.alpha.getFloat(x, y);
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
