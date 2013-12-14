/**
 * The GD library aims to provide similar functionality for server-side programs
 * that the PHP GD library provides for image io and manipulation.  It can
 * encode/decode various image formats and provides basic image drawing and
 * manipulation functions.
 */
library gd;

import 'dart:typed_data' as Data;

part 'src/color.dart';
part 'src/image.dart';
part 'src/jpeg_decoder.dart';
part 'src/jpeg_encoder.dart';
part 'src/tga_encoder.dart';
part 'src/_byte_buffer.dart';
