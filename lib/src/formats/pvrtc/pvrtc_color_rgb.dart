part of image;

class PvrtcColorRgb {
  int r;
  int g;
  int b;

  PvrtcColorRgb([this.r = 0, this.g = 0, this.b = 0]);

  PvrtcColorRgb operator *(int x) =>
    new PvrtcColorRgb(r * x, g * x, b * x);

  PvrtcColorRgb operator +(PvrtcColorRgb x) =>
      new PvrtcColorRgb(r + x.r, g + x.g, b + x.b);

  PvrtcColorRgb operator -(PvrtcColorRgb x) =>
      new PvrtcColorRgb(r - x.r, g - x.g, b - x.b);

  int operator %(PvrtcColorRgb x) =>
      r * x.r + g * x.g + b * x.b;
}
