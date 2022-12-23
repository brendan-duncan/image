import '../../image/image.dart';
import '../command.dart';

typedef TransformFunction = Image Function(Image image);

/// Execute an arbitrary transform function as an ImageCommand.
class TransformCmd extends Command {
  final TransformFunction _transform;

  TransformCmd(Command? input, this._transform)
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    final newImages = <Image>[];
    var hasNewImage = false;
    if (img != null) {
      for (final frame in img.frames) {
        final img2 = _transform(frame);
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
