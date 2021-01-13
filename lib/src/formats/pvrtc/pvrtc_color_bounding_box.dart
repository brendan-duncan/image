
class PvrtcColorBoundingBox {
  dynamic min;
  dynamic max;

  PvrtcColorBoundingBox(dynamic min, dynamic max)
      : min = min.copy(),
        max = max.copy();

  void add(dynamic c) {
    min.setMin(c);
    max.setMax(c);
  }
}
