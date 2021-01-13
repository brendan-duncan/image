
import 'dart:html';
import 'dart:convert';
import 'package:image/image.dart';

/// Convert all .webp IMG elements on the page to PNG so that they can be viewed
/// by browsers like FireFox and IE.
void main() {
  var images = querySelectorAll('img');

  for (var _img in images) {
    var img = _img as ImageElement;
    if (img.src!.toLowerCase().endsWith('.webp')) {
      var req = HttpRequest();
      req.open('GET', img.src!);
      req.overrideMimeType('text\/plain; charset=x-user-defined');
      req.onLoadEnd.listen((e) {
        if (req.status == 200) {
          var bytes = req.responseText!
              .split('')
              .map((e) {
                return String.fromCharCode(e.codeUnitAt(0) & 0xff);
              })
              .join('')
              .codeUnits;

          var image = decodeWebP(bytes)!;
          var png = encodePng(image);

          var png64 = base64Encode(png);
          img.src = 'data:image/png;base64,${png64}';
        }
      });
      req.send('');
    }
  }
}
