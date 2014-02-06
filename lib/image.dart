/**
 * The image library aims to provide server-side programs the ability to load,
 * manipulate, and save various image file formats.
 */
library image;

import 'dart:math' as Math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

part 'src/draw/draw_char.dart';
part 'src/draw/draw_circle.dart';
part 'src/draw/draw_line.dart';
part 'src/filter/noise.dart';
part 'src/draw/draw_pixel.dart';
part 'src/draw/draw_rect.dart';
part 'src/draw/draw_string.dart';
part 'src/draw/fill.dart';
part 'src/draw/fill_rect.dart';

part 'src/effects/drop_shadow.dart';

part 'src/filter/brightness.dart';
part 'src/filter/bump_to_normal.dart';
part 'src/filter/color_offset.dart';
part 'src/filter/contrast.dart';
part 'src/filter/convolution.dart';
part 'src/filter/emboss.dart';
part 'src/filter/gaussian_blur.dart';
part 'src/filter/grayscale.dart';
part 'src/filter/invert.dart';
part 'src/filter/normalize.dart';
part 'src/filter/pixelate.dart';
part 'src/filter/remap_colors.dart';
part 'src/filter/seperable_convolution.dart';
part 'src/filter/seperable_kernel.dart';
part 'src/filter/smooth.dart';

part 'src/fonts/arial_14.dart';
part 'src/fonts/arial_24.dart';
part 'src/fonts/arial_48.dart';

part 'src/formats/gif/gif_color_map.dart';
part 'src/formats/gif/gif_image_desc.dart';
part 'src/formats/gif/gif_info.dart';
part 'src/formats/jpeg/jpeg.dart';
part 'src/formats/jpeg/jpeg_adobe.dart';
part 'src/formats/jpeg/jpeg_component.dart';
part 'src/formats/jpeg/jpeg_data.dart';
part 'src/formats/jpeg/jpeg_frame.dart';
part 'src/formats/jpeg/jpeg_jfif.dart';
part 'src/formats/jpeg/jpeg_scan.dart';
part 'src/formats/webp/vp8.dart';
part 'src/formats/webp/vp8_bit_reader.dart';
part 'src/formats/webp/vp8_filter.dart';
part 'src/formats/webp/vp8_types.dart';
part 'src/formats/webp/vp8l.dart';
part 'src/formats/webp/vp8l_bit_reader.dart';
part 'src/formats/webp/vp8l_color_cache.dart';
part 'src/formats/webp/vp8l_transform.dart';
part 'src/formats/webp/webp_alpha.dart';
part 'src/formats/webp/webp_filters.dart';
part 'src/formats/webp/webp_frame.dart';
part 'src/formats/webp/webp_huffman.dart';
part 'src/formats/webp/webp_info.dart';
part 'src/formats/decoder.dart';
part 'src/formats/formats.dart';
part 'src/formats/gif_decoder.dart';
part 'src/formats/jpeg_decoder.dart';
part 'src/formats/jpeg_encoder.dart';
part 'src/formats/png_decoder.dart';
part 'src/formats/png_encoder.dart';
part 'src/formats/tga_decoder.dart';
part 'src/formats/tga_encoder.dart';
part 'src/formats/webp_decoder.dart';

part 'src/transform/copy_into.dart';
part 'src/transform/copy_crop.dart';
part 'src/transform/copy_resize.dart';
part 'src/transform/copy_rotate.dart';
part 'src/transform/flip.dart';
part 'src/transform/trim.dart';

part 'src/util/clip_line.dart';
part 'src/util/interpolation.dart';
part 'src/util/min_max.dart';
part 'src/util/random.dart';

part 'src/animation.dart';
part 'src/bitmap_font.dart';
part 'src/color.dart';
part 'src/image.dart';
part 'src/image_exception.dart';

