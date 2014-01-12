part of image;

/**
 * Returns a copy of the [src] image, rotated by [angle] degrees.
 */
Image copyRotate(Image src, num angle, {int interpolation: LINEAR}) {
  double nangle = angle % 360.0;

  // Optimized version for orthogonal angles.
  if ((nangle % 90.0) == 0.0) {
    int wm1 = src.width - 1;
    int hm1 = src.height - 1;

    int iangle = nangle ~/ 90.0;
    switch (iangle) {
      case 1: // 90 deg.
        Image dst = new Image(src.height, src.width, src.format);
        for (int y = 0; y < dst.height; ++y) {
          for (int x = 0; x < dst.width; ++x) {
            dst.setPixel(x, y, src.getPixel(y, x));
          }
        }
        return dst;
        break;
      case 2: // 180 deg.
        Image dst = new Image(src.width, src.height, src.format);
        for (int y = 0; y < dst.height; ++y) {
          for (int x = 0; x < dst.width; ++x) {
            dst.setPixel(x, y, src.getPixel(wm1 - x, hm1 - y));
          }
        }
        return dst;
        break;
      case 3: // 270 deg.
        Image dst = new Image(src.height, src.width, src.format);
        for (int y = 0; y < dst.height; ++y) {
          for (int x = 0; x < dst.width; ++x) {
            dst.setPixel(x, y, src.getPixel(wm1 - y, x));
          }
        }
        return dst;
        break;
      default: // 0 deg.
        return new Image.from(src);
    }
  }

  // Generic angle.
  double rad = (nangle * Math.PI / 180.0);
  double ca = Math.cos(rad);
  double sa = Math.sin(rad);
  double ux = (src.width * ca).abs();
  double uy = (src.width * sa).abs();
  double vx = (src.height * sa).abs();
  double vy = (src.height * ca).abs();
  double w2 = 0.5 * src.width;
  double h2 = 0.5 * src.height;
  double dw2 = 0.5 * (ux + vx);
  double dh2 = 0.5 * (uy + vy);

  Image dst = new Image((ux + vx).toInt(), (uy + vy).toInt(), src.format);

  switch (interpolation) {
    case CUBIC: // Cubic interpolation.
      for (int y = 0; y < dst.height; ++y) {
        for (int x = 0; x < dst.width; ++x) {
          int c = src.getPixelCubic(w2 + (x - dw2) * ca + (y - dh2) * sa,
                                    h2 - (x - dw2) * sa + (y - dh2) * ca);
          dst.setPixel(x, y, c);
        }
      }
      break;
    case LINEAR: // Linear interpolation.
      for (int y = 0; y < dst.height; ++y) {
        for (int x = 0; x < dst.width; ++x) {
          int c = src.getPixelLinear(w2 + (x - dw2) * ca + (y - dh2) * sa,
                                     h2 - (x - dw2) * sa + (y - dh2) * ca);
          dst.setPixel(x, y, c);
        }
      }
      break;
    default: // Nearest-neighbor interpolation.
      for (int y = 0; y < dst.height; ++y) {
        for (int x = 0; x < dst.width; ++x) {
          int c = src.getPixel((w2 + (x - dw2) * ca + (y - dh2) * sa).toInt(),
                               (h2 - (x - dw2) * sa + (y - dh2) * ca).toInt());
          dst.setPixel(x, y, c);
        }
      }
      break;
  }

  return dst;
}
