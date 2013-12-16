part of dart_image;

int color(int r, int g, int b, [int a = 255]) {
  return ((r & 0xFF) << 24) |
         ((g & 0xFF) << 16) |
         ((b & 0xFF) << 8) |
         (a & 0xFF);
}

int colorFromList(List<int> rgba) {
  return color(rgba.length > 0 ? rgba[0] : 0,
               rgba.length > 1 ? rgba[1] : 0,
               rgba.length > 2 ? rgba[2] : 0,
               rgba.length > 3 ? rgba[3] : 255);
}

int red(int c) =>
    (c >> 24) & 0xFF;

int green(int c) =>
    (c >> 16) & 0xFF;

int blue(int c) =>
    (c >> 8) & 0xFF;

int alpha(int c) =>
    c & 0xFF;
