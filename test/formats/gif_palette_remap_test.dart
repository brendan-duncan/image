import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('Format', () {
    group('gif', () {
      test('palette_remap - regression test for color remap issue', () async {
        // This test ensures that animated GIFs with varying local color palettes
        // across frames can be decoded without null pointer exceptions.
        // 
        // Regression test for issue where remapColors map was built using
        // current frame's colorMap size instead of lastImage's palette size,
        // causing incomplete mapping and null pointer exceptions when a pixel
        // index from lastImage wasn't present in the remapColors map.
        //
        // This particular GIF has frames with different local color tables
        // where some palettes have more colors than others, triggering the bug.
        final image = await decodeGifFile('test/_data/gif/palette_remap.gif');

        expect(image, isNotNull,
            reason: 'Should successfully decode palette_remap.gif');
        expect(image!.width, equals(240));
        expect(image.height, equals(135));
        expect(image.numFrames, equals(21));
      });
    });
  });
}
