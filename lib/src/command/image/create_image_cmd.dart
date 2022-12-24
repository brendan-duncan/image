import '../../color/format.dart';
import '../../exif/exif_data.dart';
import '../../image/icc_profile.dart';
import '../../image/image.dart';
import '../../image/palette.dart';
import '../command.dart';

class CreateImageCmd extends Command {
  int width;
  int height;
  Format format;
  int numChannels;
  bool withPalette;
  Format paletteFormat;
  Palette? palette;
  ExifData? exif;
  IccProfile? iccp;
  Map<String, String>? textData;

  CreateImageCmd(this.width, this.height, { this.format = Format.uint8,
      this.numChannels = 3, this.withPalette = false,
      this.paletteFormat = Format.uint8, this.palette, this.exif, this.iccp,
      this.textData });

  @override
  void executeCommand() {
    outputImage = Image(width, height, format: format, numChannels: numChannels,
        withPalette: withPalette,
        paletteFormat: paletteFormat, palette: palette, exif: exif, iccp: iccp,
        textData: textData);
  }
}
