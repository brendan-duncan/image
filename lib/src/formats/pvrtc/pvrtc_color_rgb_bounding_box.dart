part of image;

class PvrtcColorRgbBoundingBox {
  PvrtcColorRgb min;
  PvrtcColorRgb max;

  PvrtcColorRgbBoundingBox(this.min, this.max);

  void add(PvrtcColorRgb c) {
    if (c.r < min.r) {
      min.r = c.r;
    }
    if (c.g < min.g) {
      min.g = c.g;
    }
    if (c.b < min.b) {
      min.b = c.b;
    }

    if (c.r > max.r) {
      max.r = c.r;
    }
    if (c.g > max.g) {
      max.g = c.g;
    }
    if (c.b > max.b) {
      max.b = c.b;
    }
  }
}
