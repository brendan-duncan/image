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


int _clamp(int x, int a, int b) =>
  (x < a) ? a :
  (x > b) ? b :
  x;

int _clamp255(int x) => _clamp(x, 0, 255);

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
