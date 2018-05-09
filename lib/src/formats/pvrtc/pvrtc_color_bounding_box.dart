class PvrtcColorBoundingBox {
  var min;
  var max;

  PvrtcColorBoundingBox(min, max)
      : this.min = min.copy()
      , this.max = max.copy();

  void add(c) {
    min.setMin(c);
    max.setMax(c);
  }
}
