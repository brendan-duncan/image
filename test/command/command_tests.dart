import 'package:test/test.dart';
import 'draw/draw_image_test.dart';
import 'draw/fill_test.dart';
import 'filter/filter_test.dart';
import 'image/create_image_test.dart';

void commandTests() {
  group('Command', () {
    createImageTest();
    drawImageTest();
    fillTest();
    filterTest();
  });
}
