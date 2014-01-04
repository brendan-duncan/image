library image_test;

import 'dart:io' as Io;
import 'package:image/image.dart';
import 'package:unittest/unittest.dart';

part 'jpeg_test.dart';
part 'png_test.dart';
part 'tga_test.dart';

void main() {
  defineTgaTests();
  defineJpegTests();
  definePngTests();
}
