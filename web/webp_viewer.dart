import 'dart:html' as Html;
import 'dart:convert';
import 'package:image/image.dart';

/**
 * Convert all .webp IMG elements on the page to PNG so that they can be viewed
 * by browsers like FireFox and IE.
 */
void main() {
  var images = Html.querySelectorAll('img');

  for (var _img in images) {
    var img = _img as Html.ImageElement;
    if (img.src.toLowerCase().endsWith('.webp')) {
      var req = Html.HttpRequest();
      req.open('GET', img.src);
      req.overrideMimeType('text\/plain; charset=x-user-defined');
      req.onLoadEnd.listen((e) {
        if (req.status == 200) {
          var bytes = req.responseText
              .split('')
              .map((e) {
                return new String.fromCharCode(e.codeUnitAt(0) & 0xff);
              })
              .join('')
              .codeUnits;

          Image image = decodeWebP(bytes);
          List<int> png = encodePng(image);

          var png64 = base64Encode(png);
          img.src = 'data:image/png;base64,${png64}';
        }
      });
      req.send('');
    }
  }
}
