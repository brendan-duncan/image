import 'package:test/test.dart';

import 'draw_char_test.dart';
import 'draw_circle_test.dart';
import 'draw_image_test.dart';
import 'draw_line_test.dart';
import 'draw_pixel_test.dart';
import 'draw_rect_test.dart';
import 'draw_string_test.dart';
import 'fill_circle_test.dart';
import 'fill_flood_test.dart';
import 'fill_rect_test.dart';
import 'fill_test.dart';

void DrawTests() {
  group('Draw', () {
    DrawPixelTest();
    DrawCharTest();
    DrawCircleTest();
    DrawImageTest();
    DrawLineTest();
    DrawRectTest();
    DrawStringTest();
    FillCircleTest();
    FillFloodTest();
    FillRectTest();
    FillTest();
  });
}
