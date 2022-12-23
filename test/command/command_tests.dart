import 'package:test/test.dart';
import 'draw/fill_test.dart';
import 'image/animated_image_filter_test.dart';

void commandTests() {
  group('Command', () {
    fillTest();
    animatedImageFilterTest();
  });
}
