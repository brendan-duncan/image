part of image;

/**
 * Adjust the color of the [src] image using varous color transformations.
 */
Image adjustColor(Image src, {int blacks, int whites, int mids,
                  double contrast, double saturation, double brightness,
                  double gamma, double exposure, double hue,
                  double amount}) {
  const double DEG_TO_RAD = 0.0174532925;
  const double avgLumR = 0.5;
  const double avgLumG = 0.5;
  const double avgLumB = 0.5;
  const double lumCoeffR = 0.2125;
  const double lumCoeffG = 0.7154;
  const double lumCoeffB = 0.0721;

  double br, bg, bb;
  double wr, wg, wb;
  double mr, mg, mb;
  if (blacks != null || whites != null || mids != null) {
    br = blacks != null ? getRed(blacks) / 255.0 : 0.0;
    bg = blacks != null ? getGreen(blacks) / 255.0 : 0.0;
    bb = blacks != null ? getBlue(blacks) / 255.0 : 0.0;

    wr = whites != null ? getRed(whites) / 255.0 : 1.0;
    wg = whites != null ? getGreen(whites) / 255.0 : 1.0;
    wb = whites != null ? getBlue(whites) / 255.0 : 1.0;

    mr = mids != null ? getRed(mids) / 255.0 : 0.5;
    mg = mids != null ? getGreen(mids) / 255.0 : 0.5;
    mb = mids != null ? getBlue(mids) / 255.0 : 0.5;

    mr = 1.0 / (1.0 + 2.0 * (mr - 0.5));
    mg = 1.0 / (1.0 + 2.0 * (mg - 0.5));
    mb = 1.0 / (1.0 + 2.0 * (mb - 0.5));
  }

  double invSaturation = saturation != null ? 1.0 - saturation : 0.0;
  double invContrast = contrast != null ? 1.0 - contrast : 0.0;

  if (exposure != null) {
    exposure = Math.pow(2.0, exposure);
  }

  double hueR;
  double hueG;
  double hueB;
  if (hue != null) {
    hue *= DEG_TO_RAD;
    double s = Math.sin(hue);
    double c = Math.cos(hue);

    hueR = (2.0 * c) / 3.0;
    hueG = (-Math.sqrt(3.0) * s - c) / 3.0;
    hueB = ((Math.sqrt(3.0) * s - c) + 1.0) / 3.0;
  }

  double invAmount = amount != null ? 1.0 - amount : 0.0;

  Uint8List pixels = src.getBytes();
  for (int i = 0, len = pixels.length; i < len; i += 4) {
    double or = pixels[i] / 255.0;
    double og = pixels[i + 1] / 255.0;
    double ob = pixels[i + 2] / 255.0;

    double r = or;
    double g = og;
    double b = ob;

    if (br != null) {
      r = Math.pow((r + br) * wr, mr);
      g = Math.pow((g + bg) * wg, mg);
      b = Math.pow((b + bb) * wb, mb);
    }

    if (brightness != null) {
      r *= brightness;
      g *= brightness;
      b *= brightness;
    }

    if (saturation != null) {
      double lum = r * lumCoeffR + g * lumCoeffG + b * lumCoeffB;

      r = lum * invSaturation + r * saturation;
      g = lum * invSaturation + g * saturation;
      b = lum * invSaturation + b * saturation;
    }

    if (contrast != null) {
      r = avgLumR * contrast + r * invContrast;
      g = avgLumG * contrast + g * invContrast;
      b = avgLumB * contrast + b * invContrast;
    }

    if (gamma != null) {
      r = Math.pow(r, gamma);
      g = Math.pow(g, gamma);
      b = Math.pow(b, gamma);
    }

    if (exposure != null) {
      r = r * exposure;
      g = g * exposure;
      b = b * exposure;
    }

    if (hue != null) {
      double hr = r * hueR + g * hueG + b * hueB;
      double hg = r * hueB + g * hueR + b * hueG;
      double hb = r * hueG + g * hueB + b * hueR;

      r = hr;
      g = hg;
      b = hb;
    }

    if (amount != null) {
      r = r * amount + or * invAmount;
      g = g * amount + og * invAmount;
      b = b * amount + ob * invAmount;
    }

    pixels[i] = _clamp255((r * 255.0).toInt());
    pixels[i + 1] = _clamp255((g * 255.0).toInt());
    pixels[i + 2] = _clamp255((b * 255.0).toInt());
  }

  return src;
}
