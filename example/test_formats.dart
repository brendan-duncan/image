import 'dart:html' as Html;
import 'dart:async' as Async;
import 'package:image/image.dart';

void main() {
  Html.ImageElement img = Html.querySelectorAll('img')[0];
  String path = img.src.substring(0, img.src.lastIndexOf('/'));
  img.remove();

  List<String> images = ['1.webp', '1_webp_ll.webp', '3_webp_a.webp',
                           'abstract.jpg', 'cars.gif', 'trees.png'];

  for (String name in images) {
    var req = new Html.HttpRequest();
    req.open('GET', path + '/' + name);
    req.overrideMimeType('text\/plain; charset=x-user-defined');
    req.onLoadEnd.listen((e) {
      if (req.status == 200) {
        var bytes = req.responseText.split('').map((e){
          return new String.fromCharCode(e.codeUnitAt(0) & 0xff);
        }).join('').codeUnits;

        var label = new Html.DivElement();
        Html.document.body.append(label);
        label.text = name;

        var c = new Html.CanvasElement();
        Html.document.body.append(c);

        Decoder decoder = getDecoderForNamedImage(name);
        if (decoder == null) {
          return;
        }

        Animation anim = decoder.decodeAnimation(bytes);
        if (anim == null) {
          print('No Animation $name');
          return;
        }

        if (anim.length == 1) {
          Image image = anim.frames[0].image;
          c.width = image.width;
          c.height = image.height;

          Html.ImageData d =
                  c.context2D.createImageData(c.width, c.height);

          d.data.setRange(0, d.data.length, image.getBytes());
          c.context2D.putImageData(d, 0, 0);

          return;
        }

        int frame = 0;
        new Async.Timer.periodic(new Duration(milliseconds: 80), (t) {
          Image image = anim.frames[frame++].image;
          if (frame >= anim.numFrames) {
            frame = 0;
          }
          c.width = image.width;
          c.height = image.height;

          Html.ImageData d = c.context2D.createImageData(c.width, c.height);

          d.data.setRange(0, d.data.length, image.getBytes());
          c.context2D.putImageData(d, 0, 0);
        });
      }
   });
   req.send('');
  }
}
