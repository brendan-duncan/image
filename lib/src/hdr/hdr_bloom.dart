import 'dart:math';
import 'dart:typed_data';

import '../image/image.dart';

/// Applies an HDR bloom filter to the image, in-place.
Image hdrBloom(Image hdr, {double radius = 0.01, double weight = 0.1}) {
  double _lerp(double t, double a, double b) => (1.0 - t) * a + t * b;

  //int nPix = xResolution * yResolution;
  // Possibly apply bloom effect to image
  if (radius > 0.0 && weight > 0.0) {
    // Compute image-space extent of bloom effect
    final bloomSupport = (radius * max(hdr.width, hdr.height)).ceil();
    final bloomWidth = bloomSupport ~/ 2;
    // Initialize bloom filter table
    final bloomFilter = Float32List(bloomWidth * bloomWidth);
    for (var i = 0; i < bloomWidth * bloomWidth; ++i) {
      final dist = sqrt(i / bloomWidth);
      bloomFilter[i] = pow(max(0.0, 1.0 - dist), 4.0).toDouble();
    }

    // Apply bloom filter to image pixels
    var offset = 0;
    final bloomImage = Float32List(3 * hdr.width * hdr.height);
    for (var p in hdr) {
      final x = p.x;
      final y = p.y;
      // Compute bloom for pixel _(x,y)_
      // Compute extent of pixels contributing bloom
      final x0 = max(0, x - bloomWidth);
      final x1 = min(x + bloomWidth, hdr.width - 1);
      final y0 = max(0, y - bloomWidth);
      final y1 = min(y + bloomWidth, hdr.height - 1);

      var sumWt = 0.0;
      for (var by = y0; by <= y1; ++by) {
        for (var bx = x0; bx <= x1; ++bx) {
          // Accumulate bloom from pixel $(bx,by)$
          final dx = x - bx;
          final dy = y - by;
          if (dx == 0 && dy == 0) {
            continue;
          }
          final dist2 = dx * dx + dy * dy;
          if (dist2 < bloomWidth * bloomWidth) {
            //int bloomOffset = bx + by * hdr.width;
            final wt = bloomFilter[dist2];

            sumWt += wt;

            final hp = hdr.getPixel(bx, by);
            bloomImage[3 * offset] += wt * hp.r;
            bloomImage[3 * offset + 1] += wt * hp.g;
            bloomImage[3 * offset + 2] += wt * hp.g;
          }
        }
      }

      bloomImage[3 * offset] /= sumWt;
      bloomImage[3 * offset + 1] /= sumWt;
      bloomImage[3 * offset + 2] /= sumWt;

      offset += 3;
    }

    // Mix bloom effect into each pixel
    offset = 0;
    for (var p in hdr) {
      p.r = _lerp(weight, p.r.toDouble(), bloomImage[offset]);
      p.g = _lerp(weight, p.g.toDouble(), bloomImage[offset + 1]);
      p.b = _lerp(weight, p.b.toDouble(), bloomImage[offset + 2]);
    }
  }

  return hdr;
}
