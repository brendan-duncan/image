import 'dart:typed_data';

import '../../filter/dither_image.dart';
import '../../formats/formats.dart';
import '../command.dart';
import '_file_access.dart'
if (dart.library.io) '_file_access_io.dart'
if (dart.library.js) '_file_access_html.dart';

/// Decode a GIF Image from byte [data].
class DecodeGifCmd extends Command {
  Uint8List data;

  DecodeGifCmd(this.data);

  @override
  Future<void> executeCommand() async {
    outputImage = decodeGif(data);
  }
}

/// Decode a GIF Image from a file at the given [path].
class DecodeGifFileCmd extends Command {
  String path;

  DecodeGifFileCmd(this.path);

  @override
  Future<void> executeCommand() async {
    final bytes = await readFile(path);
    outputImage = bytes != null ? decodeGif(bytes) : null;
  }
}

/// Encode an Image to the GIF format.
class EncodeGifCmd extends Command {
  int samplingFactor;
  DitherKernel dither;
  bool ditherSerpentine;

  EncodeGifCmd(Command? input, {
      this.samplingFactor = 10,
      this.dither = DitherKernel.floydSteinberg,
      this.ditherSerpentine = false })
    : super(input);

  @override
  Future<void> executeCommand() async {
    await input?.execute();
    outputImage = input?.outputImage;
    if (outputImage != null) {
      outputBytes = encodeGif(outputImage!, samplingFactor: samplingFactor,
          dither: dither, ditherSerpentine: ditherSerpentine);
    }
  }
}

/// Encode an Image to the GIF format and write it to a file at the given
/// [path].
class EncodeGifFileCmd extends EncodeGifCmd {
  String path;

  EncodeGifFileCmd(Command? input, this.path, {
      int samplingFactor = 10,
      DitherKernel dither = DitherKernel.floydSteinberg,
      bool ditherSerpentine = false })
      : super(input, samplingFactor: samplingFactor, dither: dither,
          ditherSerpentine: ditherSerpentine);

  @override
  Future<void> executeCommand() async {
    await super.executeCommand();
    if (outputBytes != null) {
      await writeFile(path, outputBytes!);
    }
  }
}
