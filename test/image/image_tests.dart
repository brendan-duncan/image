import 'package:test/test.dart';

import 'image_float16_test.dart';
import 'image_float32_test.dart';
import 'image_float64_test.dart';
import 'image_int16_test.dart';
import 'image_int32_test.dart';
import 'image_int8_test.dart';
import 'image_test.dart';
import 'image_uint16_test.dart';
import 'image_uint1_test.dart';
import 'image_uint2_test.dart';
import 'image_uint32_test.dart';
import 'image_uint4_test.dart';
import 'image_uint8_test.dart';

void imageTests() {
  group('image', () {
    imageUint1Test();
    imageUint2Test();
    imageUint4Test();
    imageUint8Test();
    imageUint16Test();
    imageUint32Test();
    imageInt8Test();
    imageInt16Test();
    imageInt32Test();
    imageFloat16Test();
    imageFloat32Test();
    imageFloat64Test();
    imageTest();
  });
}
