import '../../color/format.dart';
import '../../exif/exif_data.dart';
import '../../image/icc_profile.dart';
import '../../image/image.dart';
import '../../image/palette.dart';
import '../image_command.dart';

class CreateImageCmd extends ImageCommand {
  int width;
  int height;
  Format format = Format.uint8;
  int numChannels = 3;
  bool isFrame = false;
  bool withPalette = false;
  Format paletteFormat = Format.uint8;
  Palette? palette;
  ExifData? exif;
  IccProfile? iccp;
  Map<String, String>? textData;

  CreateImageCmd(this.width, this.height, { this.format = Format.uint8,
      this.numChannels = 3, this.isFrame = false, this.withPalette = false,
      this.paletteFormat = Format.uint8, this.palette, this.exif, this.iccp,
      this.textData });

  @override
  void executeCommand() {
    image = Image(width, height, format: format, numChannels: numChannels,
        isFrame: isFrame, withPalette: withPalette,
        paletteFormat: paletteFormat, palette: palette, exif: exif, iccp: iccp,
        textData: textData);
  }
}
