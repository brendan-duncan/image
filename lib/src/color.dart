part of dart_image;

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
