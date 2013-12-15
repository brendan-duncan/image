part of dart_image;

int color(int r, int g, int b, [int a = 255]) {
  return ((r & 0xFF) << 24) |
         ((g & 0xFF) << 16) |
         ((b & 0xFF) << 8) |
         (a & 0xFF);
}

int red(int c) =>
    (c >> 24) & 0xFF;

int green(int c) =>
    (c >> 16) & 0xFF;

int blue(int c) =>
    (c >> 8) & 0xFF;

int alpha(int c) =>
    c & 0xFF;
