import 'package:image/src/formats/png_encoder.dart';

import '../image.dart';
import '../util/output_buffer.dart';
import 'encoder.dart';

abstract class WinEncoder extends Encoder {
  int get type;

  int colorPlanesOrXHotSpot(int index);

  int bitsPerPixelOrYHotSpot(int index);

  @override
  List<int> encodeImage(Image image) {
    return encodeImages([image]);
  }

  List<int> encodeImages(List<Image> images) {
    int count = images.length;

    OutputBuffer out = OutputBuffer(bigEndian: false);

    // header
    out.writeUint16(0); // reserved
    out.writeUint16(type); // type: ICO => 1; CUR => 2
    out.writeUint16(count);

    int offset = 6 + count * 16; // file header with image directory byte size

    List<List<int>> imageDatas = [];

    int i = 0;
    for (Image img in images) {
      if (img.width > 256 || img.height > 256) throw Exception("ICO and CUR support only sizes until 256");

      out.writeByte(img.width); // image width in pixels
      out.writeByte(img.height); // image height in pixels
      out.writeByte(0); // Color count, should be 0 if more than 256 colors https://fileformats.fandom.com/wiki/Icon
      out.writeByte(0); // Reserved
      out.writeUint16(colorPlanesOrXHotSpot(i));
      out.writeUint16(bitsPerPixelOrYHotSpot(i));

      List<int> data =
          PngEncoder().encodeImage(img); // Use png instead of bmp encoded data, it's supported since Windows Vista

      out.writeUint32(data.length); // size of the image's data in bytes
      out.writeUint32(offset); // offset of data from the beginning of the file

      offset += data.length; // add the size of bytes to get the new begin of the next image
      i++;
      imageDatas.add(data);
    }

    for (List<int> imageData in imageDatas) {
      out.writeBytes(imageData);
    }

    return out.getBytes();
  }
}

class IcoEncoder extends WinEncoder {
  @override
  int colorPlanesOrXHotSpot(int index) => 0;

  @override
  int bitsPerPixelOrYHotSpot(int index) => 32;

  @override
  int get type => 1;
}
