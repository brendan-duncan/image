
import 'dart:html';
import 'dart:convert';
import 'package:image/image.dart';

void main() {
  var theImg = document.getElementById('testimage') as ImageElement;

  var cvs = document.createElement('canvas') as CanvasElement;
  cvs.width = theImg.width;
  cvs.height = theImg.height;

  var ctx = cvs.getContext('2d') as CanvasRenderingContext2D;

  ctx.drawImage(theImg, 0, 0);

  var bytes = ctx.getImageData(0, 0, cvs.width!, cvs.height!).data;

  var image =
      Image.fromBytes(cvs.width!, cvs.height!, bytes, format: Format.rgba);

  var jpg = encodeJpg(image, quality: 25);

  var jpg64 = base64Encode(jpg);
  var img = document.createElement('img') as ImageElement;
  img.src = 'data:image/jpeg;base64,${jpg64}';
  document.body!.append(img);
}
