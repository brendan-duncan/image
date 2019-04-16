import 'dart:math' as Math;

import 'image_exception.dart';
import 'internal/clamp.dart';

/**
 * Image pixel colors are instantiated as an int object rather than an instance
 * of the Color class in order to reduce object allocations. Image pixels are
 * stored in 32-bit RGBA format (8 bits per channel). Internally in dart, this
 * will be stored in a "small integer" on 64-bit machines, or a
 * "medium integer" on 32-bit machines. In Javascript, this will be stored
 * in a 64-bit double.
 *
 * The Color class is used as a namespace for color operations, in an attempt
 * to create a cleaner API for color operations.
 */
class Color {
  /**
   * Create a color value from RGB values in the range [0, 255].
   */
  static int fromRgb(int red, int green, int blue) {
    return getColor(red, green, blue);
  }

  /**
   * Create a color value from RGBA values in the range [0, 255].
   */
  static int fromRgba(int red, int green, int blue, int alpha) {
    return getColor(red, green, blue, alpha);
  }

  /**
   * Create a color value from HSL values in the range [0, 1].
   */
  static int fromHsl(num hue, num saturation, num lightness) {
    var rgb = hslToRGB(hue, saturation, lightness);
    return getColor(rgb[0], rgb[1], rgb[2]);
  }

  /**
   * Create a color value from HSV values in the range [0, 1].
   */
  static int fromHsv(num hue, num saturation, num value) {
    var rgb = hsvToRGB(hue, saturation, value);
    return getColor(rgb[0], rgb[1], rgb[2]);
  }

  /**
   * Create a color value from XYZ values.
   */
  static int fromXyz(num x, num y, num z) {
    var rgb = xyzToRGB(x, y, z);
    return getColor(rgb[0], rgb[1], rgb[2]);
  }

  /**
   * Create a color value from CIE-L*ab values.
   */
  static int fromLab(num L, num a, num b) {
    var rgb = labToRGB(L, a, b);
    return getColor(rgb[0], rgb[1], rgb[2]);
  }

  /**
   * Compare colors from a 3 or 4 dimensional color space
   */
  static double distance(List<double> c1, List<double> c2, bool compareAlpha) {
    double d1 = c1[0] - c2[0];
    double d2 = c1[1] - c2[1];
    double d3 = c1[2] - c2[2];
    if (compareAlpha) {
      double dA = c1[3] - c2[3];
      return Math.sqrt(
        Math.max(d1*d1, (d1-dA)*(d1-dA)) +
        Math.max(d2*d2, (d2-dA)*(d2-dA)) +
        Math.max(d3*d3, (d3-dA)*(d3-dA))
      );
    } else {
      return Math.sqrt(
        d1*d1 +
        d2*d2 +
        d3*d3);
    }
  }
}


/// Red channel of a color.
const int RED = 0;
/// Green channel of a color.
const int GREEN = 1;
/// Blue channel of a color.
const int BLUE = 2;
/// Alpha channel of a color.
const int ALPHA = 3;
/// Luminance of a color.
const int LUMINANCE = 4;

/**
 * Get the color with the given [r], [g], [b], and [a] components.
 *
 * The channel order of a uint32 encoded color is RGBA, to be consistent
 * with the image data of a canvas html element.
 */
int getColor(int r, int g, int b, [int a = 255]) =>
    (clamp255(a) << 24) |
    (clamp255(b) << 16) |
    (clamp255(g) << 8) |
    clamp255(r);

/**
 * Get the [channel] from the [color].
 */
int getChannel(int color, int channel) =>
    channel == 0 ? getRed(color) :
    channel == 1 ? getGreen(color) :
    channel == 2 ? getBlue(color) :
    getAlpha(color);

/**
 * Returns a new color, where the given [color]'s [channel] has been
 * replaced with the given [value].
 */
int setChannel(int color, int channel, int value) =>
    channel == 0 ? setRed(color, value) :
    channel == 1 ? setGreen(color, value) :
    channel == 2 ? setBlue(color, value) :
    setAlpha(color, value);

/**
 * Get the red channel from the [color].
 */
int getRed(int color) =>
    (color) & 0xff;

/**
 * Returns a new color where the red channel of [color] has been replaced
 * by [value].
 */
int setRed(int color, int value) =>
    (color & 0xffffff00) | (clamp255(value));

/**
 * Get the green channel from the [color].
 */
int getGreen(int color) =>
    (color >> 8) & 0xff;

/**
 * Returns a new color where the green channel of [color] has been replaced
 * by [value].
 */
int setGreen(int color, int value) =>
    (color & 0xffff00ff) | (clamp255(value) << 8);

/**
 * Get the blue channel from the [color].
 */
int getBlue(int color) =>
    (color >> 16) & 0xff;

/**
 * Returns a new color where the blue channel of [color] has been replaced
 * by [value].
 */
int setBlue(int color, int value) =>
    (color & 0xff00ffff) | (clamp255(value) << 16);

/**
 * Get the alpha channel from the [color].
 */
int getAlpha(int color) =>
    (color >> 24) & 0xff;

/**
 * Returns a new color where the alpha channel of [color] has been replaced
 * by [value].
 */
int setAlpha(int color, int value) =>
    (color & 0x00ffffff) | (clamp255(value) << 24);

/**
 * Returns a new color of [src] alpha-blended onto [dst]. The opacity of [src]
 * is additionally scaled by [fraction] / 255.
 */
int alphaBlendColors(int dst, int src, [int fraction = 0xff]) {
  double a = (getAlpha(src) / 255.0);
  if (fraction != 0xff) {
    a *= (fraction / 255.0);
  }

  int sr = (getRed(src) * a).round();
  int sg = (getGreen(src) * a).round();
  int sb = (getBlue(src) * a).round();
  int sa = (getAlpha(src) * a).round();

  int dr = (getRed(dst) * (1.0 - a)).round();
  int dg = (getGreen(dst) * (1.0 - a)).round();
  int db = (getBlue(dst) * (1.0 - a)).round();
  int da = (getAlpha(dst) * (1.0 - a)).round();

  return getColor(sr + dr, sg + dg, sb + db, sa + da);
}

/**
 * Returns the luminance (grayscale) value of the [color].
 */
int getLuminance(int color) {
  int r = getRed(color);
  int g = getGreen(color);
  int b = getBlue(color);
  return (0.299 * r + 0.587 * g + 0.114 * b).round();
}

/**
 * Returns the luminance (grayscale) value of the color.
 */
int getLuminanceRGB(int r, int g, int b) =>
  (0.299 * r + 0.587 * g + 0.114 * b).round();

/**
 * Convert an HSL color to RGB, where h is specified in normalized degrees
 * [0, 1] (where 1 is 360-degrees); s and l are in the range [0, 1].
 * Returns a list [r, g, b] with values in the range [0, 255].
 */
List<int> hslToRGB(num hue, num saturation, num lightness) {
  if (saturation == 0) {
    int gray = (lightness * 255.0).toInt();
    return [gray, gray, gray];
  }

  hue2rgb(num p, num q, num t) {
    if (t < 0.0) {
      t += 1.0;
    }
    if (t > 1) {
      t -= 1.0;
    }
    if (t < 1.0 / 6.0) {
      return p + (q - p) * 6.0 * t;
    }
    if (t < 1.0 / 2.0) {
      return q;
    }
    if (t < 2.0 / 3.0) {
      return p + (q - p) * (2.0/3.0 - t) * 6.0;
    }
    return p;
  }

  var q = lightness < 0.5
          ? lightness * (1.0 + saturation)
          : lightness + saturation - lightness * saturation;
  var p = 2.0 * lightness - q;

  var r = hue2rgb(p, q, hue + 1.0 / 3.0);
  var g = hue2rgb(p, q, hue);
  var b = hue2rgb(p, q, hue - 1.0 / 3.0);

  return [(r * 255.0).round(), (g * 255.0).round(), (b * 255.0).round()];
}

/**
 * Convert an HSV color to RGB, where h is specified in normalized degrees
 * [0, 1] (where 1 is 360-degrees); s and l are in the range [0, 1].
 * Returns a list [r, g, b] with values in the range [0, 255].
 */
List<int> hsvToRGB(num hue, num saturation, num brightness) {
  if (saturation == 0) {
    var gray = (brightness * 255.0).round();
    return [gray, gray, gray];
  }

  double h = (hue - hue.floor()) * 6.0;
  double f = h - h.floor();
  double p = brightness * (1.0 - saturation);
  double q = brightness * (1.0 - saturation * f);
  double t = brightness * (1.0 - (saturation * (1.0 - f)));

  switch (h.toInt()) {
    case 0:
      return [(brightness * 255.0).round(),
              (t * 255.0).round(),
              (p * 255.0).round()];
    case 1:
      return [(q * 255.0).round(),
              (brightness * 255.0).round(),
              (p * 255.0).round()];
    case 2:
      return [(p * 255.0).round(),
              (brightness * 255.0).round(),
              (t * 255.0).round()];
    case 3:
      return [(p * 255.0).round(),
              (q * 255.0).round(),
              (brightness * 255.0).round()];
    case 4:
      return [(t * 255.0).round(),
              (p * 255.0).round(),
              (brightness * 255.0).round()];
    case 5:
      return [(brightness * 255.0).round(),
              (p * 255.0).round(),
              (q * 255.0).round()];
    default:
      throw new ImageException('invalid hue');
  }
}

/**
 * Convert an RGB color to HSL, where r, g and b are in the range [0, 255].
 * Returns a list [h, s, l] with values in the range [0, 1].
 */
List<double> rgbToHSL(num r, num g, num b) {
  r /= 255.0;
  g /= 255.0;
  b /= 255.0;
  var max = Math.max(r, Math.max(g, b));
  var min = Math.min(r, Math.min(g, b));
  var h;
  var s;
  var l = (max + min) / 2.0;

  if (max == min){
    return [0.0, 0.0, l];
  }

  var d = max - min;

  s = l > 0.5 ? d / (2.0 - max - min) : d / (max + min);

  if (max == r) {
    h = (g - b) / d + (g < b ? 6.0 : 0.0);
  } else if (max == g) {
    h = (b - r) / d + 2.0;
  } else {
    h = (r - g) / d + 4.0;
  }

  h /= 6.0;

  return [h, s, l];
}

/**
 * Convert a CIE-L*ab color to XYZ.
 */
List<int> labToXYZ(num l, num a, num b) {
  var y = (l + 16.0) / 116.0;
  var x = y + (a / 500.0);
  var z = y - (b / 200.0);
  if (Math.pow(x, 3) > 0.008856) {
    x = Math.pow(x, 3);
  } else {
    x = (x - 16.0 / 116) / 7.787;
  }
  if (Math.pow(y, 3) > 0.008856) {
    y = Math.pow(y, 3);
  } else {
    y = (y - 16.0 / 116.0) / 7.787;
  }
  if (Math.pow(z, 3) > 0.008856) {
    z = Math.pow(z, 3);
  } else {
    z = (z - 16.0 / 116.0) / 7.787;
  }

  return [(x * 95.047).toInt(), (y * 100.0).toInt(), (z * 108.883).toInt()];
}

/**
 * Convert an XYZ color to RGB.
 */
List<int> xyzToRGB(num x, num y, num z) {
  var b, g, r;
  x /= 100;
  y /= 100;
  z /= 100;
  r = (3.2406 * x) + (-1.5372 * y) + (-0.4986 * z);
  g = (-0.9689 * x) + (1.8758 * y) + (0.0415 * z);
  b = (0.0557 * x) + (-0.2040 * y) + (1.0570 * z);
  if (r > 0.0031308) {
    r = (1.055 * Math.pow(r, 0.4166666667)) - 0.055;
  } else {
    r *= 12.92;
  }
  if (g > 0.0031308) {
    g = (1.055 * Math.pow(g, 0.4166666667)) - 0.055;
  } else {
    g *= 12.92;
  }
  if (b > 0.0031308) {
    b = (1.055 * Math.pow(b, 0.4166666667)) - 0.055;
  } else {
    b *= 12.92;
  }

  return [(r * 255).toInt().clamp(0, 255),
          (g * 255).toInt().clamp(0, 255),
          (b * 255).toInt().clamp(0, 255)];
}

/**
 * Convert a CMYK color to RGB, where c, m, y, k values are in the range
 * [0, 255]. Returns a list [r, g, b] with values in the range [0, 255].
 */
List<int> cmykToRGB(num c, num m, num y, num k) {
  c /= 255.0;
  m /= 255.0;
  y /= 255.0;
  k /= 255.0;
  return [(255.0 * (1.0 - c) * (1.0 - k)).round(),
          (255.0 * (1.0 - m) * (1.0 - k)).round(),
          (255.0 * (1.0 - y) * (1.0 - k)).round()];
}

/**
 * Convert a CIE-L*ab color to RGB.
 */
List<int> labToRGB(num l, num a, num b) {
  const double ref_x = 95.047;
  const double ref_y = 100.000;
  const double ref_z = 108.883;

  double y = (l + 16.0) / 116.0;
  double x = a / 500.0 + y;
  double z = y - b / 200.0;

  double y3 = Math.pow(y, 3);
  if (y3 > 0.008856) {
    y = y3;
  } else {
    y = (y - 16 / 116) / 7.787;
  }

  double x3 = Math.pow(x,  3);
  if (x3 > 0.008856) {
    x = x3;
  } else {
    x = (x - 16 / 116) / 7.787;
  }

  double z3 = Math.pow(z, 3);
  if (z3 > 0.008856) {
    z = z3;
  } else {
    z = (z - 16 / 116) / 7.787;
  }

  x *= ref_x;
  y *= ref_y;
  z *= ref_z;

  x /= 100.0;
  y /= 100.0;
  z /= 100.0;

  // xyz to rgb
  double R = x * 3.2406 + y * (-1.5372) + z * (-0.4986);
  double G = x * (-0.9689) + y * 1.8758 + z * 0.0415;
  double B = x * 0.0557 + y * (-0.2040) + z * 1.0570;

  if (R > 0.0031308) {
    R = 1.055 * (Math.pow(R, 1.0 / 2.4)) - 0.055;
  } else {
    R = 12.92 * R;
  }

  if (G > 0.0031308) {
    G = 1.055 * (Math.pow(G, 1.0 / 2.4)) - 0.055;
  } else {
    G = 12.92 * G;
  }

  if (B > 0.0031308) {
    B = 1.055 * (Math.pow(B, 1.0 / 2.4)) - 0.055;
  } else {
    B = 12.92 * B;
  }

  return [(R * 255.0).toInt().clamp(0,  255),
          (G * 255.0).toInt().clamp(0,  255),
          (B * 255.0).toInt().clamp(0,  255)];
}

/**
 * Convert a RGB color to XYZ.
 */
List<double> rgbToXYZ(num r, num g, num b) {
  r = r / 255.0;
  g = g / 255.0;
  b = b / 255.0;

  if ( r > 0.04045 ) r = Math.pow((r + 0.055) / 1.055, 2.4);
  else               r = r / 12.92;
  if ( g > 0.04045 ) g = Math.pow((g + 0.055) / 1.055, 2.4);
  else               g = g / 12.92;
  if ( b > 0.04045 ) b = Math.pow((b + 0.055) / 1.055, 2.4);
  else               b = b / 12.92;

  r = r * 100.0;
  g = g * 100.0;
  b = b * 100.0;

  return [r * 0.4124 + g * 0.3576 + b * 0.1805,
          r * 0.2126 + g * 0.7152 + b * 0.0722,
          r * 0.0193 + g * 0.1192 + b * 0.9505];
}

/**
 * Convert a XYZ color to CIE-L*ab.
 */
List<double> xyzToLab(num x, num y, num z) {
  x = x / 95.047;
  y = y / 100.0;
  z = z / 108.883;

  if (x > 0.008856) x = Math.pow(x, 1/3.0);
  else              x = (7.787 * x) + (16 / 116.0);
  if (y > 0.008856) y = Math.pow(y, 1/3.0);
  else              y = (7.787 * y) + (16 / 116.0);
  if (z > 0.008856) z = Math.pow(z, 1/3.0);
  else              z = (7.787 * z) + (16 / 116.0);

  return [(116.0 * y) - 16,
          500.0 * (x - y),
          200.0 * (y - z)];
}

/**
 * Convert a RGB color to CIE-L*ab.
 */
List<double> rgbToLab(num r, num g, num b) {
  r = r / 255.0;
  g = g / 255.0;
  b = b / 255.0;

  if ( r > 0.04045 ) r = Math.pow((r + 0.055) / 1.055, 2.4);
  else               r = r / 12.92;
  if ( g > 0.04045 ) g = Math.pow((g + 0.055) / 1.055, 2.4);
  else               g = g / 12.92;
  if ( b > 0.04045 ) b = Math.pow((b + 0.055) / 1.055, 2.4);
  else               b = b / 12.92;

  r = r * 100.0;
  g = g * 100.0;
  b = b * 100.0;

  double x = r * 0.4124 + g * 0.3576 + b * 0.1805;
  double y = r * 0.2126 + g * 0.7152 + b * 0.0722;
  double z = r * 0.0193 + g * 0.1192 + b * 0.9505;

  x = x / 95.047;
  y = y / 100.0;
  z = z / 108.883;

  if (x > 0.008856) x = Math.pow(x, 1/3.0);
  else              x = (7.787 * x) + (16 / 116.0);
  if (y > 0.008856) y = Math.pow(y, 1/3.0);
  else              y = (7.787 * y) + (16 / 116.0);
  if (z > 0.008856) z = Math.pow(z, 1/3.0);
  else              z = (7.787 * z) + (16 / 116.0);

  return [(116.0 * y) - 16,
          500.0 * (x - y),
          200.0 * (y - z)];
}
