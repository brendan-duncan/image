part of image;

const int RED = 0;
const int GREEN = 1;
const int BLUE = 2;
const int ALPHA = 3;

int getColor(int r, int g, int b, [int a = 255]) {
  return ((r & 0xFF) << 24) |
         ((g & 0xFF) << 16) |
         ((b & 0xFF) << 8) |
         (a & 0xFF);
}

int getColorFromList(List<int> rgba) {
  return getColor(rgba.length > 0 ? rgba[0] : 0,
                  rgba.length > 1 ? rgba[1] : 0,
                  rgba.length > 2 ? rgba[2] : 0,
                  rgba.length > 3 ? rgba[3] : 255);
}

int getRed(int c) =>
    (c >> 24) & 0xFF;

int getGreen(int c) =>
    (c >> 16) & 0xFF;

int getBlue(int c) =>
    (c >> 8) & 0xFF;

int getAlpha(int c) =>
    c & 0xFF;

/**
 * Composite the color [src] onto the color [dst].
 */
int alphaBlendColors(int dst, int src) {
  double a = getAlpha(src) / 255.0;
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
