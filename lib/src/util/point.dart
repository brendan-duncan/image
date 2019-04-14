
class Point {
  num x;
  num y;

  get xi { return x.toInt(); }
  get yi { return y.toInt(); }

  Point([this.x = 0, this.y = 0]);

  Point.from(Point other)
    : x = other.x
    , y = other.y;

  Point operator*(double s) {
    return Point(x * s, y * s);
  }

  Point operator+(Point rhs) {
    return Point(x + rhs.x, y + rhs.y);
  }
}
