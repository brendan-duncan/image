# Font Rendering

The Dart Image Library has (very) limited support for bitmap fonts and drawing text.

To create a bitmap font to use with the Dart Image Library: 
1. Get your .ttf file - important is to select file with specific style
   which you want. For example when you download .ttf file from Google fonts: select
   file from /static folder. Example name: Roboto-Black.ttf
2. Convert ttf file to fnt zip using a tool like: https://ttf2fnt.com. Setting the font color to white lets you draw the font with different colors.

You can import the zip with:

```dart
import 'package:image/image.dart' as img;

void main() async {
  final fontZipFile = await File('font.zip').readAsBytes();
  final font = img.BitmapFont.fromZip(fontZipFile);
  final image = img.Image(width: 320, height: 200);
  img.drawString(image, 'Hello', font: font, x: 10, y: 100);
  await img.encodePngFile('testFont.png', image);
}
```
