import 'package:test/test.dart';

import 'color_float16_test.dart';
import 'color_float32_test.dart';
import 'color_float64_test.dart';
import 'color_int16_test.dart';
import 'color_int32_test.dart';
import 'color_int8_test.dart';
import 'color_uint16_test.dart';
import 'color_uint1_test.dart';
import 'color_uint2_test.dart';
import 'color_uint32_test.dart';
import 'color_uint4_test.dart';
import 'color_uint8_test.dart';

void ColorTests() {
  group('Color', () {
    ColorUint1Test();
    ColorUint2Test();
    ColorUint4Test();
    ColorUint8Test();
    ColorUint16Test();
    ColorUint32Test();
    ColorFloat16Test();
    ColorFloat32Test();
    ColorFloat64Test();
    ColorInt8Test();
    ColorInt16Test();
    ColorInt32Test();
  });
}
