import '../../image/image.dart';
import '../command.dart';

typedef FilterFunction = void Function(Image image);

/// Execute an arbitrary filter function as an ImageCommand.
class FilterCmd extends Command {
  final FilterFunction _filter;

  FilterCmd(Command? input, this._filter)
      : super(input);

  @override
  void executeCommand() {
    input?.executeIfDirty();
    final img = input?.image;
    if (img != null) {
      _filter(img);
    }
    image = img;
  }
}
