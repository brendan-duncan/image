import 'package:archive/archive.dart';

import '../formats/png_decoder.dart';
import '../image/image.dart';
import '../util/_cast.dart';
import '../util/image_exception.dart';

/// Decode a [BitmapFont] from the contents of a zip file that stores the
/// .fnt font definition and associated PNG images.
BitmapFont readFontZip(List<int> bytes) => BitmapFont.fromZip(bytes);

/// Decode a [BitmapFont] from the contents of [font] definition (.fnt) file,
/// and an [Image] that stores the font [map].
BitmapFont readFont(String font, Image map) => BitmapFont.fromFnt(font, map);

/// A bitmap font that can be used with drawString and drawChar functions.
///
/// See https://github.com/brendan-duncan/image/blob/main/doc/fonts.md
/// for more information.
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

  /// Decode a [BitmapFont] from the contents of [fnt] definition (.fnt) file,
  /// and an [Image] that stores the font map.
  BitmapFont.fromFnt(String fnt, Image page) {
    final fontPages = {0: page};
    _parseFnt(_parse(fnt), fontPages);
  }

  /// Decode a [BitmapFont] from the contents of a zip file that stores the
  /// .fnt font definition and associated PNG images.
  BitmapFont.fromZip(List<int> fileData) {
    final arc = ZipDecoder().decodeBytes(fileData);

    ArchiveFile? fontFile;
    for (var i = 0; i < arc.numberOfFiles(); ++i) {
      if (arc.fileName(i).endsWith('.fnt')) {
        fontFile = arc.files[i];
        break;
      }
    }

    if (fontFile == null) {
      throw ImageException('Invalid font archive');
    }

    final fontStr = String.fromCharCodes(fontFile.content as List<int>);

    _parseFnt(_parse(fontStr), {}, arc);
  }

  /// Get the amount the writer x position should advance after drawing the
  /// character [ch].
  int characterXAdvance(String ch) {
    if (ch.isEmpty) {
      return 0;
    }
    final c = ch.codeUnits[0];
    if (!characters.containsKey(c)) {
      return base ~/ 2;
    }
    return characters[c]!.xAdvance;
  }

  /// Parse the font definition [fnt], detecting whether it's stored as XML or
  /// as the plain-text .fnt format, and return the root `font` node.
  _FntNode _parse(String fnt) {
    /// Remove leading whitespace so xml detection is correct.
    fnt = fnt.trimLeft();

    if (fnt.startsWith('<?xml') || fnt.startsWith('<font>')) {
      return _parseXmlFnt(fnt);
    }
    return _parseTextFnt(fnt);
  }

  void _parseFnt(_FntNode font, Map<int, Image?> fontPages, [Archive? arc]) {
    if (font.name != 'font') {
      throw ImageException('Invalid font XML');
    }

    for (var c in font.children) {
      final name = c.name;
      if (name == 'info') {
        for (var a in c.attributes.entries) {
          switch (a.key) {
            case 'face':
              face = a.value;
              break;
            case 'size':
              size = int.parse(a.value);
              break;
            case 'bold':
              bold = int.parse(a.value) == 1;
              break;
            case 'italic':
              italic = int.parse(a.value) == 1;
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
              smooth = int.parse(a.value) == 1;
              break;
            case 'antialias':
              antialias = int.parse(a.value) == 1;
              break;
            case 'padding':
              final tk = a.value.split(',');
              padding = [];
              for (var t in tk) {
                padding.add(int.parse(t));
              }
              break;
            case 'spacing':
              final tk = a.value.split(',');
              spacing = [];
              for (var t in tk) {
                spacing.add(int.parse(t));
              }
              break;
            case 'outline':
              outline = int.parse(a.value) == 1;
              break;
          }
        }
      } else if (name == 'common') {
        for (var a in c.attributes.entries) {
          switch (a.key) {
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
              packed = int.parse(a.value) == 1;
              break;
          }
        }
      } else if (name == 'pages') {
        for (var page in c.children) {
          final id = int.parse(page.getAttribute('id')!);
          final filename = page.getAttribute('file');

          if (fontPages.containsKey(id)) {
            throw ImageException('Duplicate font page id found: $id.');
          }

          if (arc != null) {
            final imageFile = _findFile(arc, filename);
            if (imageFile == null) {
              throw ImageException('Font zip missing font page image '
                  '$filename');
            }

            final image =
                PngDecoder().decode(castToUint8List(imageFile.content));

            fontPages[id] = image;
          }
        }
      } else if (name == 'kernings') {
        for (var kerning in c.children) {
          final first = int.parse(kerning.getAttribute('first')!);
          final second = int.parse(kerning.getAttribute('second')!);
          final amount = int.parse(kerning.getAttribute('amount')!);

          if (!kernings.containsKey(first)) {
            kernings[first] = {};
          }
          kernings[first]![second] = amount;
        }
      }
    }

    for (var c in font.children) {
      final name = c.name;
      if (name == 'chars') {
        for (var char in c.children) {
          final id = int.parse(char.getAttribute('id')!);
          final x = int.parse(char.getAttribute('x')!);
          final y = int.parse(char.getAttribute('y')!);
          final width = int.parse(char.getAttribute('width')!);
          final height = int.parse(char.getAttribute('height')!);
          final xoffset = int.parse(char.getAttribute('xoffset')!);
          final yoffset = int.parse(char.getAttribute('yoffset')!);
          final xadvance = int.parse(char.getAttribute('xadvance')!);
          final page = int.parse(char.getAttribute('page')!);
          final chnl = int.parse(char.getAttribute('chnl')!);

          if (!fontPages.containsKey(page)) {
            throw ImageException('Missing page image: $page');
          }

          final fontImage = fontPages[page];

          final ch = BitmapFontCharacter(
              id, width, height, xoffset, yoffset, xadvance, page, chnl);

          characters[id] = ch;

          final x2 = x + width;
          final y2 = y + height;
          final image = ch.image;
          for (var yi = y; yi < y2; ++yi) {
            for (var xi = x; xi < x2; ++xi) {
              image.setPixel(xi - x, yi - y, fontImage!.getPixel(xi, yi));
            }
          }
        }
      }
    }
  }

  /// Parse the plain-text .fnt format into a `font` node tree that mirrors the
  /// structure of the XML format.
  _FntNode _parseTextFnt(String content) {
    final children = <_FntNode>[];
    final pageList = <_FntNode>[];
    final charList = <_FntNode>[];
    final kerningList = <_FntNode>[];
    Map<String, String>? charsAttrs;
    Map<String, String>? kerningsAttrs;

    var lines = content.split('\r\n');
    if (lines.length <= 1) {
      lines = content.split('\n');
    }

    for (var line in lines) {
      if (line.isEmpty) {
        continue;
      }

      final tk = line.split(' ');
      switch (tk[0]) {
        case 'info':
          children.add(_FntNode('info', _parseParameters(tk), []));
          break;
        case 'common':
          children.add(_FntNode('common', _parseParameters(tk), []));
          break;
        case 'page':
          pageList.add(_FntNode('page', _parseParameters(tk), []));
          break;
        case 'chars':
          charsAttrs = _parseParameters(tk);
          break;
        case 'char':
          charList.add(_FntNode('char', _parseParameters(tk), []));
          break;
        case 'kernings':
          kerningsAttrs = _parseParameters(tk);
          break;
        case 'kerning':
          kerningList.add(_FntNode('kerning', _parseParameters(tk), []));
          break;
      }
    }

    if (charsAttrs != null || charList.isNotEmpty) {
      children.add(_FntNode('chars', charsAttrs ?? {}, charList));
    }

    if (kerningsAttrs != null || kerningList.isNotEmpty) {
      children.add(_FntNode('kernings', kerningsAttrs ?? {}, kerningList));
    }

    if (pageList.isNotEmpty) {
      children.add(_FntNode('pages', {}, pageList));
    }

    return _FntNode('font', {}, children);
  }

  Map<String, String> _parseParameters(List<String> tk) {
    final params = <String, String>{};
    for (var ti = 1; ti < tk.length; ++ti) {
      if (tk[ti].isEmpty) {
        continue;
      }
      final atk = tk[ti].split('=');
      if (atk.length != 2) {
        continue;
      }

      // Remove all " characters
      params[atk[0]] = atk[1].replaceAll('"', '');
    }
    return params;
  }

  /// Parse the XML .fnt format into a `font` node tree.
  _FntNode _parseXmlFnt(String content) => _XmlFntParser(content).parse();

  static ArchiveFile? _findFile(Archive arc, String? filename) {
    for (var f in arc.files) {
      if (f.name == filename) {
        return f;
      }
    }
    return null;
  }
}

/// A node in a parsed .fnt definition. The .fnt format, whether stored as XML
/// or plain text, maps onto a simple tree of named elements with attributes,
/// so this minimal model avoids a dependency on a full XML library.
class _FntNode {
  final String name;
  final Map<String, String> attributes;
  final List<_FntNode> children;

  _FntNode(this.name, this.attributes, this.children);

  String? getAttribute(String name) => attributes[name];
}

/// A minimal XML parser scoped to the shape of BMFont .fnt files: an optional
/// `<?xml?>` declaration, attribute-only elements, self-closing tags, simple
/// nesting and no mixed text content. It is intentionally not a general purpose
/// XML parser.
class _XmlFntParser {
  final String _s;
  int _pos = 0;

  _XmlFntParser(this._s);

  _FntNode parse() {
    final root = _parseNode();
    if (root == null) {
      throw ImageException('Invalid font XML');
    }
    return root;
  }

  /// Parse the next element, skipping any leading misc nodes (declarations,
  /// comments, doctype, text). Returns null at end of input or when the next
  /// token is a closing tag.
  _FntNode? _parseNode() {
    while (_pos < _s.length) {
      _skipWhitespace();
      if (_pos >= _s.length) {
        return null;
      }
      if (!_startsWith('<')) {
        // Text content between elements; the .fnt format carries no meaningful
        // text, so skip to the next tag.
        _skipToChar('<');
        continue;
      }
      if (_startsWith('<?')) {
        _skipPast('?>');
        continue;
      }
      if (_startsWith('<!--')) {
        _skipPast('-->');
        continue;
      }
      if (_startsWith('<!')) {
        _skipPast('>');
        continue;
      }
      if (_startsWith('</')) {
        // Closing tag belongs to the caller.
        return null;
      }
      return _parseElement();
    }
    return null;
  }

  _FntNode _parseElement() {
    _expect('<');
    final name = _parseName();
    final attributes = <String, String>{};
    final children = <_FntNode>[];

    while (true) {
      _skipWhitespace();
      if (_startsWith('/>')) {
        _pos += 2;
        return _FntNode(name, attributes, children);
      }
      if (_startsWith('>')) {
        _pos += 1;
        break;
      }
      if (_pos >= _s.length) {
        throw ImageException('Invalid font XML');
      }
      final attrName = _parseName();
      _skipWhitespace();
      _expect('=');
      _skipWhitespace();
      attributes[attrName] = _parseAttributeValue();
    }

    // Parse child elements until the matching closing tag.
    while (true) {
      final child = _parseNode();
      if (child == null) {
        break;
      }
      children.add(child);
    }

    _skipWhitespace();
    if (_startsWith('</')) {
      _pos += 2;
      _parseName();
      _skipWhitespace();
      _expect('>');
    }

    return _FntNode(name, attributes, children);
  }

  String _parseName() {
    final start = _pos;
    while (_pos < _s.length) {
      final c = _s.codeUnitAt(_pos);
      // Stop at whitespace, '>', '/', or '='.
      if (_isWhitespace(c) || c == 0x3e || c == 0x2f || c == 0x3d) {
        break;
      }
      _pos++;
    }
    if (_pos == start) {
      throw ImageException('Invalid font XML');
    }
    return _s.substring(start, _pos);
  }

  String _parseAttributeValue() {
    if (_pos >= _s.length) {
      throw ImageException('Invalid font XML');
    }
    final quote = _s.codeUnitAt(_pos);
    if (quote != 0x22 && quote != 0x27) {
      throw ImageException('Invalid font XML: unquoted attribute value');
    }
    _pos++;
    final start = _pos;
    while (_pos < _s.length && _s.codeUnitAt(_pos) != quote) {
      _pos++;
    }
    final raw = _s.substring(start, _pos);
    if (_pos < _s.length) {
      _pos++; // Consume the closing quote.
    }
    return _decodeEntities(raw);
  }

  String _decodeEntities(String s) {
    if (!s.contains('&')) {
      return s;
    }
    final sb = StringBuffer();
    var i = 0;
    while (i < s.length) {
      if (s.codeUnitAt(i) != 0x26 /* & */) {
        sb.write(s[i]);
        i++;
        continue;
      }
      final end = s.indexOf(';', i);
      if (end == -1) {
        sb.write(s[i]);
        i++;
        continue;
      }
      final entity = s.substring(i + 1, end);
      String? replacement;
      switch (entity) {
        case 'amp':
          replacement = '&';
          break;
        case 'lt':
          replacement = '<';
          break;
        case 'gt':
          replacement = '>';
          break;
        case 'quot':
          replacement = '"';
          break;
        case 'apos':
          replacement = "'";
          break;
        default:
          if (entity.startsWith('#x') || entity.startsWith('#X')) {
            final code = int.tryParse(entity.substring(2), radix: 16);
            if (code != null) {
              replacement = String.fromCharCode(code);
            }
          } else if (entity.startsWith('#')) {
            final code = int.tryParse(entity.substring(1));
            if (code != null) {
              replacement = String.fromCharCode(code);
            }
          }
      }
      if (replacement != null) {
        sb.write(replacement);
        i = end + 1;
      } else {
        sb.write(s[i]);
        i++;
      }
    }
    return sb.toString();
  }

  bool _isWhitespace(int c) => c == 0x20 || c == 0x09 || c == 0x0a || c == 0x0d;

  void _skipWhitespace() {
    while (_pos < _s.length && _isWhitespace(_s.codeUnitAt(_pos))) {
      _pos++;
    }
  }

  bool _startsWith(String s) => _s.startsWith(s, _pos);

  void _expect(String s) {
    if (!_startsWith(s)) {
      throw ImageException('Invalid font XML');
    }
    _pos += s.length;
  }

  void _skipPast(String s) {
    final idx = _s.indexOf(s, _pos);
    _pos = idx == -1 ? _s.length : idx + s.length;
  }

  void _skipToChar(String ch) {
    final idx = _s.indexOf(ch, _pos);
    _pos = idx == -1 ? _s.length : idx;
  }
}

/// A single character in a [BitmapFont].
class BitmapFontCharacter {
  final int id;
  final int width;
  final int height;
  final int xOffset;
  final int yOffset;
  final int xAdvance;
  final int page;
  final int channel;
  final Image image;

  BitmapFontCharacter(this.id, this.width, this.height, this.xOffset,
      this.yOffset, this.xAdvance, this.page, this.channel)
      : image = Image(width: width, height: height, numChannels: 4);

  @override
  String toString() {
    final x = {
      'id': id,
      'width': width,
      'height': height,
      'xOffset': xOffset,
      'yOffset': yOffset,
      'xAdvance': xAdvance,
      'page': page,
      'channel': channel
    };
    return 'Character $x';
  }
}
