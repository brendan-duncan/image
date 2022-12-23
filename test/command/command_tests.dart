import 'package:test/test.dart';
import 'draw/fill_test.dart';
import 'filter/filter_test.dart';

void commandTests() {
  group('Command', () {
    fillTest();
    filterTest();
  });
}
