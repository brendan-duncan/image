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

void ImageTests() {
  group('Image', () {
    ImageUint1Test();
    ImageUint2Test();
    ImageUint4Test();
    ImageUint8Test();
    ImageUint16Test();
    ImageUint32Test();
    ImageInt8Test();
    ImageInt16Test();
    ImageInt32Test();
    ImageFloat16Test();
    ImageFloat32Test();
    ImageFloat64Test();
    ImageTest();
  });
}
