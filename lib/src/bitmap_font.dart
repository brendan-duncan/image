part of image;

/**
 * Decode a [BitmapFont] from the contents of a zip file that stores the
 * .fnt font definition and associated PNG images.
 */
BitmapFont readFontZip(List<int> bytes) =>
    new BitmapFont.fromZip(bytes);


/**
 * Decode a [BitmapFont] from the contents of [font] definition (.fnt) file,
 * and an [Image] that stores the font [map].
 */
BitmapFont readFont(String font, Image map) =>
    new BitmapFont.fromFnt(font, map);


/**
 * A bitmap font that can be used with [drawString] and [drawChar] functions.
 * You can generate a font files from a program
 * like: http://kvazars.com/littera
 */
class BitmapFont {
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
  int lineHeight = 0;
  int base = 0;
  num scaleW = 0;
  num scaleH = 0;
  int pages = 0;
  bool packed = false;

  Map<int, BitmapFontCharacter> characters = {};
  Map<int, Map<int, int>> kernings = {};

  /**
   * Decode a [BitmapFont] from the contents of [font] definition (.fnt) file,
   * and an [Image] that stores the font [map].
   */
  BitmapFont.fromFnt(String fnt, Image page) {
    Map<int, Image> fontPages = { 0: page };

    XmlElement xml;

    if (fnt.startsWith('<font>')) {
      xml = XML.parse(fnt);
      if (xml == null || xml.name != 'font') {
        throw new ImageException('Invalid font XML');
      }
    } else {
      xml = _parseTextFnt(fnt);
    }

    _parseFnt(xml, fontPages);
  }

  /**
   * Decode a [BitmapFont] from the contents of a zip file that stores the
   * .fnt font definition and associated PNG images.
   */
  BitmapFont.fromZip(List<int> fileData) {
    Archive arc = new ZipDecoder().decodeBytes(fileData);

    ArchiveFile font_file;
    for (int i = 0; i < arc.numberOfFiles(); ++i) {
      if (arc.fileName(i).endsWith('.fnt')) {
        font_file = arc.files[i];
        break;
      }
    }

    if (font_file == null) {
      throw new ImageException('Invalid font archive');
    }

    String font_str = new String.fromCharCodes(font_file.content);
    XmlElement xml;

    if (font_str.startsWith('<font>')) {
      xml = XML.parse(font_str);
      if (xml == null || xml.name != 'font') {
        throw new ImageException('Invalid font XML');
      }
    } else {
      xml = _parseTextFnt(font_str);
    }

    _parseFnt(xml, {}, arc);
  }

  /**
   * Get the amount the writer x position should advance after drawing the
   * character [ch].
   */
  int characterXAdvance(String ch) {
    if (ch.isEmpty) {
      return 0;
    }
    int c = ch.codeUnits[0];
    if (!characters.containsKey(ch)) {
      return base ~/ 2;
    }
    return characters[c].xadvance;
  }


  void _parseFnt(XmlElement xml, Map<int, Image> fontPages,
                 [Archive arc]) {
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
              scaleW = int.parse(c.attributes[a]);
              break;
            case 'scaleH':
              scaleH = int.parse(c.attributes[a]);
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

          if (arc != null) {
            ArchiveFile imageFile = _findFile(arc, filename);
            if (imageFile == null) {
              throw new ImageException('Font zip missing font page image $filename');
            }

            Image image = new PngDecoder().decodeImage(imageFile.content);

            fontPages[id] = image;
          }
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
          Image image = ch.image;
          for (int yi = y; yi < y2; ++yi) {
            for (int xi = x; xi < x2; ++xi) {
              image[pi++] = fontImage.getPixel(xi, yi);
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

  XmlElement _parseTextFnt(String content) {
    XmlElement xml = new XmlElement('font');

    XmlElement info = new XmlElement('info');
    xml.addChild(info);

    XmlElement common = new XmlElement('common');
    xml.addChild(common);

    XmlElement pages = new XmlElement('pages');
    xml.addChild(pages);

    XmlElement chars = new XmlElement('chars');
    xml.addChild(chars);

    XmlElement kernings = new XmlElement('kernings');
    xml.addChild(kernings);

    List<String> lines = content.split('\n');

    for (String line in lines) {
      if (line.isEmpty) {
        continue;
      }

      List<String> tk = line.split(' ');
      switch (tk[0]) {
        case 'info':
          _parseParameters(info, tk);
          break;
        case 'common':
          _parseParameters(common, tk);
          break;
        case 'page':
          XmlElement page = new XmlElement('page');
          _parseParameters(page, tk);
          pages.addChild(page);
          break;
        case 'chars':
          _parseParameters(chars, tk);
          break;
        case 'char':
          XmlElement char = new XmlElement('char');
          _parseParameters(char, tk);
          chars.addChild(char);
          break;
        case 'kernings':
          _parseParameters(kernings, tk);
          break;
        case 'kerning':
          XmlElement kerning = new XmlElement('kerning');
          _parseParameters(kerning, tk);
          kernings.addChild(kerning);
          break;
      }
    }

    return xml;
  }

  void _parseParameters(XmlElement xml, List<String> tk) {
    for (int ti = 1; ti < tk.length; ++ti) {
      if (tk[ti].isEmpty) {
        continue;
      }
      List<String> atk = tk[ti].split('=');
      if (atk.length != 2) {
        continue;
      }

      // Remove all " characters
      atk[1] = atk[1].replaceAll('"', '');

      xml.attributes[atk[0]] = atk[1];
    }
  }

  static ArchiveFile _findFile(Archive arc, String filename) {
    for (ArchiveFile f in arc.files) {
      if (f.name == filename) {
        return f;
      }
    }
    return null;
  }
}

/**
 * A single character in a [BitmapFont].
 */
class BitmapFontCharacter {
  final int id;
  final int width;
  final int height;
  final int xoffset;
  final int yoffset;
  final int xadvance;
  final int page;
  final int channel;
  final Image image;

  BitmapFontCharacter(this.id, int width, int height,
                      this.xoffset, this.yoffset, this.xadvance, this.page,
                      this.channel) :
    this.width = width,
    this.height = height,
    image = new Image(width, height);

  String toString() {
    Map x = {'id': id, 'width': width, 'height': height, 'xoffset': xoffset,
             'yoffset': yoffset, 'xadvance': xadvance, 'page': page,
             'channel': channel};
    return 'Character $x';
  }
}
