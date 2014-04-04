part of image;

class ExrAttribute {
  String name;
  String type;
  int size;
  InputBuffer value;

  ExrAttribute(this.name, this.type, this.size, this.value);
}
