import 'dart:html' as Html;
import 'dart:convert';
import 'package:image/image.dart';

void main() {
  var theImg = Html.document.getElementById('testimage') as Html.ImageElement;
  var cvs = Html.document.createElement('canvas') as Html.CanvasElement;
  cvs.width = theImg.width;
  cvs.height = theImg.height;

  var ctx = cvs.getContext("2d") as Html.CanvasRenderingContext2D;

  ctx.drawImage(theImg, 0, 0);

  var bytes = ctx.getImageData(0, 0, cvs.width, cvs.height).data;
  Image image = Image.fromBytes(cvs.width, cvs.height, bytes);

  var jpg = encodeJpg(image, quality: 25);

  var jpg64 = base64Encode(jpg);
  var img = Html.document.createElement('img') as Html.ImageElement;
  img.src = 'data:image/png;base64,${jpg64}';
  Html.document.body.append(img);
}
