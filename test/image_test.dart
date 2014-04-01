library image_test;

import 'dart:io' as Io;
import 'package:image/image.dart';
import 'package:unittest/unittest.dart';

part 'exr_test.dart';
part 'filter_test.dart';
part 'font_test.dart';
part 'gif_test.dart';
part 'half_test.dart';
part 'jpeg_test.dart';
part 'png_test.dart';
part 'psd_test.dart';
part 'tga_test.dart';
part 'tiff_test.dart';
part 'webp_test.dart';

void main() {
  defineExrTests();
  definePsdTests();
  defineJpegTests();
  definePngTests();
  defineGifTests();
  defineTgaTests();
  defineTiffTests();
  defineFontTests();
  defineWebPTests();
  defineFilterTests();
  defineHalfTests();
}
