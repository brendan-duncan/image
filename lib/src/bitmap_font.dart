part of image;

// TODO under construction...
class BitmapFont {
  // enum Format
  static const int BLACK_AND_WHITE = 0;
  static const int GRAYSCALE = 1;
  static const int RGBA = 2;

  String face;
  int size;
  bool bold;
  bool italic;
  String charset;
  String unicode;
  int stretchH;
  bool smooth;
  bool antiAlias;
  List<int> padding;
  List<int> spacing;
  bool outline;

  int format = GRAYSCALE;
  Map<int, BitmapFontCharacter> characters = {};

  BitmapFont() {
  }

  // Load a bitmap font from a zip file containing a .fnt xml file and
  // .png font image.
  BitmapFont.fromFile(List<int> fileData) {
    loadFromFile(fileData, this);
  }

  static BitmapFont loadFromFile(List<int> fileData, [BitmapFont font]) {
    if (font == null) {
      font = new BitmapFont();
    }

    Arc.Archive arc = new Arc.ZipDecoder().decodeBytes(fileData);

    Arc.File font_xml = _findFile(arc, 'font.fnt');
    Arc.File font_png = _findFile(arc, 'font.png');
    if (font_xml == null || font_png == null) {
      throw new ImageException('Invalid font archive');
      return null;
    }

    String xml_str = new String.fromCharCodes(font_xml.content);
    XmlElement xml = XML.parse(xml_str);

    Image png = new PngDecoder().decode(font_png.content);

    //...

    return font;
  }

  static Arc.File _findFile(Arc.Archive arc, String filename) {
    for (Arc.File f in arc.files) {
      if (f.filename == filename) {
        return f;
      }
    }
    return null;
  }
}

class BitmapFontCharacter {
  String id;
  int width;
  int height;
  Data.TypedData data;
}
