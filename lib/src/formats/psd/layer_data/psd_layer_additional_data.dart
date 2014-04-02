part of image;

class PsdLayerAdditionalData extends PsdLayerData {
  InputBuffer data;

  PsdLayerAdditionalData(String tag, InputBuffer data) :
    super.type(tag),
    this.data = data;
}
