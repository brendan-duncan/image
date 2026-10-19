import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('Transform bug fixes', () {
    for (final interp in [Interpolation.nearest, Interpolation.linear]) {
      test('copyResizeCropSquare with a radius keeps all frames ($interp)', () {
        final anim = Image(width: 20, height: 10, numChannels: 4)
          ..clear(ColorRgba8(255, 0, 0, 255))
          ..addFrame(Image(width: 20, height: 10, numChannels: 4)
            ..clear(ColorRgba8(0, 255, 0, 255)))
          ..addFrame(Image(width: 20, height: 10, numChannels: 4)
            ..clear(ColorRgba8(0, 0, 255, 255)));
        final dst = copyResizeCropSquare(anim,
            size: 8, radius: 2, interpolation: interp);
        expect(dst.numFrames, equals(3));
        expect(dst.frames[0].getPixel(4, 4).r, equals(255));
        expect(dst.frames[1].getPixel(4, 4).g, equals(255));
        expect(dst.frames[2].getPixel(4, 4).b, equals(255));
      });
    }
  });
}
