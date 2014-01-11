/**
 * The image library aims to provide server-side programs the ability to load,
 * manipulate, and save various image file formats.
 */
library image;

import 'dart:math' as Math;
import 'dart:typed_data' as Data;

import 'package:archive/archive.dart' as Arc;
import 'package:xml/xml.dart';

part 'src/formats/jpeg/_jpeg.dart';
part 'src/formats/jpeg/_jpeg_adobe.dart';
part 'src/formats/jpeg/_jpeg_component.dart';
part 'src/formats/jpeg/_jpeg_data.dart';
part 'src/formats/jpeg/_jpeg_frame.dart';
part 'src/formats/jpeg/_jpeg_jfif.dart';
part 'src/formats/jpeg/_jpeg_scan.dart';
part 'src/formats/formats.dart';
part 'src/formats/jpeg_decoder.dart';
part 'src/formats/jpeg_encoder.dart';
part 'src/formats/png_decoder.dart';
part 'src/formats/png_encoder.dart';
part 'src/formats/tga_decoder.dart';
part 'src/formats/tga_encoder.dart';

part 'src/draw/draw_char.dart';
part 'src/draw/draw_string.dart';
part 'src/draw/fill.dart';
part 'src/draw/fill_rectangle.dart';

part 'src/filter/brightness.dart';
part 'src/filter/color_offset.dart';
part 'src/filter/contrast.dart';
part 'src/filter/convolution.dart';
part 'src/filter/edge_detect_quick.dart';
part 'src/filter/emboss.dart';
part 'src/filter/copy_gaussian_blur.dart';
part 'src/filter/grayscale.dart';
part 'src/filter/mean_removal.dart';
part 'src/filter/negate.dart';
part 'src/filter/pixelate.dart';
part 'src/filter/remap_colors.dart';
part 'src/filter/smooth.dart';

part 'src/transform/copy_into.dart';
part 'src/transform/copy_crop.dart';
part 'src/transform/flip.dart';
part 'src/transform/copy_resize.dart';

part 'src/bitmap_font.dart';
part 'src/color.dart';
part 'src/image.dart';
part 'src/image_exception.dart';

