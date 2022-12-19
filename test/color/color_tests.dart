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

void colorTests() {
  group('color', () {
    colorUint1Test();
    colorUint2Test();
    colorUint4Test();
    colorUint8Test();
    colorUint16Test();
    colorUint32Test();
    colorFloat16Test();
    colorFloat32Test();
    colorFloat64Test();
    colorInt8Test();
    colorInt16Test();
    colorInt32Test();
  });
}
