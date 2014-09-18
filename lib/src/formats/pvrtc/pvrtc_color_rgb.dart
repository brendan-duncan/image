part of image;

class PvrTcColorRgb {
  int r;
  int g;
  int b;

  PvrTcColorRgb([this.r = 0, this.g = 0, this.b = 0]);

  PvrTcColorRgb operator*(int x) =>
    new PvrTcColorRgb(r * x, g * x, b * x);

  PvrTcColorRgb operator+(PvrTcColorRgb x) =>
      new PvrTcColorRgb(r + x.r, g + x.g, b + x.b);

  PvrTcColorRgb operator-(PvrTcColorRgb x) =>
      new PvrTcColorRgb(r - x.r, g - x.g, b - x.b);

  int operator%(PvrTcColorRgb x) =>
      r * x.r + g * x.g + b * x.b;
}
