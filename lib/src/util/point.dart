/// 2-dimensional point
class Point {
  num x;
  num y;

  int get xi {
    return x.toInt();
  }

  int get yi {
    return y.toInt();
  }

  Point([this.x = 0, this.y = 0]);

  Point.from(Point other)
      : x = other.x,
        y = other.y;

  Point operator *(double s) {
    return Point(x * s, y * s);
  }

  Point operator +(Point rhs) {
    return Point(x + rhs.x, y + rhs.y);
  }

  @override
  bool operator ==(dynamic other) =>
      other is Point && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}
