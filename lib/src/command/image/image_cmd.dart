import '../../image/image.dart';
import '../command.dart';

class ImageCmd extends Command {
  ImageCmd(Image image) {
    this.image = image;
  }

  @override
  void executeCommand() { }
}
