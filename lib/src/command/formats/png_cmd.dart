import 'dart:typed_data';

import '../../formats/formats.dart';
import '../../formats/png_encoder.dart';
import '../command.dart';
import '_file_access.dart'
if (dart.library.io) '_file_access_io.dart'
if (dart.library.js) '_file_access_html.dart';

/// Decode a PNG Image from byte data.
class DecodePngCmd extends Command {
  final Uint8List _data;

  DecodePngCmd(this._data);

  @override
  Future<void> executeCommand() async {
    outputImage = decodePng(_data);
  }
}

/// Decode a PNG Image from a file at the given path.
class DecodePngFileCmd extends Command {
  final String _path;

  DecodePngFileCmd(String path)
      : _path = path;

  @override
  Future<void> executeCommand() async {
    final bytes = await readFile(_path);
    outputImage = bytes != null ? decodePng(bytes) : null;
  }
}

/// Encode an Image to the PNG format.
class EncodePngCmd extends Command {
  final int _level;
  final PngFilter _filter;

  EncodePngCmd(Command? input, { int level = 6,
      PngFilter filter = PngFilter.paeth })
      : _level = level
      , _filter = filter
      , super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      outputBytes = encodePng(outputImage!, level: _level, filter: _filter);
    }
  }
}

/// Encode an Image to the PNG format and write it to a file at the given
/// path.
class EncodePngFileCmd extends EncodePngCmd {
  final String _path;

  EncodePngFileCmd(Command? input, String path, { int level = 6,
      PngFilter filter = PngFilter.paeth })
      : _path = path
      , super(input, level: level, filter: filter);

  @override
  Future<void> executeCommand() async {
    await super.executeCommand();
    if (outputBytes != null) {
      await writeFile(_path, outputBytes!);
    }
  }
}
