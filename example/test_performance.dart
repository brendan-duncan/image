import 'dart:html' as Html;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart';

/**
 * Decode and display various image formats.  This is used as a visual
 * unit-test to indentify problems that may occur after the translation to
 * javascript.
 */
void main() {
  // An img on the html page is used to establish the path to the images
  // directory.  It's removed after we get the path since we'll be populating
  // the page with our own decoded images.
  Html.ImageElement img = Html.querySelectorAll('img')[0];
  String path = img.src.substring(0, img.src.lastIndexOf('/'));
  //img.remove();

  String name = 'Crab_Nebula.jpg';

  // Use an AJAX request to get the image file from disk.
  var req = new Html.HttpRequest();
  req.open('GET', path + '/' + name);
  req.overrideMimeType('text\/plain; charset=x-user-defined');
  req.onLoadEnd.listen((e) {
    if (req.status == 200) {
      // Convert the text to binary byte list.
      var bytes = req.responseText.split('').map((e){
        return new String.fromCharCode(e.codeUnitAt(0) & 0xff);
      }).join('').codeUnits;
      Uint8List data = new Uint8List.fromList(bytes);

      img.src = '';

      Stopwatch t = new Stopwatch();

      // Find the best decoder for the image.
      Decoder decoder = findDecoderForData(data);
      if (decoder == null) {
        return;
      }

      void updateProgress(int frame, int numFrames, int progress, int total) {
        print('$frame / $numFrames : $progress / $total');
      }
      decoder.progressCallback = updateProgress;

      // Some of the files are animated, so always decode to animation.
      // Single image files will decode to a single framed animation.
      t.start();
      Image image = decoder.decodeImage(data);
      t.stop();
      Html.DivElement div = new Html.DivElement();
      div.text = 'Decode: ${t.elapsedMilliseconds / 1000.0}';
      Html.document.body.append(div);

      t.reset();
      t.start();
      Image thumbnail = copyResize(image, 150);
      t.stop();
      div = new Html.DivElement();
      div.text = 'Resize: ${t.elapsedMilliseconds / 1000.0}';
      Html.document.body.append(div);

      t.reset();
      t.start();
      List<int> jpg = new JpegEncoder().encodeImage(thumbnail);

      var jpg64 = CryptoUtils.bytesToBase64(jpg);
      img.src = 'data:image/png;base64,${jpg64}';

      t.stop();
      div = new Html.DivElement();
      div.text = 'Encode: ${t.elapsedMilliseconds / 1000.0}';
      Html.document.body.append(div);
    }
  });
  req.send('');
}
