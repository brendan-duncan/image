import 'package:test/test.dart';
import 'draw/fill_test.dart';
import 'image/for_each_frame_test.dart';

void commandTests() {
  group('Command', () {
    fillTest();
    forEachFrameTest();
  });
}
