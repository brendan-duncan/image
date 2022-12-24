import 'package:test/test.dart';
import 'draw/draw_image_test.dart';
import 'draw/fill_test.dart';
import 'filter/filter_test.dart';

void commandTests() {
  group('Command', () {
    drawImageTest();
    fillTest();
    filterTest();
  });
}
