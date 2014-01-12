part of image;

const int RED = 0;
const int GREEN = 1;
const int BLUE = 2;
const int ALPHA = 3;

int _clamp(int x, int a, int b) =>
  (x < a) ? a :
  (x > b) ? b :
  x;

int _clamp255(int x) => _clamp(x, 0, 255);

/**
 * Get the color with the given [r],[g],[b], and [a] components.
 */
int getColor(int r, int g, int b, [int a = 255]) {
  return (_clamp255(r) << 24) |
         (_clamp255(g) << 16) |
         (_clamp255(b) << 8) |
         _clamp255(a);
}

/**
 * Get the color with the given [r],[g],[b], and [a] components.
 */
int color(int r, int g, int b, [int a = 255]) => getColor(r, g, b, a);

/**
 * Get the color with the list of components.
 */
int getColorFromList(List<int> rgba) {
  return getColor(rgba.length > 0 ? rgba[0] : 0,
                  rgba.length > 1 ? rgba[1] : 0,
                  rgba.length > 2 ? rgba[2] : 0,
                  rgba.length > 3 ? rgba[3] : 255);
}

/**
 * Get the red component from the color.
 */
int getRed(int c) =>
    (c >> 24) & 0xff;

/**
 * Get the red component from the color.
 */
int red(int c) => getRed(c);

/**
 * Get the green component from the color.
 */
int getGreen(int c) =>
    (c >> 16) & 0xff;

/**
 * Get the green component from the color.
 */
int green(int c) => getGreen(c);

/**
 * Get the blue component from the color.
 */
int getBlue(int c) =>
    (c >> 8) & 0xff;

/**
 * Get the blue component from the color.
 */
int blue(int c) => getBlue(c);

/**
 * Get the alpha component from the color.
 */
int getAlpha(int c) =>
    c & 0xff;

/**
 * Get the alpha component from the color.
 */
int alpha(int c) => getAlpha(c);

/**
 *
 * Composite the color [src] onto the color [dst].  The [src] alpha is
 * scaled by [fraction], for anti-aliasing.
 */
int alphaBlendColors(int dst, int src, [int fraction = 0xff]) {
  double a = (alpha(src) / 255.0) * (fraction / 255.0);

  int sr = (red(src) * a).toInt();
  int sg = (green(src) * a).toInt();
  int sb = (blue(src) * a).toInt();
  int sa = (alpha(src) * a).toInt();

  int dr = (red(dst) * (1.0 - a)).toInt();
  int dg = (green(dst) * (1.0 - a)).toInt();
  int db = (blue(dst) * (1.0 - a)).toInt();
  int da = (alpha(dst) * (1.0 - a)).toInt();

  return color(sr + dr, sg + dg, sb + db, sa + da);
}
