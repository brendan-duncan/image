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
 * Get the color with the list of components.
 */
int getColorFromList(List<int> rgba) {
  return getColor(rgba.length > 0 ? rgba[0] : 0,
                  rgba.length > 1 ? rgba[1] : 0,
                  rgba.length > 2 ? rgba[2] : 0,
                  rgba.length > 3 ? rgba[3] : 255);
}

/**
 * Get the channel from the color.
 */
int getChannel(int c, int ch) =>
    ch == 0 ? getRed(c) :
    ch == 1 ? getGreen(c) :
    ch == 2 ? getBlue(c) :
    getAlpha(c);

int setChannel(int c, int ch, int v) =>
    ch == 0 ? setRed(c, v) :
    ch == 1 ? setGreen(c, v) :
    ch == 2 ? setBlue(c, v) :
    setAlpha(c, v);

/**
 * Get the red component from the color.
 */
int getRed(int c) =>
    (c >> 24) & 0xff;

/**
 * Set the red component of the color.
 */
int setRed(int c, int v) =>
    (c & 0x00ffffff) | (_clamp255(v) << 24);

/**
 * Get the green component from the color.
 */
int getGreen(int c) =>
    (c >> 16) & 0xff;

/**
 * Set the green component of the color.
 */
int setGreen(int c, int v) =>
    (c & 0xff00ffff) | (_clamp255(v) << 16);

/**
 * Get the blue component from the color.
 */
int getBlue(int c) =>
    (c >> 8) & 0xff;

/**
 * Set the blue component of the color.
 */
int setBlue(int c, int v) =>
    (c & 0xffff00ff) | (_clamp255(v) << 8);

/**
 * Get the alpha component from the color.
 */
int getAlpha(int c) =>
    c & 0xff;

/**
 * Set the alpha component of the color.
 */
int setAlpha(int c, int v) =>
    (c & 0xffffff00) | (_clamp255(v));

/**
 *
 * Composite the color [src] onto the color [dst].  The [src] alpha is
 * scaled by [fraction], for anti-aliasing.
 */
int alphaBlendColors(int dst, int src, [int fraction = 0xff]) {
  double a = (getAlpha(src) / 255.0) * (fraction / 255.0);

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
