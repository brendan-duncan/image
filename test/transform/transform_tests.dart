import 'copy_crop_test.dart';
import 'copy_flip_test.dart';
import 'copy_rectify_test.dart';
import 'copy_resize_crop_square_test.dart';
import 'copy_resize_test.dart';
import 'copy_rotate_test.dart';
import 'trim_test.dart';

void transformTests() {
  copyCropTest();
  copyRectifyTest();
  copyResizeTest();
  copyRotateTest();
  copyFlipTest();
  copyResizeCropSquareTest();
  trimTest();
}
