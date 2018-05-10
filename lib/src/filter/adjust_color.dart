import 'dart:math' as Math;
import 'dart:typed_data';

import '../color.dart';
import '../image.dart';
import '../internal/clamp.dart';

/**
 * Adjust the color of the [src] image using varous color transformations.
 *
 * [blacks] defines the black level of the image, as a color.
 *
 * [whites] defines the white level of the image, as a color.
 *
 * [mids] defines the mid level of hte image, as a color.
 *
 * [contrast] increases (> 1) / decreases (< 1) the contrast of the image by
 * pushing colors away/toward neutral gray, where at 0.0 the image is entirely
 * neutral gray (0 contrast), 1.0, the image is not adjusted and > 1.0 the
 * image increases contrast.
 *
 * [saturation] increases (> 1) / decreases (< 1) the saturation of the image
 * by pushing colors away/toward their grayscale value, where 0.0 is grayscale
 * and 1.0 is the original image, and > 1.0 the image becomes more saturated.
 *
 * [brightness] is a constant scalar of the image colors.  At 0 the image
 * is black, 1.0 unmodified, and > 1.0 the image becomes brighter.
 *
 * [gamma] is an exponental scalar of the image colors.  At < 1.0 the image
 * becomes brighter, and > 1.0 the image becomes darker.  A [gamma] of 1/2.2
 * will convert the image colors to linear color space.
 *
 * [exposure] is an exponental scalar of the image as rgb * pow(2, exposure).
 * At 0, the image is unmodified; as the exposure increases, the image
 * brightens.
 *
 * [hue] shifts the hue component of the image colors in degrees.  A [hue] of
 * 0 will have no affect, and a [hue] of 45 will shift the hue of all colors
 * by 45 degrees.
 *
 * [amount] controls how much affect this filter has on the [src] image, where
 * 0.0 has no effect and 1.0 has full effect.
 */
Image adjustColor(Image src, {int blacks, int whites, int mids,
                  double contrast, double saturation, double brightness,
                  double gamma, double exposure, double hue,
                  double amount}) {
  if (amount == 0.0) {
    return src;
  }

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

    if (brightness != null && brightness != 1.0) {
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
      r = avgLumR * invContrast + r * contrast;
      g = avgLumG * invContrast + g * contrast;
      b = avgLumB * invContrast + b * contrast;
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

    if (hue != null && hue != 0.0) {
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

    pixels[i] = clamp255((r * 255.0).toInt());
    pixels[i + 1] = clamp255((g * 255.0).toInt());
    pixels[i + 2] = clamp255((b * 255.0).toInt());
  }

  return src;
}
