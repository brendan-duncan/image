part of image;

class PvrtcColor {
  int r;
  int g;
  int b;

  PvrtcColor([this.r = 0, this.g = 0, this.b = 0]);

  PvrtcColor operator *(int x) =>
    new PvrtcColor(r * x, g * x, b * x);

  PvrtcColor operator +(PvrtcColor x) =>
      new PvrtcColor(r + x.r, g + x.g, b + x.b);

  PvrtcColor operator -(PvrtcColor x) =>
      new PvrtcColor(r - x.r, g - x.g, b - x.b);

  int operator %(PvrtcColor x) =>
      r * x.r + g * x.g + b * x.b;
}
