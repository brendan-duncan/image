part of image;

class ImfAttribute {
  String name;
  String type;
  int size;
  InputBuffer value;

  ImfAttribute(this.name, this.type, this.size, this.value);
}
