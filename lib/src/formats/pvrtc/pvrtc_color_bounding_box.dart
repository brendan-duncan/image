import 'pvrtc_color.dart';

class PvrtcColorBoundingBox<PvrtcColor extends PvrtcColorRgbCore<PvrtcColor>> {
  PvrtcColor min;
  PvrtcColor max;

  PvrtcColorBoundingBox(PvrtcColor min, PvrtcColor max)
      : min = min.copy(),
        max = max.copy();

  void add(PvrtcColor c) {
    min.setMin(c);
    max.setMax(c);
  }
}
