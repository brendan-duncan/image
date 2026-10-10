# Font Rendering

The Dart Image Library draws text with bitmap fonts: fonts whose characters are stored as
pre-rendered images at a fixed size. It doesn't render TrueType or OpenType fonts directly, but
you can convert them to bitmap fonts (see [Creating a bitmap font](#creating-a-bitmap-font)).

```dart
import 'package:image/image.dart' as img;

Future<void> main() async {
  final image = img.Image(width: 320, height: 120);
  img.drawString(image, 'Hello World', font: img.arial24, x: 10, y: 10);
  img.drawString(image, 'In red', font: img.arial14, x: 10, y: 50,
      color: img.ColorRgb8(255, 0, 0));
  await img.encodePngFile('text.png', image);
}
```

## Built-in fonts

Three sizes of Arial are included, ready to use:

| Font | Size | Line height |
|---|---|---|
| `arial14` | 14 px | 16 px |
| `arial24` | 24 px | 28 px |
| `arial48` | 48 px | 55 px |

They contain the printable ASCII characters except `<`, `>`, `\`, `` ` `` and `~`. Their glyphs
are white, so the `color` argument of `drawString` gives text of exactly that color. Each font is
decoded the first time you use it.

## Drawing text

### [drawString](https://pub.dev/documentation/image/latest/image/drawString.html)

```dart
Image drawString(Image image, String string, {required BitmapFont font,
    int? x, int? y, Color? color, bool rightJustify = false, bool wrap = false,
    BlendMode blend = BlendMode.alpha, Image? mask,
    Channel maskChannel = Channel.luminance})
```

Draws `string` into `image` and returns `image`.

| Parameter | Description |
|---|---|
| `font` | The [BitmapFont](#bitmapfont) to draw with. |
| `x`, `y` | The top-left corner of the text. Leave out `x` to center the text horizontally in the image, or `y` to center it vertically. |
| `color` | Tints the text: the glyph colors are multiplied by `color`, and its alpha scales their opacity. White glyphs become exactly `color`. Without it, the glyphs' own colors are used. |
| `rightJustify` | When `true`, `x` is the right edge of each line instead of the left. |
| `wrap` | When `true`, breaks lines between words so they fit within the width of the image. Drawing stops at a word that doesn't fit on a line by itself. |
| `blend`, `mask`, `maskChannel` | The usual [drawing parameters](draw.md#common-parameters). |

* `\n` starts a new line. Each line is drawn below the previous one, at a spacing equal to the
  height of the tallest character in the string.
* Characters the font doesn't have are skipped, leaving a gap of half the font's `base` height.
* Text is drawn character by character with each glyph's offsets and advance; kerning pairs are
  read from the font file (`font.kernings`) but not applied.
* Strings are processed as UTF-16 code units, so characters outside the Basic Multilingual Plane
  (such as most emoji) can't be drawn.

```dart
// Centered in the image.
img.drawString(image, 'Centered', font: img.arial48);

// Two lines, right-aligned 10 pixels from the right edge.
img.drawString(image, 'Total\n42.00', font: img.arial24,
    x: image.width - 10, y: 10, rightJustify: true);

// A paragraph that wraps at the edge of the image.
img.drawString(image, 'The quick brown fox jumps over the lazy dog.',
    font: img.arial14, x: 10, y: 60, wrap: true,
    color: img.ColorRgb8(0, 0, 0));

// Semi-transparent white text.
img.drawString(image, 'Watermark', font: img.arial24, x: 10, y: 90,
    color: img.ColorRgba8(255, 255, 255, 128));
```

![drawString](images/draw/drawString.png)

### [drawChar](https://pub.dev/documentation/image/latest/image/drawChar.html)

```dart
Image drawChar(Image image, String char, {required BitmapFont font,
    required int x, required int y, Color? color,
    BlendMode blend = BlendMode.alpha, Image? mask,
    Channel maskChannel = Channel.luminance})
```

Draws the first character of `char` with the top-left corner of its glyph image at (`x`, `y`).
Unlike `drawString`, it doesn't apply the character's offsets, so it's mostly useful for
symbols and single characters. If `color` is given, the glyph is drawn in that color using the
glyph's alpha as its shape; otherwise the glyph's own colors are used. Nothing is drawn if the
font doesn't have the character.

```dart
img.drawChar(image, 'A', font: img.arial48, x: 20, y: 20,
    color: img.ColorRgb8(0, 0, 255));
```

![drawChar](images/draw/drawChar.png)

### Measuring text

There's no measuring function, but you can add up the characters' advances. This matches how
`drawString` lays out a single line:

```dart
(int, int) measureString(img.BitmapFont font, String text) {
  var width = 0;
  var height = 0;
  for (final c in text.codeUnits) {
    final ch = font.characters[c];
    if (ch == null) continue;
    width += ch.xAdvance;
    if (ch.height + ch.yOffset > height) height = ch.height + ch.yOffset;
  }
  return (width, height);
}
```

For example, to put a caption on a band at the bottom of an image:

```dart
final (w, h) = measureString(img.arial24, caption);
img.fillRect(image, x1: 0, y1: image.height - h - 16, x2: image.width - 1,
    y2: image.height - 1, color: img.ColorRgba8(0, 0, 0, 160));
img.drawString(image, caption, font: img.arial24,
    x: (image.width - w) ~/ 2, y: image.height - h - 8);
```

## Loading your own fonts

The library reads fonts in the [AngelCode BMFont](https://www.angelcode.com/products/bmfont/)
format: a `.fnt` definition file (in either the text or XML variant) and one or more PNG images
holding the glyphs.

### From a zip file

The easiest way to load a font is to put the `.fnt` file and its PNG pages in a zip file, and
pass the bytes of the zip to
[readFontZip](https://pub.dev/documentation/image/latest/image/readFontZip.html) (or the
equivalent `BitmapFont.fromZip` constructor). The PNG files are found by the names listed in
the `.fnt` file. It throws an `ImageException` if the zip has no `.fnt` file or is missing a
page image.

```dart
import 'dart:io';
import 'package:image/image.dart' as img;

Future<void> main() async {
  final fontZip = await File('roboto_32.zip').readAsBytes();
  final font = img.readFontZip(fontZip);

  final image = img.Image(width: 320, height: 200);
  img.drawString(image, 'Hello', font: font, x: 10, y: 100);
  await img.encodePngFile('hello.png', image);
}
```

Decode a font once and reuse it, since decoding it takes much longer than drawing with it. In
Flutter, you can load the zip from your assets with
`(await rootBundle.load('assets/font.zip')).buffer.asUint8List()`; on the web, fetch the bytes
over HTTP.

### From a .fnt file and an image

[readFont](https://pub.dev/documentation/image/latest/image/readFont.html) (or
`BitmapFont.fromFnt`) takes the contents of a `.fnt` file as a string, plus the page image,
for fonts that fit on a single page:

```dart
img.BitmapFont loadFont(String fnt, img.Image page) => img.readFont(fnt, page);
```

## BitmapFont

A [BitmapFont](https://pub.dev/documentation/image/latest/image/BitmapFont-class.html) exposes
the information from the `.fnt` file, which is useful for layout:

| Property | Description |
|---|---|
| `face`, `size`, `bold`, `italic` | The name, size and style of the original font. |
| `lineHeight` | The recommended distance between lines, in pixels. |
| `base` | The distance from the top of a line to the baseline, in pixels. |
| `characters` | A `Map<int, BitmapFontCharacter>` from character code to glyph. |
| `kernings` | Kerning amounts: `kernings[first]?[second]` is the adjustment between two characters. |
| `characterXAdvance(String ch)` | How far the pen moves after drawing `ch`. |

Each [BitmapFontCharacter](https://pub.dev/documentation/image/latest/image/BitmapFontCharacter-class.html)
has its glyph `image`, its `width` and `height`, the `xOffset` and `yOffset` from the pen
position to the top-left of the glyph, and its `xAdvance`.

## Creating a bitmap font

To make a bitmap font from a TrueType (`.ttf`) or OpenType (`.otf`) font:

1. Get the font file for the exact style you want. Each weight and style needs its own bitmap
   font. For example, Google Fonts downloads have files for each style in the `static` folder,
   such as `Roboto-Black.ttf`.
2. Convert it with a BMFont tool, such as [SnowB](https://snowb.org) (in the browser),
   [AngelCode BMFont](https://www.angelcode.com/products/bmfont/) (Windows), or
   [Hiero](https://libgdx.com/wiki/tools/hiero). Choose:
   * the pixel size you'll draw at, since bitmap fonts don't scale well,
   * the characters you need,
   * white glyphs on a transparent background, so you can color the text with `color`,
   * PNG for the page images, and a text or XML `.fnt` file.
3. Zip the `.fnt` file together with its PNG page images, and load it with `readFontZip`.

## See also

* [Drawing](draw.md): shapes, blending and masks.
* [Commands](commands.md): `drawString` and `drawChar` as Command methods.
* [API reference](https://pub.dev/documentation/image/latest/image/)
