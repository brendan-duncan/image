import '../../../util/input_buffer.dart';
import '../psd_layer_data.dart';

class PsdLayerAdditionalData extends PsdLayerData {
  InputBuffer data;

  PsdLayerAdditionalData(String tag, InputBuffer data)
      : data = data,
        super.type(tag);
}
