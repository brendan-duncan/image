import 'dart:io';
import 'dart:isolate';
import 'package:image/image.dart' as DIL;

class DecodeParam {
  final File file;
  final SendPort sendPort;
  DecodeParam(this.file, this.sendPort);
}

void decode(DecodeParam param) {
  // Read an image from file (webp in this case).
  // decodeImage will identify the format of the image and use the appropriate
  // decoder.
  final image = DIL.decodeImage(param.file.readAsBytesSync())!;
  // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
  final thumbnail = DIL.gaussianBlur(DIL.copyResize(image, width: 120), 5);
  param.sendPort.send(thumbnail);
}

// Decode and process an image file in a separate thread (isolate) to avoid
// stalling the main UI thread.
Future<void> main() async {
  final receivePort = ReceivePort();
  await Isolate.spawn(decode, DecodeParam(File('test.webp'),
      receivePort.sendPort));

  // Get the processed image from the isolate.
  final image = await receivePort.first as DIL.Image;

  File('thumbnail.png').writeAsBytesSync(DIL.encodePng(image));
}
