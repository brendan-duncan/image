import 'dart:io';
import 'dart:isolate';
import 'package:image/image.dart';

class DecodeParam {
  final File file;
  final SendPort sendPort;
  DecodeParam(this.file, this.sendPort);
}

void decode(DecodeParam param) {
  // Read an image from file (webp in this case).
  // decodeImage will identify the format of the image and use the appropriate
  // decoder.
  Image image = decodeImage(param.file.readAsBytesSync());
  // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
  Image thumbnail = gaussianBlur(copyResize(image, 120), 5);
  param.sendPort.send(thumbnail);
}

// Decode and process an image file in a separate thread (isolate) to avoid
// stalling the main UI thread.
void main() async {
  ReceivePort receivePort = ReceivePort();

  await Isolate.spawn(decode,
      new DecodeParam(new File('test.webp'), receivePort.sendPort));

  // Get the processed image from the isolate.
  Image image = await receivePort.first as Image;

  new File('thumbnail.png').writeAsBytesSync(encodePng(image));
}
