import 'dart:html' as Html;
import 'dart:convert/convert.dart';
import 'package:image/image.dart';

void main() {
  var theImg = Html.document.getElementById('testimage');
  var cvs = Html.document.createElement('canvas');
  cvs.width = theImg.width;
  cvs.height = theImg.height;

  var ctx = cvs.getContext("2d");

  ctx.drawImage(theImg,0,0);

  var bytes = ctx.getImageData(0, 0, cvs.width, cvs.height).data;
  Image image = new Image.fromBytes(cvs.width, cvs.height, bytes);

  var jpg = encodeJpg(image, quality: 25);

  var jpg64 = BASE64.encode(jpg);
  var img = Html.document.createElement('img');
  img.src = 'data:image/png;base64,${jpg64}';
  Html.document.body.append(img);
}
