import '../../image/image.dart';
import '../command.dart';

typedef FilterFunction = Image Function(Image image);

/// Execute an arbitrary filter function as an ImageCommand.
class FilterCmd extends Command {
  final FilterFunction _filter;

  FilterCmd(Command? input, this._filter)
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    final newImages = <Image>[];
    var hasNewImage = false;
    if (img != null) {
      for (final frame in img.frames) {
        final img2 = _filter(frame);
        if (img2 != frame) {
          hasNewImage = true;
        }
        newImages.add(img2);
      }
    }

    if (hasNewImage) {
      image = newImages.first == img ? Image.from(img!, noAnimation: true)
          : newImages[0];
      final numFrames = newImages.length;
      for (var i = 1; i < numFrames; ++i) {
        image!.addFrame(newImages[i]);
      }
    } else {
      image = img;
    }
  }
}
