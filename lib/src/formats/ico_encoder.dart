import 'package:image/src/formats/png_encoder.dart';

import '../image.dart';
import '../util/output_buffer.dart';
import 'encoder.dart';

class IcoEncoder extends Encoder {
  @override
  List<int> encodeImage(Image image) {
    return encodeImages([image]);
  }

  List<int> encodeImages(List<Image> images) {
    int count = images.length;

    OutputBuffer out = OutputBuffer(bigEndian: false);

    // header
    out.writeUint16(0); // reserved
    out.writeUint16(1); // type: ICO => 1; CUR => 2
    out.writeUint16(count);

    int offset = 6 + count * 16;

    List<List<int>> imageDatas = [];

    for (Image img in images) {
      out.writeByte(img.width);
      out.writeByte(img.height);
      out.writeByte(32); // number of colors in the color palette
      out.writeByte(0);
      out.writeUint16(0); // TODO 0 or 1, maybe change
      out.writeUint16(8); // TODO bits per pixel

      List<int> data = PngEncoder().encodeImage(img);

      out.writeUint32(data.length * 8);
      out.writeUint32(offset);

      offset += data.length;
      imageDatas.add(data);
    }

    for (List<int> imageData in imageDatas) {
      out.writeBytes(imageData);
    }

    return out.getBytes();
  }
}
