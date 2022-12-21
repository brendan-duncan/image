import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../color/color.dart';
import '../color/format.dart';
import '../exif/exif_data.dart';
import '../font/bitmap_font.dart';
import '../formats/png_encoder.dart';
import '../image/icc_profile.dart';
import '../image/image.dart';
import '../image/palette.dart';
import '../util/interpolation.dart';
import '_executor.dart'
  if (dart.library.io) '_executor_io.dart'
  if (dart.library.js) '_executor_html.dart';
import 'draw/draw_char_cmd.dart';
import 'draw/fill_cmd.dart';
import 'formats/decode_image_file_cmd.dart';
import 'formats/encode_png_cmd.dart';
import 'formats/write_to_file_cmd.dart';
import 'image/create_image_cmd.dart';
import 'transform/copy_resize_cmd.dart';

/// Base class for commands that create, load, manipulate, and save images.
/// Commands are not executed until either the [execute] or [executeAsync]
/// methods are called.
class ImageCommand {
  ImageCommand? _command;
  bool dirty = true;
  Image? image;
  Uint8List? bytes;

  // image

  void create(int width, int height,
      { Format format = Format.uint8, int numChannels = 3,
        bool isFrame = false,
        bool withPalette = false,
        Format paletteFormat = Format.uint8,
        Palette? palette, ExifData? exif,
        IccProfile? iccp, Map<String, String>? textData }) {
    _command = CreateImageCmd(width, height, format: format,
        numChannels: numChannels, isFrame: isFrame, withPalette: withPalette,
        paletteFormat: paletteFormat, palette: palette, exif: exif,
        iccp: iccp, textData: textData);
  }

  // draw

  void fill(Color color) {
    _command = FillCmd(_command ?? this, color);
  }

  void drawChar(BitmapFont font, int x, int y,
      String char, { Color? color }) {
    _command = DrawCharCmd(_command ?? this, font, x, y, char,
        color: color);
  }

  // transform

  void copyResize({ int? width, int? height,
    Interpolation interpolation = Interpolation.nearest }) {
    _command = CopyResizeCmd(_command ?? this, width: width, height: height,
        interpolation: interpolation);
  }

  // formats

  void decodeImageFile(String path) {
    _command = DecodeImageFileCmd(path);
  }

  void encodePng({ int level = 6, PngFilter filter = PngFilter.paeth }) {
    _command = EncodePngCmd(_command ?? this, level: level, filter: filter);
  }

  void writeToFile(String path) {
    _command = WriteToFileCmd(_command ?? this, path);
  }

  void execute() {
    (_command ?? this).executeIfDirty();
  }

  Future<void> executeAsync() async {
    final cmdOrThis = _command ?? this;
    if (cmdOrThis.dirty) {
      await executeCommandAsync(cmdOrThis).then((value) {
        cmdOrThis
          ..dirty = false
          ..image = value.image
          ..bytes = value.bytes;
      });
    }
  }

  Image? getImage() {
    execute();
    return (_command ?? this).image;
  }

  Future<Image?> getImageAsync() async {
    await executeAsync();
    return (_command ?? this).image;
  }

  Uint8List? getBytes() {
    execute();
    return (_command ?? this).bytes;
  }

  Future<Uint8List?> getBytesAsync() async {
    await executeAsync();
    return (_command ?? this).bytes;
  }

  @protected
  void executeIfDirty() {
    if (dirty) {
      dirty = false;
      executeCommand();
    }
  }

  @protected
  void executeCommand() { }
}
