part of image;

class PsdLayerAdditionalData extends PsdLayerData {
  InputBuffer data;

  PsdLayerAdditionalData(String tag, InputBuffer data) :
    this.data = data,
    super.type(tag);
}
