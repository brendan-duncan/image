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
  BitmapFont.fromZipFile(List<int> fileData) {
    Arc.Archive arc = new Arc.ZipDecoder().decodeBytes(fileData);

    Arc.File font_xml = _findFile(arc, 'font.fnt');
    if (font_xml == null) {
      throw new ImageException('Invalid font archive');
    }

    String xml_str = new String.fromCharCodes(font_xml.content);
    XmlElement xml = XML.parse(xml_str);

    if (xml == null || xml.name != 'font') {
      throw new ImageException('Invalid font XML');
    }

    Map<int, Image> fontPages = {};

    for (XmlElement c in xml.children) {
      if (c.name == 'info') {

      } else if (c.name == 'common') {

      } else if (c.name == 'pages') {
        int count = c.children.length;
        if (c.attributes.containsKey('count')) {
          count = int.parse(c.attributes['count']);
        }
        for (int ci = 0; ci < count; ++ci) {
          XmlElement page = c.children[ci];
          int id = int.parse(page.attributes['id']);
          String filename = page.attributes['file'];

          if (fontPages.containsKey(id)) {
            throw new ImageException('Duplicate font page id found: $id.');
          }

          Arc.File imageFile = _findFile(arc, filename);
          if (imageFile == null) {
            throw new ImageException('Font zip missing font page image $filename');
          }

          Image image = new PngDecoder().decode(imageFile.content);

          fontPages[id] = image;
        }
      } else if (c.name == 'chars') {
        int count = c.children.length;
        if (c.attributes.containsKey('count')) {
          count = int.parse(c.attributes['count']);
        }

        if (count > c.children.length) {
          throw new ImageException('Invalid font XML');
        }

        for (int ci = 0; ci < count; ++ci) {
          XmlElement char = c.children[ci];
          int id = int.parse(char.attributes['id']);
          int x = int.parse(char.attributes['x']);
          int y = int.parse(char.attributes['y']);
          int width = int.parse(char.attributes['width']);
          int height = int.parse(char.attributes['height']);
          int xoffset = int.parse(char.attributes['xoffset']);
          int yoffset = int.parse(char.attributes['yoffset']);
          int xadvance = int.parse(char.attributes['xadvance']);
          int page = int.parse(char.attributes['page']);
          int chnl = int.parse(char.attributes['chnl']);

          if (!fontPages.containsKey(page)) {
            throw new ImageException('Missing page image: $page');
          }

          Image fontImage = fontPages[page];

          BitmapFontCharacter ch = new BitmapFontCharacter(id, width, height);

          int x2 = x + width;
          int y2 = y + height;
          int pi = 0;
          var rgbaBuffer = ch.rgbaBuffer;
          for (int yi = y; yi < y2; ++yi) {
            for (int xi = x; xi < x2; ++xi) {
              int p = fontImage.getPixel(xi, yi);
              rgbaBuffer[pi++] = p;
            }
          }

          characters[id] = ch;
        }
      } else if (c.name == 'kernings') {
        int count = c.children.length;
        if (c.attributes.containsKey('count')) {
          count = int.parse(c.attributes['count']);
        }

        if (count > c.children.length) {
          throw new ImageException('Invalid font XML');
        }

        for (int ci = 0; ci < count; ++ci) {
          XmlElement kerning = c.children[ci];
        }
      }
    }
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
  static const int RGBA = 0;

  final int id;
  final int width;
  final int height;
  final Data.TypedData data;

  BitmapFontCharacter(this.id, int width, int height, {int format: RGBA}) :
    this.width = width,
    this.height = height,
    data = format == RGBA ? new Data.Uint32List(width * height) :
           throw new ImageException('Invalid Character Format');

  Data.Uint32List get rgbaBuffer => data;
}
