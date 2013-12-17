/**
 * The image library aims to provide server-side programs the ability to load,
 * manipulate, and save various image file formats.
 */
library dart_image;

import 'dart:io' as Io;
import 'dart:typed_data' as Data;

part 'src/color.dart';
part 'src/image.dart';
part 'src/jpeg_decoder.dart';
part 'src/jpeg_encoder.dart';
part 'src/png_decoder.dart';
part 'src/png_encoder.dart';
part 'src/tga_encoder.dart';
part 'src/_byte_buffer.dart';

/**
 * The largest value that can be stored in a Dart medium-int data.
 * Dart VM optimizes for expressions such as: a = (b << c) & MAX_INT;
 * because it can know ahead of time that the expression will always fit
 * into a mint data.
 */
const int MAX_INT = 0x3FFFFFFF;
