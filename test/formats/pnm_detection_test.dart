import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  test('binary PNM is not misdetected as TGA (#744)', () {
    // A 4x4 binary PGM whose bytes also satisfy TGA's loose validation: TGA has
    // no magic bytes, byte 1 (0x35) is not a colormap type, byte 2 (0x0a) is a
    // valid image type, and byte 16 here is 24, a valid TGA pixel depth. With
    // TGA probed before PNM, this file was claimed by the TGA decoder.
    final header = 'P5\n4 4\n255\n'.codeUnits; // 11 bytes
    final pixels = List<int>.generate(16, (i) => i == 5 ? 24 : (i * 15) % 256);
    final bytes = Uint8List.fromList([...header, ...pixels]);
    expect(bytes[16], 24, reason: 'the byte TGA reads as pixel depth');

    expect(findFormatForData(bytes), ImageFormat.pnm);

    final image = decodeImage(bytes);
    expect(image, isNotNull);
    expect(image!.width, 4);
    expect(image.height, 4);
  });
}
