import 'package:test/test.dart';

import 'adjust_color_test.dart';
import 'bump_to_normal_test.dart';
import 'color_offset_test.dart';
import 'contrast_test.dart';
import 'dither_test.dart';
import 'drop_shadow_test.dart';
import 'emboss_test.dart';
import 'gaussian_blur_test.dart';
import 'grayscale_test.dart';
import 'invert_test.dart';
import 'noise_test.dart';
import 'normalize_test.dart';
import 'pixelate_test.dart';
import 'quantize_test.dart';
import 'remap_colors_test.dart';
import 'scale_rgba_test.dart';
import 'sepia_test.dart';
import 'smooth_test.dart';
import 'sobel_test.dart';
import 'vignette_test.dart';

void filterTests() {
  group('filter', () {
    adjustColorTest();
    bumpToNormalTest();
    colorOffsetTest();
    contrastTest();
    ditherTest();
    embossTest();
    gaussianBlurTest();
    grayscaleTest();
    invertTest();
    noiseTest();
    normalizeTest();
    pixelateTest();
    quantizeTest();
    remapColorsTest();
    scaleRgbaTest();
    sepiaTest();
    smoothTest();
    sobelTest();
    vignetteTest();
    dropShadowTest();
  });
}
