import '../../../image_exception.dart';
import '../../../util/input_buffer.dart';
import '../psd_layer_data.dart';

class PsdLayerSectionDivider extends PsdLayerData {
  static const String TAG = 'lsct';

  static const int NORMAL = 0;
  static const int OPEN_FOLDER = 1;
  static const int CLOSED_FOLDER = 2;
  static const int SECTION_DIVIDER = 3;

  static const int SUBTYPE_NORMAL = 0;
  static const int SUBTYPE_SCENE_GROUP = 1;

  int type;
  String key;
  int subType = SUBTYPE_NORMAL;

  PsdLayerSectionDivider(String tag, InputBuffer data) : super.type(tag) {
    int len = data.length;

    type = data.readUint32();

    if (len >= 12) {
      String sig = data.readString(4);
      if (sig != '8BIM') {
        throw new ImageException('Invalid key in layer additional data');
      }
      key = data.readString(4);
    }

    if (len >= 16) {
      subType = data.readUint32();
    }
  }
}
