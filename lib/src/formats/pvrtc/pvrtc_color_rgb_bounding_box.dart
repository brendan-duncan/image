part of image;

class PvrTcColorRgbBoundingBox {
  PvrTcColorRgb min;
  PvrTcColorRgb max;

  PvrTcColorRgbBoundingBox(this.min, this.max);

  void add(PvrTcColorRgb c) {
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
