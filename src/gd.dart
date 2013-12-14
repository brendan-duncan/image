/**
 * The GD library aims to provide similar functionality for server-side programs
 * that the PHP GD library provides for image io and manipulation.  It can
 * encode/decode various image formats and provides basic image drawing and
 * manipulation functions.
 */
library gd;

import 'dart:typed_data' as Data;

part 'image.dart';
part 'jpeg_decoder.dart';
part 'jpeg_encoder.dart';
part '_byte_buffer.dart';
