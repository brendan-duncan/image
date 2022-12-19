import 'color/color_tests.dart';
import 'draw/draw_tests.dart';
import 'exif/exif_tests.dart';
import 'filter/filter_tests.dart';
import 'font/font_tests.dart';
import 'formats/format_tests.dart';
import 'image/image_tests.dart';
import 'transform/transform_tests.dart';
import 'util/util_tests.dart';

void main() {
  colorTests();
  exifTests();
  fontTests();
  utilTests();
  imageTests();
  drawTests();
  filterTests();
  transformTests();
  formatTests();
}
