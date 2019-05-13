import 'dart:math' as math;
import 'dart:typed_data';

import '../image.dart';
import '../image_exception.dart';
import 'hdr_image.dart';

/// Convert a high dynamic range image to a low dynamic range image,
/// with optional exposure control.
Image hdrToImage(HdrImage hdr, {num exposure}) {
  num _knee(num x, num f) {
    return math.log(x * f + 1.0) / f;
  }

  num _gamma(num h, num m) {
    num x = math.max(0, h * m);

    if (x > 1.0) {
      x = 1.0 + _knee(x - 1, 0.184874);
    }

    return math.pow(x, 0.4545) * 84.66;
  }

  Image image = Image(hdr.width, hdr.height);
  Uint8List pixels = image.getBytes();

  if (!hdr.hasColor) {
    throw ImageException('Only RGB[A] images are currently supported.');
  }

  num m = (exposure != null)
      ? math.pow(2.0, (exposure + 2.47393).clamp(-20.0, 20.0))
      : 1.0;

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

      num ri, gi, bi;
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
      num mi = math.max(ri, math.max(gi, bi));
      if (mi > 255.0) {
        ri = 255.0 * (ri / mi);
        gi = 255.0 * (gi / mi);
        bi = 255.0 * (bi / mi);
      }

      pixels[di++] = ri.clamp(0, 255).toInt();
      pixels[di++] = gi.clamp(0, 255).toInt();
      pixels[di++] = bi.clamp(0, 255).toInt();

      if (hdr.alpha != null) {
        double a = hdr.alpha.getFloat(x, y);
        if (a.isInfinite || a.isNaN) {
          a = 1.0;
        }
        pixels[di++] = (a * 255.0).clamp(0, 255).toInt();
      } else {
        pixels[di++] = 255;
      }
    }
  }

  return image;
}
