/// Assembling a VP8L lossless stream: transforms, the entropy coded image, and
/// the sub-images the transforms need.
library;

import 'dart:typed_data';

import '../../image/image.dart';
import '../../util/_internal.dart';
import '../../util/image_exception.dart';
import '../../util/output_buffer.dart';
import 'vp8l_analysis.dart';
import 'vp8l_backward_refs.dart';
import 'vp8l_bit_writer.dart';
import 'vp8l_color_cache_encoder.dart' as colorCache;
import 'vp8l_cross_color.dart';
import 'vp8l_histogram.dart';
import 'vp8l_huffman_encoder.dart' as huffman;
import 'vp8l_optimal_parse.dart';
import 'vp8l_predictor.dart' as predictor;
import 'vp8l_transparency.dart';

/// The largest image WebP can carry, in either direction.
///
/// libwebp calls this WEBP_MAX_DIMENSION. The VP8L header stores each
/// dimension less one in fourteen bits, so 16384 would fit there, but the
/// container caps it a pixel lower.
@internal
const maxDimension = 16383;

/// Encodes an image into the VP8L bitstream, without the RIFF container.
@internal
class VP8LEncoder {
  VP8LEncoder({this.exact = false});

  /// Whether the colour hidden under fully transparent pixels must be kept
  ///
  /// Clearing it flattens those pixels into long runs, which is what cwebp
  /// does unless given its own `-exact`
  final bool exact;

  Uint8List encodeVP8L(Image image) {
    final width = image.width;
    final height = image.height;
    if (width <= 0 ||
        height <= 0 ||
        width > maxDimension ||
        height > maxDimension) {
      // The VP8L header has fourteen bits for each dimension. Silently letting
      // one overflow into the next field produces a stream that no decoder can
      // read, so refuse instead. Zero is stored less one, so it would say
      // 16384.
      throw ImageException('WebP images must be between 1x1 and '
          '${maxDimension}x$maxDimension, got ${width}x$height');
    }

    final numPixels = width * height;
    final g = Uint8List(numPixels);
    final r = Uint8List(numPixels);
    final b = Uint8List(numPixels);
    final a = Uint8List(numPixels);

    // Two channels is luminance and alpha.
    final hasAlpha = image.hasAlpha;
    // Pixel.g and Pixel.b answer zero for a one channel image, so reading
    // them writes the picture in red
    final grey = image.numChannels == 1;
    // WebP carries eight bits a channel, so a deeper image is scaled, not
    // clamped: clamping turns everything above 255 white.
    final maxValue = image.maxChannelValue;
    final scale = maxValue == 255 ? 1.0 : 255.0 / maxValue;
    var alphaIsUsed = false;
    var i = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final p = image.getPixel(x, y);
        final pg = grey ? p.r : p.g;
        final pb = grey ? p.r : p.b;
        if (scale == 1.0) {
          g[i] = pg.toInt().clamp(0, 255);
          r[i] = p.r.toInt().clamp(0, 255);
          b[i] = pb.toInt().clamp(0, 255);
          a[i] = hasAlpha ? p.a.toInt().clamp(0, 255) : 255;
        } else {
          g[i] = (pg * scale).round().clamp(0, 255);
          r[i] = (p.r * scale).round().clamp(0, 255);
          b[i] = (pb * scale).round().clamp(0, 255);
          a[i] = hasAlpha ? (p.a * scale).round().clamp(0, 255) : 255;
        }
        if (a[i] != 255) alphaIsUsed = true;
        i++;
      }
    }

    // VP8L image header: signature byte 0x2f + 28-bit header (w-1, h-1,
    // alpha_is_used, version=0) packed little-endian. alpha_is_used is a hint
    // and reports whether the image actually carries transparency, not merely
    // whether it has an alpha channel, which is what libwebp records too.
    final header =
        (width - 1) | ((height - 1) << 14) | ((alphaIsUsed ? 1 : 0) << 28);
    final out = OutputBuffer()
      ..writeByte(0x2f)
      ..writeByte(header & 0xff)
      ..writeByte((header >> 8) & 0xff)
      ..writeByte((header >> 16) & 0xff)
      ..writeByte((header >> 24) & 0xff)
      ..writeBytes(
          encodeStream(r, g, b, a, width, height, alphaIsUsed: alphaIsUsed));
    return out.getBytes();
  }

  /// Encodes four colour planes as a bare VP8L stream, with no image header.
  ///
  /// The alpha channel of a lossy file is carried this way: it is a VP8L image
  /// in its own right, but its size is already known from the frame, so the
  /// header would only repeat it.
  Uint8List encodeStream(
      Uint8List r, Uint8List g, Uint8List b, Uint8List a, int width, int height,
      {required bool alphaIsUsed}) {
    // 16x16 predictor blocks, which is what libwebp settles on at its highest
    // effort (GetTransformBits caps the transform at 4 bits there). Measured
    // against 32x32 on both a screenshot corpus and the test images, it codes
    // about 0.75% smaller for the same time.
    const predSizeBits = 4;
    const predBlockSize = 1 << predSizeBits;
    final predBlockW = (width + predBlockSize - 1) ~/ predBlockSize;
    final predBlockH = (height + predBlockSize - 1) ~/ predBlockSize;
    final numPixels = width * height;

    // Pack once here: the predictors are written on a packed ARGB word, the
    // transform analysis wants the pixels as they came in, and flattening the
    // transparent areas is easiest on the same representation.
    final argb = Uint32List(numPixels);
    for (var i = 0; i < numPixels; i++) {
      argb[i] = (a[i] << 24) | (r[i] << 16) | (g[i] << 8) | b[i];
    }

    // Done before the palette is counted, since flattening collapses whatever
    // colours were hiding under transparent pixels and can bring an image
    // under the palette limit.
    if (!exact && alphaIsUsed) {
      clearTransparentPixels(argb);
      for (var i = 0; i < numPixels; i++) {
        final v = argb[i];
        r[i] = (v >> 16) & 0xff;
        g[i] = (v >> 8) & 0xff;
        b[i] = v & 0xff;
      }
    }

    // An image with few distinct colors codes far more compactly as palette
    // indices than as full pixels, so prefer the color indexing transform.
    final palette = _buildPalette(r, g, b, a, numPixels);
    if (palette != null) {
      final bw = VP8LBitWriter();
      _writePaletteImage(bw, palette, r, g, b, a, width, height);
      bw.flush();
      return bw.getBytes();
    }

    // Which transforms are worth carrying is decided from one pass over the
    // pixels rather than by building the stream each way and comparing. The
    // estimate is not exact, but every combination built in full costs a whole
    // encode, and this is how libwebp settles the same question.
    const crossBits = predSizeBits;
    final analysis = analyzeEntropy(argb, width, height, predSizeBits);

    if (analysis.useSubtractGreen) {
      _applySubtractGreenTransform(r, g, b, numPixels);
      for (var i = 0; i < numPixels; i++) {
        argb[i] = (a[i] << 24) | (r[i] << 16) | (g[i] << 8) | b[i];
      }
    }

    List<int>? predModes;
    if (analysis.usePredictor) {
      predModes = predictor.selectPredictorModes(
          argb, width, height, predBlockW, predBlockH, predBlockSize);
      predictor.applyPredictorTransform(argb, r, g, b, a, width, height,
          predBlockW, predBlockSize, predModes);
    }

    // Prediction residuals still move together across channels, and the
    // cross-color transform fits a small linear model per block to remove what
    // is left.
    List<VP8LColorMultipliers>? multipliers;
    if (analysis.useCrossColor) {
      multipliers = selectCrossColor(r, g, b, width, height, crossBits);
      if (multipliers != null) {
        applyCrossColor(r, g, b, width, height, crossBits, multipliers);
      }
    }

    // Transforms are undone in reverse order, so the one written last is undone
    // first.
    final bw = VP8LBitWriter();
    if (analysis.useSubtractGreen) {
      bw
        ..writeBits(1, 1) // has_transform = 1
        ..writeBits(2, 2); // transform_type = 2 (SUBTRACT_GREEN)
    }
    if (predModes != null) {
      bw
        ..writeBits(1, 1) // has_transform = 1
        ..writeBits(0, 2) // transform_type = 0 (PREDICTOR)
        ..writeBits(predSizeBits - 2, 3); // predictor block size bits
      predictor.writePredictorSubImage(bw, predBlockW, predBlockH, predModes);
    }
    if (multipliers != null) {
      final crossBlockW = (width + (1 << crossBits) - 1) >> crossBits;
      final crossBlockH = (height + (1 << crossBits) - 1) >> crossBits;
      bw
        ..writeBits(1, 1) // has_transform = 1
        ..writeBits(1, 2) // transform_type = 1 (CROSS_COLOR)
        ..writeBits(crossBits - 2, 3);
      _writeCrossColorSubImage(bw, crossBlockW, crossBlockH, multipliers);
    }
    bw.writeBits(0, 1); // has_transform = 0

    _writeImageStream(bw, r, g, b, a, width, numPixels, isLevel0: true);
    bw.flush();
    return bw.getBytes();
  }

  /// Writes a VP8L image stream: the color cache flag, the meta Huffman flag,
  /// the five Huffman code definitions and the LZ77 token data.
  ///
  /// [width] is the stride used to compute distance plane codes. For a color
  /// indexed image that is the packed width, not the image width.
  ///
  /// [isLevel0] must be true only for the main image. The meta Huffman flag is
  /// present just there; VP8L._readHuffmanCodes skips it for the sub-images of
  /// a transform, so writing it would desynchronize the stream.
  void _writeImageStream(VP8LBitWriter bw, Uint8List r, Uint8List g,
      Uint8List b, Uint8List a, int width, int numPixels,
      {required bool isLevel0}) {
    // Weighing a match against a literal needs to know what each costs, which
    // is only knowable once the symbol distribution exists. So take the
    // matches once, price the symbols from the plainest reading of them, and
    // only then choose the cover that actually codes smallest.
    final matches = computeMatches(r, g, b, a, numPixels, width);
    // The greedy cover is dead once priced, and the optimal one is written at
    // exactly the positions read back, so one parse serves both.
    final parse = VP8LCover(numPixels);
    _greedyCover(matches, parse);
    final costs = VP8LCostModel.fromCover(parse, r, g, b, a, width);
    optimalCover(matches, costs, r, g, b, a, width, parse);
    final refs = refsFromCover(parse);
    final tokenIsLit = refs.isLiteral;
    final tokenLitIdx = refs.literalIndex;
    final tokenLen = refs.length;
    final tokenDist = refs.distance;
    final tokenPos = refs.position;

    // Which green and distance symbol a back-reference codes as is fixed by
    // the token. Meta Huffman selection alone would derive it once per
    // candidate block size, on top of the histogram and emit passes, so derive
    // it once here instead.
    final refCount = tokenLen.length;
    final refLenSym = Int32List(refCount);
    final refDistSym = Int32List(refCount);
    for (var i = 0; i < refCount; i++) {
      refLenSym[i] = huffman.lengthSymbol(tokenLen[i]);
      refDistSym[i] =
          huffman.prefixCode(huffman.distToPlaneCode(width, tokenDist[i]));
    }

    // The decoder inserts every pixel into the color cache in raster order and
    // refreshes it right before each lookup, so the cache contents at a given
    // position depend only on the pixels, never on how they were tokenized.
    // That lets several cache sizes be scored without redoing the tokenization.
    final cacheKeys = Int32List(tokenLitIdx.length);
    final cacheBits = colorCache.selectColorCacheBits(r, g, b, a, tokenIsLit,
        tokenLitIdx, tokenLen, tokenDist, width, cacheKeys);
    final greenAlphabetSize = 280 + (cacheBits > 0 ? 1 << cacheBits : 0);

    if (cacheBits > 0) {
      bw
        ..writeBits(1, 1) // color cache present
        ..writeBits(cacheBits, 4);
    } else {
      bw.writeBits(0, 1); // no color cache
    }

    // One set of codes has to serve the whole image unless meta Huffman splits
    // it into regions that each get their own. Sub-images are small and never
    // carry the flag, so only the main image is considered.
    final meta = isLevel0
        ? _selectMetaHuffman(
            r,
            g,
            b,
            a,
            tokenIsLit,
            tokenLitIdx,
            refLenSym,
            refDistSym,
            tokenPos,
            cacheKeys,
            width,
            numPixels,
            greenAlphabetSize)
        : null;

    if (isLevel0) {
      if (meta == null) {
        bw.writeBits(0, 1); // no meta Huffman codes
      } else {
        bw
          ..writeBits(1, 1)
          ..writeBits(meta.bits - _minHuffmanBits, _numHuffmanBits);
        _writeEntropyImage(bw, meta);
      }
    }

    final numGroups = meta?.clustering.numGroups ?? 1;
    // Which group each token belongs to, resolved once for the two passes that
    // follow. Tokens are in raster order, so the row advances from the
    // previous token rather than being divided out of the position.
    final tokenGroup = Int32List(tokenIsLit.length);
    if (meta != null) {
      final assignment = meta.clustering.assignment;
      final bits = meta.bits;
      final xsize = meta.xsize;
      var rowStart = 0;
      var y = 0;
      for (var t = 0; t < tokenIsLit.length; t++) {
        final p = tokenPos[t];
        while (p - rowStart >= width) {
          rowStart += width;
          y++;
        }
        tokenGroup[t] =
            assignment[(y >> bits) * xsize + ((p - rowStart) >> bits)];
      }
    }

    // Count symbols per group. VP8L codes with five alphabets:
    //   green: 256 literals + 24 LZ77 length codes + one per cache entry
    //   red, blue, alpha: 256 each
    //   dist: 40 LZ77 distance prefix codes
    final histograms = List.generate(
        numGroups, (_) => VP8LHistogram(greenAlphabetSize),
        growable: false);

    var litPtr = 0;
    var refPtr = 0;
    for (var t = 0; t < tokenIsLit.length; t++) {
      final h = histograms[tokenGroup[t]];
      if (tokenIsLit[t] != 0) {
        final key = cacheKeys[litPtr];
        final idx = tokenLitIdx[litPtr++];
        if (key >= 0) {
          h.addCacheRef(key);
        } else {
          h.addLiteral(r[idx], g[idx], b[idx], a[idx]);
        }
      } else {
        h.addCopy(refLenSym[refPtr], refDistSym[refPtr]);
        refPtr++;
      }
    }

    // Build and write the code definitions, one full set per group, in the
    // order the decoder reads them.
    final codes = <_HuffmanCodes>[];
    for (final h in histograms) {
      codes.add(_HuffmanCodes(h, greenAlphabetSize)..write(bw));
    }

    // Write token stream.
    litPtr = 0;
    refPtr = 0;
    for (var t = 0; t < tokenIsLit.length; t++) {
      final c = codes[tokenGroup[t]];
      if (tokenIsLit[t] != 0) {
        final key = cacheKeys[litPtr];
        final idx = tokenLitIdx[litPtr++];
        if (key >= 0) {
          c.writeSymbol(bw, c.green, c.greenLen, 280 + key);
        } else {
          c
            ..writeSymbol(bw, c.green, c.greenLen, g[idx])
            ..writeSymbol(bw, c.red, c.redLen, r[idx])
            ..writeSymbol(bw, c.blue, c.blueLen, b[idx])
            ..writeSymbol(bw, c.alpha, c.alphaLen, a[idx]);
        }
      } else {
        final len = tokenLen[refPtr];
        final dist = tokenDist[refPtr];
        refPtr++;

        // Write length prefix in the green channel.
        c.writeSymbol(bw, c.green, c.greenLen, huffman.lengthSymbol(len));
        final (lExtra, lVal) = huffman.lengthExtra(len);
        if (lExtra > 0) bw.writeBits(lVal, lExtra);

        // Write distance prefix in the dist channel.
        final planeCode = huffman.distToPlaneCode(width, dist);
        c.writeSymbol(bw, c.dist, c.distLen, huffman.prefixCode(planeCode));
        final (dExtra, dVal) = huffman.prefixExtra(planeCode);
        if (dExtra > 0) bw.writeBits(dVal, dExtra);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Meta Huffman
  // ---------------------------------------------------------------------------

  /// Block sizes the meta Huffman search considers, as VP8L's precision value
  /// (a block spans 2^bits pixels). The format allows 2..9.
  /// Entropy image block sizes to weigh against each other.
  ///
  /// libwebp computes a single size by formula (`GetHistoBits`) rather than
  /// trying any. Measured here: the formula is 4.6% faster but costs 0.13
  /// points on Kodak and 0.44 on the PNG suite, because on smaller images the
  /// entropy image is cheap enough that a finer split pays. Large images are
  /// unaffected, since [_maxEntropyImageSize] already rules the finer sizes out
  /// for them.
  static const _metaHuffmanCandidates = [4, 5, 6];

  /// Most blocks an entropy image may be split into, libwebp's
  /// MAX_HUFF_IMAGE_SIZE.
  ///
  /// Past this the entropy image costs more to describe than the finer
  /// statistics save, so libwebp raises the block size until it fits rather
  /// than considering the finer split at all. Skipping those candidates costs
  /// nothing measurable in size and is a good deal of the selection time: on a
  /// 1922x1107 screenshot the 16-pixel candidate alone builds 8470 histograms.
  static const _maxEntropyImageSize = 2600;
  static const _minHuffmanBits = 2;
  static const _numHuffmanBits = 3;

  /// Chooses a block size and a grouping of blocks, or null when a single set
  /// of codes for the whole image is no more expensive.
  _MetaHuffman? _selectMetaHuffman(
      Uint8List r,
      Uint8List g,
      Uint8List b,
      Uint8List a,
      Uint8List tokenIsLit,
      Int32List tokenLitIdx,
      Int32List refLenSym,
      Int32List refDistSym,
      Int32List tokenPos,
      Int32List cacheKeys,
      int width,
      int numPixels,
      int greenAlphabetSize) {
    final height = numPixels ~/ width;
    _MetaHuffman? best;

    for (final bits in _metaHuffmanCandidates) {
      final xsize = _subSampleSize(width, bits);
      final ysize = _subSampleSize(height, bits);
      if (xsize * ysize < 2 || xsize * ysize > _maxEntropyImageSize) {
        continue;
      }

      final blocks = List.generate(
          xsize * ysize, (_) => VP8LHistogram(greenAlphabetSize),
          growable: false);

      var litPtr = 0;
      var refPtr = 0;
      // Tokens come in raster order, so the row a token starts in is reached
      // by advancing from the previous one. Dividing the position by the width
      // instead costs a real integer division per token, and this loop runs
      // once per candidate block size.
      var rowStart = 0;
      var y = 0;
      for (var t = 0; t < tokenIsLit.length; t++) {
        final p = tokenPos[t];
        while (p - rowStart >= width) {
          rowStart += width;
          y++;
        }
        final h = blocks[(y >> bits) * xsize + ((p - rowStart) >> bits)];
        if (tokenIsLit[t] != 0) {
          final key = cacheKeys[litPtr];
          final idx = tokenLitIdx[litPtr++];
          if (key >= 0) {
            h.addCacheRef(key);
          } else {
            h.addLiteral(r[idx], g[idx], b[idx], a[idx]);
          }
        } else {
          h.addCopy(refLenSym[refPtr], refDistSym[refPtr]);
          refPtr++;
        }
      }

      final clustering = clusterHistograms(blocks);
      if (clustering != null &&
          (best == null || clustering.cost < best.clustering.cost)) {
        best = _MetaHuffman(bits, xsize, ysize, clustering);
      }
    }

    return best;
  }

  /// Writes the entropy image, which tells the decoder which group each block
  /// belongs to. The index is carried in the red and green bytes.
  void _writeEntropyImage(VP8LBitWriter bw, _MetaHuffman meta) {
    final n = meta.xsize * meta.ysize;
    final er = Uint8List(n);
    final eg = Uint8List(n);
    final eb = Uint8List(n);
    final ea = Uint8List(n)..fillRange(0, n, 255);
    for (var i = 0; i < n; i++) {
      final group = meta.clustering.assignment[i];
      // The format carries a 16 bit group index across the red and green
      // bytes. clusterHistograms caps the count far below 256, so the red byte
      // is always zero in practice; writing it anyway keeps this correct if
      // that cap is ever raised.
      er[i] = (group >> 8) & 0xff;
      eg[i] = group & 0xff;
    }
    _writeImageStream(bw, er, eg, eb, ea, meta.xsize, n, isLevel0: false);
  }

  // ---------------------------------------------------------------------------
  // Transforms
  // ---------------------------------------------------------------------------

  /// The color indexing transform can address at most this many colors.
  static const _maxPaletteSize = 256;

  /// The distinct colors of the image in ascending ARGB order, or null if the
  /// image holds more than [_maxPaletteSize] of them.
  Uint32List? _buildPalette(
      Uint8List r, Uint8List g, Uint8List b, Uint8List a, int numPixels) {
    final colors = <int>{};
    for (var i = 0; i < numPixels; i++) {
      final argb = (a[i] << 24) | (r[i] << 16) | (g[i] << 8) | b[i];
      if (colors.add(argb) && colors.length > _maxPaletteSize) {
        return null;
      }
    }
    // Ascending ARGB. libwebp also offers an order that minimises the
    // difference between neighbouring entries, since the palette is stored
    // delta-coded; ported and measured at 360 bytes *worse* over a 587 image
    // corpus. It optimises the palette's own storage, which is at most a few
    // hundred bytes, while the indices it does not touch are the bulk of the
    // data. Its co-occurrence-based sibling (PaletteSortModifiedZeng) targets
    // the indices instead and would be the one to try, but palette images are
    // 0.7% of that corpus by size, so there is little there to win.
    return Uint32List.fromList(colors.toList()..sort());
  }

  /// How many index bits are packed into a single byte for a palette of
  /// [numColors] entries. Mirrors the reader in VP8L._readTransform.
  static int _paletteBits(int numColors) => numColors > 16
      ? 0
      : numColors > 4
          ? 1
          : numColors > 2
              ? 2
              : 3;

  static int _subSampleSize(int size, int samplingBits) =>
      (size + (1 << samplingBits) - 1) >> samplingBits;

  /// Writes the color indexing transform followed by the indexed image.
  ///
  /// The palette itself is stored as a numColors x 1 image stream, and each
  /// pixel of the main image is replaced by its palette index carried in the
  /// green channel. Neither the subtract-green nor the predictor transform is
  /// useful on index data, so neither is emitted here.
  void _writePaletteImage(VP8LBitWriter bw, Uint32List palette, Uint8List r,
      Uint8List g, Uint8List b, Uint8List a, int width, int height) {
    final numColors = palette.length;

    bw
      ..writeBits(1, 1) // has_transform = 1
      ..writeBits(3, 2) // transform_type = 3 (COLOR_INDEXING)
      ..writeBits(numColors - 1, 8);

    // Palette entries are stored as per-channel differences to the previous
    // entry, which the decoder accumulates back in _expandColorMap.
    final pr = Uint8List(numColors);
    final pg = Uint8List(numColors);
    final pb = Uint8List(numColors);
    final pa = Uint8List(numColors);
    var prevR = 0;
    var prevG = 0;
    var prevB = 0;
    var prevA = 0;
    for (var i = 0; i < numColors; i++) {
      final c = palette[i];
      final ca = (c >> 24) & 0xff;
      final cr = (c >> 16) & 0xff;
      final cg = (c >> 8) & 0xff;
      final cb = c & 0xff;
      pr[i] = (cr - prevR) & 0xff;
      pg[i] = (cg - prevG) & 0xff;
      pb[i] = (cb - prevB) & 0xff;
      pa[i] = (ca - prevA) & 0xff;
      prevR = cr;
      prevG = cg;
      prevB = cb;
      prevA = ca;
    }
    _writeImageStream(bw, pr, pg, pb, pa, numColors, numColors,
        isLevel0: false);

    bw.writeBits(0, 1); // has_transform = 0

    final indexOf = <int, int>{};
    for (var i = 0; i < numColors; i++) {
      indexOf[palette[i]] = i;
    }

    final bits = _paletteBits(numColors);
    final packedWidth = _subSampleSize(width, bits);
    final numPacked = packedWidth * height;
    final indices = Uint8List(numPacked);
    // The decoder reads the index out of the green channel and ignores the
    // others, so leaving them at zero costs almost nothing to code.
    final zero = Uint8List(numPacked);

    if (bits == 0) {
      for (var i = 0; i < width * height; i++) {
        indices[i] = indexOf[(a[i] << 24) | (r[i] << 16) | (g[i] << 8) | b[i]]!;
      }
    } else {
      final bitsPerPixel = 8 >> bits;
      final pixelsPerByte = 1 << bits;
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final i = y * width + x;
          final v = indexOf[(a[i] << 24) | (r[i] << 16) | (g[i] << 8) | b[i]]!;
          indices[y * packedWidth + (x >> bits)] |=
              v << ((x & (pixelsPerByte - 1)) * bitsPerPixel);
        }
      }
    }

    _writeImageStream(bw, zero, indices, zero, zero, packedWidth, numPacked,
        isLevel0: true);
  }

  void _applySubtractGreenTransform(
    Uint8List r,
    Uint8List g,
    Uint8List b,
    int numPixels,
  ) {
    for (var i = 0; i < numPixels; i++) {
      r[i] = (r[i] - g[i]) & 0xFF;
      b[i] = (b[i] - g[i]) & 0xFF;
    }
  }

  /// Takes every match on offer, which is what the symbols have to be priced
  /// from before any better cover can be judged.
  static void _greedyCover(VP8LMatches matches, VP8LCover parse) {
    final numPixels = parse.numPixels;
    final cover = parse.cover;
    final distance = parse.distance;
    var i = 0;
    while (i < numPixels) {
      final len = matches.length[i];
      final take = len >= 3 ? len : 1;
      cover[i] = take;
      distance[i] = matches.distance[i];
      i += take;
    }
  }

  /// Writes the cross-color sub-image, one pixel per block holding that
  /// block's three multipliers.
  void _writeCrossColorSubImage(VP8LBitWriter bw, int blockW, int blockH,
      List<VP8LColorMultipliers> multipliers) {
    final n = blockW * blockH;
    final cr = Uint8List(n);
    final cg = Uint8List(n);
    final cb = Uint8List(n);
    final ca = Uint8List(n)..fillRange(0, n, 255);
    for (var i = 0; i < n; i++) {
      cr[i] = multipliers[i].red;
      cg[i] = multipliers[i].green;
      cb[i] = multipliers[i].blue;
    }
    _writeImageStream(bw, cr, cg, cb, ca, blockW, n, isLevel0: false);
  }
}

/// A chosen meta Huffman layout: the block size and which group each block
/// belongs to.
class _MetaHuffman {
  _MetaHuffman(this.bits, this.xsize, this.ysize, this.clustering);

  /// Blocks span 2^bits pixels each way.
  final int bits;
  final int xsize;
  final int ysize;
  final VP8LClustering clustering;
}

/// One meta Huffman group's five Huffman codes, ready to write with.
class _HuffmanCodes {
  _HuffmanCodes(VP8LHistogram h, this.greenAlphabetSize)
      : greenLen = huffman.buildHuffmanCodeLengths(h.green, greenAlphabetSize),
        redLen = huffman.buildHuffmanCodeLengths(h.red, 256),
        blueLen = huffman.buildHuffmanCodeLengths(h.blue, 256),
        alphaLen = huffman.buildHuffmanCodeLengths(h.alpha, 256),
        distLen = huffman.buildHuffmanCodeLengths(h.dist, 40);

  final int greenAlphabetSize;
  final List<int> greenLen;
  final List<int> redLen;
  final List<int> blueLen;
  final List<int> alphaLen;
  final List<int> distLen;

  late final List<int> green;
  late final List<int> red;
  late final List<int> blue;
  late final List<int> alpha;
  late final List<int> dist;

  /// Writes the code definitions and derives the codes used to encode with.
  ///
  /// The two go together because writing a single-symbol code zeroes its length
  /// in place, which the canonical codes then have to reflect.
  void write(VP8LBitWriter bw) {
    huffman.writeHuffmanCode(bw, greenAlphabetSize, greenLen);
    huffman.writeHuffmanCode(bw, 256, redLen);
    huffman.writeHuffmanCode(bw, 256, blueLen);
    huffman.writeHuffmanCode(bw, 256, alphaLen);
    huffman.writeHuffmanCode(bw, 40, distLen);

    green =
        huffman.canonicalCodes(Int32List.fromList(greenLen), greenAlphabetSize);
    red = huffman.canonicalCodes(Int32List.fromList(redLen), 256);
    blue = huffman.canonicalCodes(Int32List.fromList(blueLen), 256);
    alpha = huffman.canonicalCodes(Int32List.fromList(alphaLen), 256);
    dist = huffman.canonicalCodes(Int32List.fromList(distLen), 40);
  }

  void writeSymbol(
          VP8LBitWriter bw, List<int> codes, List<int> lengths, int symbol) =>
      bw.writeBits(codes[symbol], lengths[symbol]);
}
