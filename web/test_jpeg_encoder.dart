import 'dart:convert';
import 'dart:js_interop';
import 'package:image/image.dart';
import 'package:web/web.dart';

void main() {
  final theImg = document.getElementById('testimage') as HTMLImageElement;

  final cvs = document.createElement('canvas') as HTMLCanvasElement
    ..width = theImg.width
    ..height = theImg.height;

  final ctx = cvs.getContext('2d') as CanvasRenderingContext2D
    ..drawImage(theImg, 0, 0);

  final bytes = ctx.getImageData(0, 0, cvs.width, cvs.height).data;

  final image = Image.fromBytes(
      width: cvs.width,
      height: cvs.height,
      bytes: bytes.toDart.buffer,
      numChannels: 4);

  final jpg = encodeJpg(image, quality: 25);

  final jpg64 = base64Encode(jpg);
  final img = HTMLImageElement()..src = 'data:image/jpeg;base64,$jpg64';
  document.body!.append(img);
}
