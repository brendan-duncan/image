part of image;

// TODO under construction...
class BitmapFont {
  // info
  String face = '';
  int size = 0;
  bool bold = false;
  bool italic = false;
  String charset = '';
  String unicode = '';
  int stretchH = 0;
  bool smooth = false;
  bool antialias = false;
  List<int> padding = [];
  List<int> spacing = [];
  bool outline = false;
  // common
  int lineHeight = 0;
  int base = 0;
  num scaleW = 0;
  num scaleH = 0;
  int pages = 0;
  bool packed = false;

  Map<int, BitmapFontCharacter> characters = {};
  Map<int, Map<int, int>> kernings = {};

  /**
   * Load a bitmap font from a zip file containing a .fnt xml file and
   * .png font image.
   */
  BitmapFont.fromZipFile(List<int> fileData) {
    Arc.Archive arc = new Arc.ZipDecoder().decodeBytes(fileData);

    Arc.File font_xml;
    for (int i = 0; i < arc.numberOfFiles(); ++i) {
      if (arc.fileName(i).endsWith('.fnt')) {
        font_xml = arc.files[i];
        break;
      }
    }

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
        for (String a in c.attributes.keys) {
          switch (a) {
            case 'face':
              face = c.attributes[a];
              break;
            case 'size':
              size = int.parse(c.attributes[a]);
              break;
            case 'bold':
              bold = (int.parse(c.attributes[a]) == 1);
              break;
            case 'italic':
              italic = (int.parse(c.attributes[a]) == 1);
              break;
            case 'charset':
              charset = c.attributes[a];
              break;
            case 'unicode':
              unicode = c.attributes[a];
              break;
            case 'stretchH':
              stretchH = int.parse(c.attributes[a]);
              break;
            case 'smooth':
              smooth = (int.parse(c.attributes[a]) == 1);
              break;
            case 'antialias':
              antialias = (int.parse(c.attributes[a]) == 1);
              break;
            case 'padding':
              List<String> tk = c.attributes[a].split(',');
              padding = [];
              for (String t in tk) {
                padding.add(int.parse(t));
              }
              break;
            case 'spacing':
              List<String> tk = c.attributes[a].split(',');
              spacing = [];
              for (String t in tk) {
                spacing.add(int.parse(t));
              }
              break;
            case 'outline':
              outline = (int.parse(c.attributes[a]) == 1);
              break;
          }
        }
      } else if (c.name == 'common') {
        for (String a in c.attributes.keys) {
          switch (a) {
            case 'lineHeight':
              lineHeight = int.parse(c.attributes[a]);
              break;
            case 'base':
              base = int.parse(c.attributes[a]);
              break;
            case 'scaleW':
              scaleW = num.parse(c.attributes[a]);
              break;
            case 'scaleH':
              scaleH = num.parse(c.attributes[a]);
              break;
            case 'pages':
              pages = int.parse(c.attributes[a]);
              break;
            case 'packed':
              packed = (int.parse(c.attributes[a]) == 1);
              break;
          }
        }
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

          BitmapFontCharacter ch = new BitmapFontCharacter(id, width, height,
              xoffset, yoffset, xadvance, page, chnl);

          characters[id] = ch;

          int x2 = x + width;
          int y2 = y + height;
          int pi = 0;
          var rgbaBuffer = ch.uint32Data;
          for (int yi = y; yi < y2; ++yi) {
            for (int xi = x; xi < x2; ++xi) {
              int p = fontImage.getPixel(xi, yi);
              rgbaBuffer[pi++] = p;
            }
          }
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
          int first = int.parse(kerning.attributes['first']);
          int second = int.parse(kerning.attributes['second']);
          int amount = int.parse(kerning.attributes['amount']);

          if (!kernings.containsKey(first)) {
            kernings[first] = {};
          }
          kernings[first][second] = amount;
        }
      }
    }
  }

  bool drawChar(Image image, int c, int x, int y) {
    if (!characters.containsKey(c)) {
      return false;
    }

    BitmapFontCharacter ch = characters[c];
    int x2 = x + ch.width;
    int y2 = y + ch.height;
    int pi = 0;
    for (int yi = y; yi < y2; ++yi) {
      for (int xi = x; xi < x2; ++xi) {
        int p = ch.uint32Data[pi++];
        image.setPixelBlend(xi, yi, p);
      }
    }
  }

  bool drawString(Image image, String s, int x, int y) {
    List<int> chars = s.codeUnits;
    for (int c in chars) {
      if (!characters.containsKey(c)) {
        x += base ~/ 2;
        continue;
      }

      BitmapFontCharacter ch = characters[c];

      int x2 = x + ch.width;
      int y2 = y + ch.height;
      int pi = 0;
      for (int yi = y; yi < y2; ++yi) {
        for (int xi = x; xi < x2; ++xi) {
          int p = ch.uint32Data[pi++];
          image.setPixelBlend(xi + ch.xoffset, yi + ch.yoffset, p);
        }
      }

      x += ch.xadvance;
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
  final int xoffset;
  final int yoffset;
  final int xadvance;
  final int page;
  final int channel;
  final Data.TypedData data;

  BitmapFontCharacter(this.id, int width, int height,
                      this.xoffset, this.yoffset, this.xadvance, this.page,
                      this.channel, {int format: RGBA}) :
    this.width = width,
    this.height = height,
    data = format == RGBA ? new Data.Uint32List(width * height) :
           throw new ImageException('Invalid Character Format');

  Data.Uint32List get uint32Data => data;

  String toString() {
    Map x = {'id': id, 'width': width, 'height': height, 'xoffset': xoffset,
             'yoffset': yoffset, 'xadvance': xadvance, 'page': page,
             'channel': channel};
    return 'Character $x';
  }
}
