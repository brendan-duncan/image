part of image;

class ExrAttribute {
  String name;
  String type;
  int size;
  InputBuffer data;

  ExrAttribute(this.name, this.type, this.size, this.data);
}
