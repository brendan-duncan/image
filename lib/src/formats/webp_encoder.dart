import 'dart:typed_data';

import '../image/image.dart';
import '../util/output_buffer.dart';
import 'encoder.dart';

/// Encode an image to the WebP format (lossless).
///
/// Uses the VP8L lossless bitstream format wrapped in a RIFF/WebP container.
/// Applies the subtract-green transform and LZ77 back-references.
class WebPEncoder extends Encoder {
  @override
  Uint8List encode(Image image, {bool singleFrame = false}) {
    final width = image.width;
    final height = image.height;

    final vp8lData = _encodeVP8L(image, width, height);

    // Wrap in RIFF/WebP container
    final out = OutputBuffer();
    final paddedLen = vp8lData.length + (vp8lData.length.isOdd ? 1 : 0);
    final fileSize = 4 /* 'WEBP' */ + 8 /* 'VP8L' + chunk size */ + paddedLen;
    out
      ..writeBytes(_tag('RIFF'))
      ..writeUint32(fileSize)
      ..writeBytes(_tag('WEBP'))
      ..writeBytes(_tag('VP8L'))
      ..writeUint32(vp8lData.length)
      ..writeBytes(vp8lData);
    if (vp8lData.length.isOdd) out.writeByte(0);

    return out.getBytes();
  }

  Uint8List _encodeVP8L(Image image, int width, int height) {
    final out = OutputBuffer();

    // VP8L image header: signature byte 0x2f + 28-bit header (w-1, h-1,
    // alpha_is_used, version=0) packed little-endian.
    final hasAlpha = image.numChannels >= 4;
    final header =
        (width - 1) | ((height - 1) << 14) | ((hasAlpha ? 1 : 0) << 28);
    out
      ..writeByte(0x2f)
      ..writeByte(header & 0xff)
      ..writeByte((header >> 8) & 0xff)
      ..writeByte((header >> 16) & 0xff)
      ..writeByte((header >> 24) & 0xff);

    // Collect pixel data first (needed for predictor mode selection).
    const predSizeBits = 5; // blockSize = 2^5 = 32
    const predBlockSize = 1 << predSizeBits;
    final predBlockW = (width + predBlockSize - 1) ~/ predBlockSize;
    final predBlockH = (height + predBlockSize - 1) ~/ predBlockSize;
    final numPixels = width * height;
    final g = Uint8List(numPixels);
    final r = Uint8List(numPixels);
    final b = Uint8List(numPixels);
    final a = Uint8List(numPixels);

    var i = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final p = image.getPixel(x, y);
        g[i] = p.g.toInt().clamp(0, 255);
        r[i] = p.r.toInt().clamp(0, 255);
        b[i] = p.b.toInt().clamp(0, 255);
        a[i] = hasAlpha ? p.a.toInt().clamp(0, 255) : 255;
        i++;
      }
    }

    // Apply Subtract Green Transform
    _applySubtractGreenTransform(r, g, b, numPixels);

    // Choose best predictor mode per 32×32 block.
    // This is done on the subtracted data.
    final predModes = _selectPredictorModes(
        r, g, b, a, width, height, predBlockW, predBlockH, predBlockSize);

    // Apply Predictor Transform
    _applyPredictorTransform(
        r, g, b, a, width, height, predBlockW, predBlockSize, predModes);

    final bw = _BitWriter()
      // Write Subtract Green Transform
      ..writeBits(1, 1) // has_transform = 1
      ..writeBits(2, 2) // transform_type = 2 (SUBTRACT_GREEN)
      // Write Predictor Transform
      ..writeBits(1, 1) // has_transform = 1
      ..writeBits(0, 2) // transform_type = 0 (PREDICTOR)
      ..writeBits(predSizeBits - 2, 3); // predictor block size bits (5 - 2 = 3)
    _writePredictorSubImage(bw, predBlockW, predBlockH, predModes);

    // Finish transforms
    bw
      ..writeBits(0, 1) // has_transform = 0
      ..writeBits(0, 1) // no color cache
      ..writeBits(0, 1); // no meta Huffman codes

    // Tokenize into literals and LZ77 back-references using a hash chain.
    // Token encoding:
    //   literalAt: list of pixel indices for literal tokens
    //   copyLen/copyDist: parallel lists for back-reference length and distance
    //   isLit: bool array indexed by token order
    final tokenIsLit = <bool>[];
    final tokenLitIdx = <int>[]; // pixel index (for literals)
    final tokenLen = <int>[]; // match length (for back-refs)
    final tokenDist = <int>[]; // pixel distance (for back-refs)

    // Hash table: RGBA key → recent positions (newest first, up to maxChain).
    const maxChain = 64;
    const maxMatchLen = 4096;
    final hashChain = <int, List<int>>{};

    void addToHash(int pos) {
      final key = (g[pos] << 24) | (r[pos] << 16) | (b[pos] << 8) | a[pos];
      final list = hashChain.putIfAbsent(key, () => <int>[]);
      if (list.length >= maxChain) list.removeAt(0);
      list.add(pos);
    }

    var j = 0;
    while (j < numPixels) {
      // Build RGBA key for current position.
      final key = (g[j] << 24) | (r[j] << 16) | (b[j] << 8) | a[j];

      // Search for best match.
      var bestLen = 0;
      var bestDist = 0;
      final candidates = hashChain[key];
      if (j > 0 && candidates != null) {
        for (var ci = candidates.length - 1; ci >= 0; ci--) {
          final c = candidates[ci];
          final dist = j - c;
          // Extend the match forward.
          var len = 1;
          while (len < maxMatchLen &&
              j + len < numPixels &&
              g[j + len] == g[c + len] &&
              r[j + len] == r[c + len] &&
              b[j + len] == b[c + len] &&
              a[j + len] == a[c + len]) {
            len++;
          }
          if (len > bestLen || (len == bestLen && dist < bestDist)) {
            bestLen = len;
            bestDist = dist;
          }
        }
      }

      if (bestLen >= 3) {
        tokenIsLit.add(false);
        tokenLen.add(bestLen);
        tokenDist.add(bestDist);
        // Add all covered positions to hash (enables future matches into this
        // region). Only add if we have space; skip the last position to avoid
        // self-referential additions.
        for (var k = 0; k < bestLen; k++) {
          addToHash(j + k);
        }
        j += bestLen;
      } else {
        tokenIsLit.add(true);
        tokenLitIdx.add(j);
        addToHash(j);
        j++;
      }
    }

    // Build frequency tables. VP8L uses 5 Huffman code groups:
    //   Group 0 (green): 280 symbols (256 literals + 24 LZ77 length codes)
    //   Group 1 (red):   256 symbols (r' after subtract-green transform)
    //   Group 2 (blue):  256 symbols (b' after subtract-green transform)
    //   Group 3 (alpha): 256 symbols
    //   Group 4 (dist):  40 symbols  (LZ77 distance prefix codes)
    final greenFreq = List<int>.filled(280, 0);
    final redFreq = List<int>.filled(256, 0);
    final blueFreq = List<int>.filled(256, 0);
    final alphaFreq = List<int>.filled(256, 0);
    final distFreq = List<int>.filled(40, 0);

    var litPtr = 0;
    var refPtr = 0;
    for (final isLit in tokenIsLit) {
      if (isLit) {
        final idx = tokenLitIdx[litPtr++];
        greenFreq[g[idx]]++;
        redFreq[r[idx]]++;
        blueFreq[b[idx]]++;
        alphaFreq[a[idx]]++;
      } else {
        final len = tokenLen[refPtr];
        final dist = tokenDist[refPtr];
        refPtr++;
        greenFreq[_lengthSymbol(len)]++;
        final planeCode = _distToPlaneCode(width, dist);
        distFreq[_prefixCode(planeCode)]++;
      }
    }

    // Build optimal Huffman code lengths.
    final greenCl = _buildHuffmanCodeLengths(greenFreq, 280);
    final redCl = _buildHuffmanCodeLengths(redFreq, 256);
    final blueCl = _buildHuffmanCodeLengths(blueFreq, 256);
    final alphaCl = _buildHuffmanCodeLengths(alphaFreq, 256);
    final distCl = _buildHuffmanCodeLengths(distFreq, 40);

    // Write Huffman code definitions.
    _writeHuffmanCode(bw, 280, greenCl);
    _writeHuffmanCode(bw, 256, redCl);
    _writeHuffmanCode(bw, 256, blueCl);
    _writeHuffmanCode(bw, 256, alphaCl);
    _writeHuffmanCode(bw, 40, distCl);

    // Build canonical codes for encoding.
    final greenCodes = _canonicalCodes(Int32List.fromList(greenCl), 280);
    final redCodes = _canonicalCodes(Int32List.fromList(redCl), 256);
    final blueCodes = _canonicalCodes(Int32List.fromList(blueCl), 256);
    final alphaCodes = _canonicalCodes(Int32List.fromList(alphaCl), 256);
    final distCodes = _canonicalCodes(Int32List.fromList(distCl), 40);

    // Write token stream.
    litPtr = 0;
    refPtr = 0;
    for (final isLit in tokenIsLit) {
      if (isLit) {
        final idx = tokenLitIdx[litPtr++];
        bw
          ..writeBits(greenCodes[g[idx]], greenCl[g[idx]])
          ..writeBits(redCodes[r[idx]], redCl[r[idx]])
          ..writeBits(blueCodes[b[idx]], blueCl[b[idx]])
          ..writeBits(alphaCodes[a[idx]], alphaCl[a[idx]]);
      } else {
        final len = tokenLen[refPtr];
        final dist = tokenDist[refPtr];
        refPtr++;

        // Write length prefix in the green channel.
        final lSym = _lengthSymbol(len);
        bw.writeBits(greenCodes[lSym], greenCl[lSym]);
        final (lExtra, lVal) = _lengthExtra(len);
        if (lExtra > 0) bw.writeBits(lVal, lExtra);

        // Write distance prefix in the dist channel.
        final planeCode = _distToPlaneCode(width, dist);
        final dSym = _prefixCode(planeCode);
        bw.writeBits(distCodes[dSym], distCl[dSym]);
        final (dExtra, dVal) = _prefixExtra(planeCode);
        if (dExtra > 0) bw.writeBits(dVal, dExtra);
      }
    }

    bw.flush();
    out.writeBytes(bw.getBytes());
    return out.getBytes();
  }

  // ---------------------------------------------------------------------------
  // Transforms
  // ---------------------------------------------------------------------------

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

  /// Select the best predictor mode for each [blockW]×[blockH] block.
  /// Tries modes 1, 2, 7, 11 and picks the one minimising |residuals|.
  List<int> _selectPredictorModes(
    Uint8List r,
    Uint8List g,
    Uint8List b,
    Uint8List a,
    int width,
    int height,
    int blockW,
    int blockH,
    int blockSize,
  ) {
    const candidates = [1, 2, 7, 11];
    final modes = List<int>.filled(blockW * blockH, 11);
    for (var by = 0; by < blockH; by++) {
      for (var bx = 0; bx < blockW; bx++) {
        final x0 = bx * blockSize;
        final y0 = by * blockSize;
        final x1 = (x0 + blockSize).clamp(0, width);
        final y1 = (y0 + blockSize).clamp(0, height);
        var bestMode = 11;
        var bestCost = 0x7fffffff;
        for (final m in candidates) {
          var cost = 0;
          for (var y = y0; y < y1; y++) {
            for (var x = x0; x < x1; x++) {
              final idx = y * width + x;
              int pR, pG, pB;
              if (y == 0 && x == 0) {
                pR = 0;
                pG = 0;
                pB = 0;
              } else if (y == 0) {
                final li = idx - 1;
                pR = r[li];
                pG = g[li];
                pB = b[li];
              } else if (x == 0) {
                final ti = idx - width;
                pR = r[ti];
                pG = g[ti];
                pB = b[ti];
              } else {
                final li = idx - 1;
                final ti = idx - width;
                switch (m) {
                  case 1:
                    pR = r[li];
                    pG = g[li];
                    pB = b[li];
                  case 2:
                    pR = r[ti];
                    pG = g[ti];
                    pB = b[ti];
                  case 7:
                    pR = (r[li] + r[ti]) >> 1;
                    pG = (g[li] + g[ti]) >> 1;
                    pB = (b[li] + b[ti]) >> 1;
                  default: // 11: select
                    final tli = ti - 1;
                    final sl = (r[li] - r[tli]).abs() +
                        (g[li] - g[tli]).abs() +
                        (b[li] - b[tli]).abs();
                    final st = (r[ti] - r[tli]).abs() +
                        (g[ti] - g[tli]).abs() +
                        (b[ti] - b[tli]).abs();
                    if (sl <= st) {
                      pR = r[ti];
                      pG = g[ti];
                      pB = b[ti];
                    } else {
                      pR = r[li];
                      pG = g[li];
                      pB = b[li];
                    }
                }
              }
              final dr = (r[idx] - pR) & 0xFF;
              final dg = (g[idx] - pG) & 0xFF;
              final db = (b[idx] - pB) & 0xFF;
              // Signed magnitude: values > 127 wrap to negative residuals.
              cost += dr < 128 ? dr : 256 - dr;
              cost += dg < 128 ? dg : 256 - dg;
              cost += db < 128 ? db : 256 - db;
            }
          }
          if (cost < bestCost) {
            bestCost = cost;
            bestMode = m;
          }
        }
        modes[by * blockW + bx] = bestMode;
      }
    }
    return modes;
  }

  /// Apply VP8L predictor transform in-place using per-block [modes].
  /// Edge rules match the decoder: (0,0)=black, y==0=mode1, x==0=mode2.
  void _applyPredictorTransform(
    Uint8List r,
    Uint8List g,
    Uint8List b,
    Uint8List a,
    int width,
    int height,
    int blockW,
    int blockSize,
    List<int> modes,
  ) {
    final origR = Uint8List.fromList(r);
    final origG = Uint8List.fromList(g);
    final origB = Uint8List.fromList(b);
    final origA = Uint8List.fromList(a);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        int pR, pG, pB, pA;
        if (y == 0 && x == 0) {
          pA = 255;
          pR = 0;
          pG = 0;
          pB = 0;
        } else if (y == 0) {
          final li = i - 1;
          pR = origR[li];
          pG = origG[li];
          pB = origB[li];
          pA = origA[li];
        } else if (x == 0) {
          final ti = i - width;
          pR = origR[ti];
          pG = origG[ti];
          pB = origB[ti];
          pA = origA[ti];
        } else {
          final li = i - 1;
          final ti = i - width;
          final shift = blockSize.bitLength - 1;
          final mode = modes[(y >> shift) * blockW + (x >> shift)];
          switch (mode) {
            case 1: // left
              pR = origR[li];
              pG = origG[li];
              pB = origB[li];
              pA = origA[li];
            case 2: // top
              pR = origR[ti];
              pG = origG[ti];
              pB = origB[ti];
              pA = origA[ti];
            case 7: // average(left, top)
              pR = (origR[li] + origR[ti]) >> 1;
              pG = (origG[li] + origG[ti]) >> 1;
              pB = (origB[li] + origB[ti]) >> 1;
              pA = (origA[li] + origA[ti]) >> 1;
            default: // 11: select(top, left, topLeft)
              final tli = ti - 1;
              final sl = (origR[li] - origR[tli]).abs() +
                  (origG[li] - origG[tli]).abs() +
                  (origB[li] - origB[tli]).abs() +
                  (origA[li] - origA[tli]).abs();
              final st = (origR[ti] - origR[tli]).abs() +
                  (origG[ti] - origG[tli]).abs() +
                  (origB[ti] - origB[tli]).abs() +
                  (origA[ti] - origA[tli]).abs();
              if (sl <= st) {
                pR = origR[ti];
                pG = origG[ti];
                pB = origB[ti];
                pA = origA[ti];
              } else {
                pR = origR[li];
                pG = origG[li];
                pB = origB[li];
                pA = origA[li];
              }
          }
        }
        r[i] = (origR[i] - pR) & 0xFF;
        g[i] = (origG[i] - pG) & 0xFF;
        b[i] = (origB[i] - pB) & 0xFF;
        a[i] = (origA[i] - pA) & 0xFF;
      }
    }
  }

  /// Write a VP8L predictor sub-image inline (no RIFF, no signature, no
  /// transform loop) using per-block predictor [modes].
  void _writePredictorSubImage(
      _BitWriter bw, int blockW, int blockH, List<int> modes) {
    final n = blockW * blockH;
    // Build green-channel frequency table for the sub-image pixels.
    final greenFreq = List<int>.filled(280, 0);
    for (final m in modes) {
      greenFreq[m]++;
    }
    final greenCl = _buildHuffmanCodeLengths(greenFreq, 280);
    final greenCodes = _canonicalCodes(Int32List.fromList(greenCl), 280);

    // Sub-image format (decoded with isLevel0=false, allowRecursion=false):
    // no color cache, then 5 Huffman groups, then pixel data.
    bw.writeBits(0, 1); // no color cache
    // Green (280): normal Huffman for the mode values.
    _writeHuffmanCode(bw, 280, greenCl);
    // Red/Blue (256): all 0 → simple, 1-bit symbol = 0.
    // Alpha (256): all 255 → simple, 8-bit symbol = 255.
    // Dist (40): unused → simple, 1-bit symbol = 0.
    bw
      ..writeBits(1, 1) // red: is_simple=1
      ..writeBits(0, 1) // 1 symbol
      ..writeBits(0, 1) // 1-bit symbol
      ..writeBits(0, 1) // symbol = 0
      ..writeBits(1, 1) // blue: is_simple=1
      ..writeBits(0, 1)
      ..writeBits(0, 1)
      ..writeBits(0, 1)
      ..writeBits(1, 1) // alpha: is_simple=1
      ..writeBits(0, 1)
      ..writeBits(1, 1) // 8-bit symbol
      ..writeBits(255, 8)
      ..writeBits(1, 1) // dist: is_simple=1
      ..writeBits(0, 1)
      ..writeBits(0, 1)
      ..writeBits(0, 1);
    // Pixel data: blockW*blockH pixels with G=modes[i], R=0, B=0, A=255.
    // Red/blue/alpha each have a 1-symbol code → 1 bit each.
    for (var i = 0; i < n; i++) {
      final m = modes[i];
      bw.writeBits(greenCodes[m], greenCl[m]); // green = predictor mode
    }
  }

  // ---------------------------------------------------------------------------
  // VP8L length and distance encoding helpers
  // ---------------------------------------------------------------------------

  /// VP8L green-channel symbol for a back-reference of [length].
  int _lengthSymbol(int length) {
    assert(length >= 1 && length <= 4096);
    if (length <= 4) return 255 + length; // symbols 256..259
    final msb = _log2Floor(length - 1);
    final half = (length - 1) >> (msb - 1) & 1;
    return 256 + 2 * msb + half; // symbols 260..279
  }

  /// Extra bits for VP8L length prefix code for back-reference [length].
  (int extraBits, int extraValue) _lengthExtra(int length) {
    if (length <= 4) return (0, 0);
    final msb = _log2Floor(length - 1);
    final half = (length - 1) >> (msb - 1) & 1;
    final eb = msb - 1;
    final base = (2 + half) << eb;
    return (eb, (length - 1) - base);
  }

  /// Convert a pixel distance to the VP8L plane code (intermediate value).
  int _distToPlaneCode(int width, int dist) {
    final yoff = dist ~/ width;
    final xoff = dist - yoff * width;
    if (xoff <= 8 && yoff < 8) {
      return _planeLut[yoff * 16 + 8 - xoff] + 1;
    } else if (xoff > width - 8 && yoff < 7) {
      return _planeLut[(yoff + 1) * 16 + 8 + width - xoff] + 1;
    }
    return dist + 120;
  }

  /// VP8L prefix code (dist alphabet symbol) for a plane code [v].
  int _prefixCode(int v) {
    final val = v - 1;
    if (val < 4) return val;
    final msb = _log2Floor(val);
    final half = val >> (msb - 1) & 1;
    return 2 * msb + half;
  }

  /// Extra bits for the VP8L distance prefix code for plane code [v].
  (int extraBits, int extraValue) _prefixExtra(int v) {
    final val = v - 1;
    if (val < 4) return (0, 0);
    final msb = _log2Floor(val);
    final half = val >> (msb - 1) & 1;
    final eb = msb - 1;
    final base = (2 + half) << eb;
    return (eb, val - base);
  }

  int _log2Floor(int v) {
    var log = 0;
    while (v > 1) {
      v >>= 1;
      log++;
    }
    return log;
  }

  // ---------------------------------------------------------------------------
  // Huffman coding
  // ---------------------------------------------------------------------------

  /// Build optimal Huffman code lengths for [alphabetSize] symbols given
  /// their [freq]uencies. Returns an array where entry i is the code length
  /// for symbol i (0 = unused). All lengths are ≤ [maxBits] (15 for VP8L).
  List<int> _buildHuffmanCodeLengths(
    List<int> freq,
    int alphabetSize, {
    int maxBits = 15,
  }) {
    final cl = List<int>.filled(alphabetSize, 0);

    final syms = <int>[];
    for (var k = 0; k < alphabetSize; k++) {
      if (freq[k] > 0) syms.add(k);
    }

    if (syms.isEmpty) {
      cl[0] = 1;
      return cl;
    }
    if (syms.length == 1) {
      cl[syms[0]] = 1;
      return cl;
    }

    final maxNodes = 2 * syms.length;
    final nodeFreq = List<int>.filled(maxNodes, 0);
    final nodeLeft = List<int>.filled(maxNodes, -1);
    final nodeRight = List<int>.filled(maxNodes, -1);

    for (var countMin = 1;; countMin *= 2) {
      for (var k = 0; k < syms.length; k++) {
        nodeFreq[k] = freq[syms[k]];
        if (nodeFreq[k] < countMin) nodeFreq[k] = countMin;
      }
      var nextNode = syms.length;

      final pq = List<int>.generate(syms.length, (k) => k)
        ..sort((x, y) => nodeFreq[x].compareTo(nodeFreq[y]));

      while (pq.length > 1) {
        final x = pq.removeAt(0);
        final y = pq.removeAt(0);
        final id = nextNode++;
        nodeFreq[id] = nodeFreq[x] + nodeFreq[y];
        nodeLeft[id] = x;
        nodeRight[id] = y;
        var pos = 0;
        while (pos < pq.length && nodeFreq[pq[pos]] <= nodeFreq[id]) {
          pos++;
        }
        pq.insert(pos, id);
      }

      // Assign code lengths via iterative DFS.
      final stackNodes = <int>[pq[0]];
      final stackDepths = <int>[0];
      var currentMaxBits = 0;

      while (stackNodes.isNotEmpty) {
        final nodeId = stackNodes.removeLast();
        final depth = stackDepths.removeLast();
        if (nodeLeft[nodeId] == -1) {
          cl[syms[nodeId]] = depth;
          if (depth > currentMaxBits) currentMaxBits = depth;
        } else {
          stackNodes
            ..add(nodeLeft[nodeId])
            ..add(nodeRight[nodeId]);
          stackDepths
            ..add(depth + 1)
            ..add(depth + 1);
        }
      }

      if (currentMaxBits <= maxBits) {
        break;
      }
    }

    return cl;
  }

  /// Write a Huffman code definition in VP8L format.
  void _writeHuffmanCode(
    _BitWriter bw,
    int alphabetSize,
    List<int> codeLengths,
  ) {
    final used = <int>[];
    for (var k = 0; k < alphabetSize; k++) {
      if (codeLengths[k] > 0) used.add(k);
    }

    if (used.length <= 2 && (used.isEmpty || used.last <= 255)) {
      // Simple code format.
      bw.writeBits(1, 1); // is_simple_code = 1
      if (used.isEmpty) {
        bw
          ..writeBits(0, 1) // 1 symbol
          ..writeBits(0, 1) // 1-bit symbol
          ..writeBits(0, 1); // symbol = 0
        return;
      }
      bw.writeBits(used.length - 1, 1); // num_symbols - 1
      final sym0 = used[0];
      if (sym0 <= 1) {
        bw
          ..writeBits(0, 1) // first_symbol_len_code = 0 (1-bit symbol)
          ..writeBits(sym0, 1); // symbol
      } else {
        bw
          ..writeBits(1, 1) // first_symbol_len_code = 1 (8-bit symbol)
          ..writeBits(sym0, 8);
      }
      if (used.length == 2) {
        bw.writeBits(used[1], 8);
      } else if (used.length == 1) {
        // 1-symbol simple codes take 0 bits in the bitstream.
        codeLengths[sym0] = 0;
      }
      return;
    }

    // Normal code format.
    final clSymbols = _buildRleSequence(codeLengths, alphabetSize);

    final clFreq = List<int>.filled(19, 0);
    for (final s in clSymbols) {
      clFreq[s.symbol]++;
    }

    final clCl = _buildHuffmanCodeLengths(clFreq, 19, maxBits: 7);
    final clCodes = _canonicalCodes(Int32List.fromList(clCl), 19);

    const kCodeLengthOrder = [
      17,
      18,
      0,
      1,
      2,
      3,
      4,
      5,
      16,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
    ];

    var numClCl = 4;
    for (var k = 18; k >= 4; k--) {
      if (clCl[kCodeLengthOrder[k]] != 0) {
        numClCl = k + 1;
        break;
      }
    }

    bw
      ..writeBits(0, 1) // is_simple_code = 0
      ..writeBits(numClCl - 4, 4); // num_code_lengths - 4

    for (var k = 0; k < numClCl; k++) {
      bw.writeBits(clCl[kCodeLengthOrder[k]], 3);
    }

    bw.writeBits(0, 1); // use_length = 0

    for (final s in clSymbols) {
      bw.writeBits(clCodes[s.symbol], clCl[s.symbol]);
      if (s.extraBits > 0) {
        bw.writeBits(s.extraValue, s.extraBits);
      }
    }
  }

  /// Build the RLE sequence for a code-lengths array using meta-symbols
  /// 0-15 (literal lengths), 16 (repeat prev 3-6×),
  /// 17 (repeat zero 3-10×), 18 (repeat zero 11-138×).
  List<_ClSymbol> _buildRleSequence(List<int> codeLengths, int alphabetSize) {
    final result = <_ClSymbol>[];
    var i = 0;
    while (i < alphabetSize) {
      final cl = codeLengths[i];
      if (cl == 0) {
        var count = 0;
        while (i + count < alphabetSize && codeLengths[i + count] == 0) {
          count++;
        }
        var rem = count;
        while (rem > 0) {
          if (rem >= 11) {
            final n = rem.clamp(11, 138);
            result.add(_ClSymbol(18, 7, n - 11));
            rem -= n;
          } else if (rem >= 3) {
            final n = rem.clamp(3, 10);
            result.add(_ClSymbol(17, 3, n - 3));
            rem -= n;
          } else {
            result.add(_ClSymbol(0, 0, 0));
            rem--;
          }
        }
        i += count;
      } else {
        result.add(_ClSymbol(cl, 0, 0));
        i++;
        while (i < alphabetSize && codeLengths[i] == cl) {
          var count = 0;
          while (i + count < alphabetSize &&
              codeLengths[i + count] == cl &&
              count < 6) {
            count++;
          }
          if (count >= 3) {
            result.add(_ClSymbol(16, 2, count - 3));
            i += count;
          } else {
            for (var k = 0; k < count; k++) {
              result.add(_ClSymbol(cl, 0, 0));
            }
            i += count;
          }
        }
      }
    }
    return result;
  }

  /// Compute canonical Huffman codes from code lengths (LSB-first bit order).
  List<int> _canonicalCodes(Int32List codeLengths, int numSymbols) {
    final codes = List<int>.filled(numSymbols, 0);
    var maxLen = 0;
    for (var k = 0; k < numSymbols; k++) {
      if (codeLengths[k] > maxLen) maxLen = codeLengths[k];
    }
    if (maxLen == 0) return codes;

    final blCount = List<int>.filled(maxLen + 1, 0);
    for (var k = 0; k < numSymbols; k++) {
      if (codeLengths[k] > 0) blCount[codeLengths[k]]++;
    }
    blCount[0] = 0;

    final nextCode = List<int>.filled(maxLen + 1, 0);
    var code = 0;
    for (var bits = 1; bits <= maxLen; bits++) {
      code = (code + blCount[bits - 1]) << 1;
      nextCode[bits] = code;
    }

    for (var k = 0; k < numSymbols; k++) {
      final len = codeLengths[k];
      if (len > 0) {
        codes[k] = _reverseBits(nextCode[len], len);
        nextCode[len]++;
      }
    }

    return codes;
  }

  int _reverseBits(int value, int numBits) {
    var result = 0;
    for (var k = 0; k < numBits; k++) {
      result = (result << 1) | (value & 1);
      value >>= 1;
    }
    return result;
  }

  Uint8List _tag(String s) {
    final bytes = Uint8List(s.length);
    for (var k = 0; k < s.length; k++) {
      bytes[k] = s.codeUnitAt(k);
    }
    return bytes;
  }

  // VP8L plane-to-code lookup table (128 entries, 8 rows × 16 cols).
  // Maps 2D pixel offsets to plane codes for DistanceToPlaneCode.
  static const _planeLut = <int>[
    //  yoffset=0 (xoffset 8..1, then 0..-7 which are unused=255)
    96, 73, 55, 39, 23, 13, 5, 1, 255, 255, 255, 255, 255, 255, 255, 255,
    //  yoffset=1
    101, 78, 58, 42, 26, 16, 8, 2, 0, 3, 9, 17, 27, 43, 59, 79,
    //  yoffset=2
    102, 86, 62, 46, 32, 20, 10, 6, 4, 7, 11, 21, 33, 47, 63, 87,
    //  yoffset=3
    105, 90, 70, 52, 37, 28, 18, 14, 12, 15, 19, 29, 38, 53, 71, 91,
    //  yoffset=4
    110, 99, 82, 66, 48, 35, 30, 24, 22, 25, 31, 36, 49, 67, 83, 100,
    //  yoffset=5
    115, 108, 94, 76, 64, 50, 44, 40, 34, 41, 45, 51, 65, 77, 95, 109,
    //  yoffset=6
    118, 113, 103, 92, 80, 68, 60, 56, 54, 57, 61, 69, 81, 93, 104, 114,
    //  yoffset=7
    119, 116, 111, 106, 97, 88, 84, 74, 72, 75, 85, 89, 98, 107, 112, 117
  ];
}

/// A code-length symbol with optional extra bits.
class _ClSymbol {
  final int symbol;
  final int extraBits;
  final int extraValue;
  _ClSymbol(this.symbol, this.extraBits, this.extraValue);
}

/// Bit writer that packs bits LSB-first into bytes.
class _BitWriter {
  final _bytes = <int>[];
  int _currentByte = 0;
  int _usedBits = 0;

  void writeBits(int value, int numBits) {
    while (numBits > 0) {
      final available = 8 - _usedBits;
      final bitsToWrite = numBits < available ? numBits : available;
      final mask = (1 << bitsToWrite) - 1;
      _currentByte |= (value & mask) << _usedBits;
      value >>= bitsToWrite;
      numBits -= bitsToWrite;
      _usedBits += bitsToWrite;
      if (_usedBits == 8) {
        _bytes.add(_currentByte);
        _currentByte = 0;
        _usedBits = 0;
      }
    }
  }

  void flush() {
    if (_usedBits > 0) {
      _bytes.add(_currentByte);
      _currentByte = 0;
      _usedBits = 0;
    }
  }

  Uint8List getBytes() => Uint8List.fromList(_bytes);
}
