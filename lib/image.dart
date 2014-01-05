/**
 * The image library aims to provide server-side programs the ability to load,
 * manipulate, and save various image file formats.
 */
library image;

import 'dart:async' as Async;
import 'dart:typed_data' as Data;

import 'package:archive/archive.dart' as Arc;
import 'package:xml/xml.dart';

part 'src/jpeg/_jpeg.dart';
part 'src/jpeg/_jpeg_adobe.dart';
part 'src/jpeg/_jpeg_component.dart';
part 'src/jpeg/_jpeg_data.dart';
part 'src/jpeg/_jpeg_frame.dart';
part 'src/jpeg/_jpeg_jfif.dart';
part 'src/jpeg/_jpeg_scan.dart';

part 'src/bitmap_font.dart';
part 'src/color.dart';
part 'src/image.dart';
part 'src/image_exception.dart';
part 'src/jpeg_decoder.dart';
part 'src/jpeg_encoder.dart';
part 'src/png_decoder.dart';
part 'src/png_encoder.dart';
part 'src/tga_decoder.dart';
part 'src/tga_encoder.dart';
