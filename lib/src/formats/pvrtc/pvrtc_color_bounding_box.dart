class PvrtcColorBoundingBox {
  dynamic min;
  dynamic max;

  PvrtcColorBoundingBox(dynamic min, dynamic max)
      : this.min = min.copy(),
        this.max = max.copy();

  void add(dynamic c) {
    min.setMin(c);
    max.setMax(c);
  }
}
