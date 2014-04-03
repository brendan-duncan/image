part of image;

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


int _clamp(int x, int a, int b) => x.clamp(a, b);

int _clamp255(int x) => x.clamp(0, 255);

/**
 * Get the color with the given [r], [g], [b], and [a] components.
 */
int getColor(int r, int g, int b, [int a = 255]) {
  return (_clamp255(a) << 24) |
         (_clamp255(b) << 16) |
         (_clamp255(g) << 8) |
         _clamp255(r);
}

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
    (color & 0xffffff00) | (_clamp255(value));

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
    (color & 0xffff00ff) | (_clamp255(value) << 8);

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
    (color & 0xff00ffff) | (_clamp255(value) << 16);

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
    (color & 0x00ffffff) | (_clamp255(value) << 24);

/**
 * Returns a new color of [src] alpha-blended onto [dst]. The opacity of [src]
 * is additionally scaled by [fraction] / 255.
 */
int alphaBlendColors(int dst, int src, [int fraction = 0xff]) {
  double a = (getAlpha(src) / 255.0);
  if (fraction != 0xff) {
    a *= (fraction / 255.0);
  }

  int sr = (getRed(src) * a).toInt();
  int sg = (getGreen(src) * a).toInt();
  int sb = (getBlue(src) * a).toInt();
  int sa = (getAlpha(src) * a).toInt();

  int dr = (getRed(dst) * (1.0 - a)).toInt();
  int dg = (getGreen(dst) * (1.0 - a)).toInt();
  int db = (getBlue(dst) * (1.0 - a)).toInt();
  int da = (getAlpha(dst) * (1.0 - a)).toInt();

  return getColor(sr + dr, sg + dg, sb + db, sa + da);
}

/**
 * Returns the luminance (grayscale) value of the [color].
 */
int getLuminance(int color) {
  int r = getRed(color);
  int g = getGreen(color);
  int b = getBlue(color);
  return (0.299 * r + 0.587 * g + 0.114 * b).toInt();
}

/**
 * Returns the luminance (grayscale) value of the color.
 */
int getLuminanceRGB(int r, int g, int b) {
  return (0.299 * r + 0.587 * g + 0.114 * b).toInt();
}


/**
 * Convert Lab color to XYZ.
 */
List<int> labToXYZ(int l, int a, int b) {
  var x, y, z;
  y = (l + 16) / 116;
  x = y + (a / 500);
  z = y - (b / 200);
  if (Math.pow(x, 3) > 0.008856) {
    x = Math.pow(x, 3);
  } else {
    x = (x - 16 / 116) / 7.787;
  }
  if (Math.pow(y, 3) > 0.008856) {
    y = Math.pow(y, 3);
  } else {
    y = (y - 16 / 116) / 7.787;
  }
  if (Math.pow(z, 3) > 0.008856) {
    z = Math.pow(z, 3);
  } else {
    z = (z - 16 / 116) / 7.787;
  }

  return [(x * 95.047).toInt(), (y * 100.0).toInt(), (z * 108.883).toInt()];
}

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

List<int> cmykToRGB(int c, int m, int y, int k) {
  int r = (65535 - (c * (255 - k) + (k << 8))) >> 8;
  int g = (65535 - (m * (255 - k) + (k << 8))) >> 8;
  int b = (65535 - (y * (255 - k) + (k << 8))) >> 8;
  return [r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255)];
}

/**
 * Convert Lab color to RGB.
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
    R = 1.055 * (Math.pow(R, 1 / 2.4)) - 0.055;
  } else {
    R = 12.92 * R;
  }

  if (G > 0.0031308) {
    G = 1.055 * (Math.pow(G, 1 / 2.4)) - 0.055;
  } else {
    G = 12.92 * G;
  }

  if (B > 0.0031308) {
    B = 1.055 * (Math.pow(B, 1 / 2.4)) - 0.055;
  } else {
    B = 12.92 * B;
  }

  return [(R * 255.0).toInt().clamp(0,  255),
          (G * 255.0).toInt().clamp(0,  255),
          (B * 255.0).toInt().clamp(0,  255)];
}
