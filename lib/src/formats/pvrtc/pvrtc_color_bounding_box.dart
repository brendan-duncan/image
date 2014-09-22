part of image;

class PvrtcColorBoundingBox {
  PvrtcColorRgb min;
  PvrtcColorRgb max;

  PvrtcColorBoundingBox(PvrtcColorRgb min, PvrtcColorRgb max)
      : this.min = new PvrtcColorRgb.from(min)
      , this.max = new PvrtcColorRgb.from(max);

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
