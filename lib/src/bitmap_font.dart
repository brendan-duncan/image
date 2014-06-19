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

    XML.XmlDocument xml;

    if (fnt.startsWith('<font>')) {
      xml = XML.parse(fnt);
      if (xml == null) {
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
    XML.XmlDocument xml;

    if (font_str.startsWith('<font>')) {
      xml = XML.parse(font_str);
      if (xml == null) {
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


  void _parseFnt(XML.XmlDocument xml, Map<int, Image> fontPages,
                 [Archive arc]) {
    if (xml.children.length != 1) {
      throw new ImageException('Invalid font XML');
    }

    var font = xml.children[0];

    for (var c in font.children) {
      if (c is! XML.XmlElement) {
        continue;
      }
      String name = c.name.toString();
      if (name == 'info') {
        for (XML.XmlAttribute a in c.attributes) {
          switch (a.name.toString()) {
            case 'face':
              face = a.value;
              break;
            case 'size':
              size = int.parse(a.value);
              break;
            case 'bold':
              bold = (int.parse(a.value) == 1);
              break;
            case 'italic':
              italic = (int.parse(a.value) == 1);
              break;
            case 'charset':
              charset = a.value;
              break;
            case 'unicode':
              unicode = a.value;
              break;
            case 'stretchH':
              stretchH = int.parse(a.value);
              break;
            case 'smooth':
              smooth = (int.parse(a.value) == 1);
              break;
            case 'antialias':
              antialias = (int.parse(a.value) == 1);
              break;
            case 'padding':
              List<String> tk = a.value.split(',');
              padding = [];
              for (String t in tk) {
                padding.add(int.parse(t));
              }
              break;
            case 'spacing':
              List<String> tk = a.value.split(',');
              spacing = [];
              for (String t in tk) {
                spacing.add(int.parse(t));
              }
              break;
            case 'outline':
              outline = (int.parse(a.value) == 1);
              break;
          }
        }
      } else if (name == 'common') {
        for (XML.XmlAttribute a in c.attributes) {
          switch (a.name.toString()) {
            case 'lineHeight':
              lineHeight = int.parse(a.value);
              break;
            case 'base':
              base = int.parse(a.value);
              break;
            case 'scaleW':
              scaleW = int.parse(a.value);
              break;
            case 'scaleH':
              scaleH = int.parse(a.value);
              break;
            case 'pages':
              pages = int.parse(a.value);
              break;
            case 'packed':
              packed = (int.parse(a.value) == 1);
              break;
          }
        }
      } else if (name == 'pages') {
        for (var page in c.children) {
          if (page is! XML.XmlElement) {
            continue;
          }
          int id = int.parse(page.getAttribute('id'));
          String filename = page.getAttribute('file');

          if (fontPages.containsKey(id)) {
            throw new ImageException('Duplicate font page id found: $id.');
          }

          if (arc != null) {
            ArchiveFile imageFile = _findFile(arc, filename);
            if (imageFile == null) {
              throw new ImageException('Font zip missing font page image '
                                       '$filename');
            }

            Image image = new PngDecoder().decodeImage(imageFile.content);

            fontPages[id] = image;
          }
        }
      } else if (name == 'kernings') {
        for (var kerning in c.children) {
          if (kerning is! XML.XmlElement) {
            continue;
          }
          int first = int.parse(kerning.getAttribute('first'));
          int second = int.parse(kerning.getAttribute('second'));
          int amount = int.parse(kerning.getAttribute('amount'));

          if (!kernings.containsKey(first)) {
            kernings[first] = {};
          }
          kernings[first][second] = amount;
        }
      }
    }

    for (var c in font.children) {
      if (c is! XML.XmlElement) {
        continue;
      }
      String name = c.name.toString();
      if (name == 'chars') {
        for (var char in c.children) {
          if (char is! XML.XmlElement) {
            continue;
          }
          int id = int.parse(char.getAttribute('id'));
          int x = int.parse(char.getAttribute('x'));
          int y = int.parse(char.getAttribute('y'));
          int width = int.parse(char.getAttribute('width'));
          int height = int.parse(char.getAttribute('height'));
          int xoffset = int.parse(char.getAttribute('xoffset'));
          int yoffset = int.parse(char.getAttribute('yoffset'));
          int xadvance = int.parse(char.getAttribute('xadvance'));
          int page = int.parse(char.getAttribute('page'));
          int chnl = int.parse(char.getAttribute('chnl'));

          if (!fontPages.containsKey(page)) {
            throw new ImageException('Missing page image: $page');
          }

          Image fontImage = fontPages[page];

          BitmapFontCharacter ch = new BitmapFontCharacter(id, width, height,
              xoffset, yoffset, xadvance, page, chnl);

          characters[id] = ch;
          print('    CHAR $id : ${new String.fromCharCode(id)}');

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
      }
    }
  }

  XML.XmlDocument _parseTextFnt(String content) {
    var children = [];
    var pageList = [];
    var charList = [];
    var kerningList = [];
    var charsAttrs;
    var kerningsAttrs;

    List<String> lines = content.split('\n');

    for (String line in lines) {
      if (line.isEmpty) {
        continue;
      }

      List<String> tk = line.split(' ');
      switch (tk[0]) {
        case 'info':
          var attrs = _parseParameters(tk);
          var info = new XML.XmlElement(new XML.XmlName('info'), attrs, []);
          children.add(info);
          break;
        case 'common':
          var attrs = _parseParameters(tk);
          var node = new XML.XmlElement(new XML.XmlName('common'), attrs, []);
          children.add(node);
          break;
        case 'page':
          var attrs = _parseParameters(tk);
          var page = new XML.XmlElement(new XML.XmlName('page'), attrs, []);
          pageList.add(page);
          break;
        case 'chars':
          charsAttrs = _parseParameters(tk);
          break;
        case 'char':
          var attrs = _parseParameters(tk);
          var node = new XML.XmlElement(new XML.XmlName('char'), attrs, []);
          charList.add(node);
          break;
        case 'kernings':
          kerningsAttrs = _parseParameters(tk);
          break;
        case 'kerning':
          var attrs = _parseParameters(tk);
          var node = new XML.XmlElement(new XML.XmlName('kerning'), attrs, []);
          kerningList.add(node);
          break;
      }
    }

    if (charsAttrs != null || charList.isNotEmpty) {
      var node = new XML.XmlElement(new XML.XmlName('chars'), charsAttrs,
          charList);
      children.add(node);
    }

    if (kerningsAttrs != null || kerningList.isNotEmpty) {
      var node = new XML.XmlElement(new XML.XmlName('kernings'), kerningsAttrs,
          kerningList);
      children.add(node);
    }

    if (pageList.isNotEmpty) {
      var pages = new XML.XmlElement(new XML.XmlName('pages'), [], pageList);
      children.add(pages);
    }

    var xml = new XML.XmlElement(new XML.XmlName('font'), [], children);
    var doc = new XML.XmlDocument([xml]);

    return doc;
  }

  List _parseParameters(List<String> tk) {
    var params = [];
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

      var a = new XML.XmlAttribute(new XML.XmlName(atk[0]), atk[1]);
      params.add(a);
    }
    return params;
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
