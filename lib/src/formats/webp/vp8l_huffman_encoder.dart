/// Entropy coding for a VP8L stream: the LZ77 length and distance symbols, and
/// the canonical Huffman codes the decoder rebuilds from the stream header.
library;

import 'dart:typed_data';

import '../../util/_internal.dart';
import 'vp8l_bit_writer.dart';

// ---------------------------------------------------------------------------
// VP8L length and distance encoding helpers
// ---------------------------------------------------------------------------

/// VP8L green-channel symbol for a back-reference of [length].
@internal
int lengthSymbol(int length) {
  assert(length >= 1 && length <= 4096);
  if (length <= 4) return 255 + length; // symbols 256..259
  final msb = _log2Floor(length - 1);
  final half = (length - 1) >> (msb - 1) & 1;
  return 256 + 2 * msb + half; // symbols 260..279
}

/// Extra bits for VP8L length prefix code for back-reference [length].
@internal
(int extraBits, int extraValue) lengthExtra(int length) {
  if (length <= 4) return (0, 0);
  final msb = _log2Floor(length - 1);
  final half = (length - 1) >> (msb - 1) & 1;
  final eb = msb - 1;
  final base = (2 + half) << eb;
  return (eb, (length - 1) - base);
}

/// Convert a pixel distance to the VP8L plane code (intermediate value).
@internal
int distToPlaneCode(int width, int dist) {
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
@internal
int prefixCode(int v) {
  final val = v - 1;
  if (val < 4) return val;
  final msb = _log2Floor(val);
  final half = val >> (msb - 1) & 1;
  return 2 * msb + half;
}

/// Extra bits for the VP8L distance prefix code for plane code [v].
@internal
(int extraBits, int extraValue) prefixExtra(int v) {
  final val = v - 1;
  if (val < 4) return (0, 0);
  final msb = _log2Floor(val);
  final half = val >> (msb - 1) & 1;
  final eb = msb - 1;
  final base = (2 + half) << eb;
  return (eb, val - base);
}

@pragma('vm:unsafe:no-bounds-checks')
@pragma('vm:unsafe:no-interrupts')
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
///
/// libwebp first nudges the histogram so that the resulting lengths fall into
/// runs, which its run-length-coded length table then stores more cheaply
/// (`OptimizeHuffmanForRle`). Ported and measured at 17KB *worse* over a 587
/// image corpus: it helps the smallest images, where the table is a real share
/// of the file, and costs more than it saves everywhere else.
@internal
List<int> buildHuffmanCodeLengths(
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
///
/// A code with one used symbol has its length in [codeLengths] set to zero, in
/// either format: a decoder spends no bits on such a tree.
@internal
@pragma('vm:unsafe:no-bounds-checks')
void writeHuffmanCode(
  VP8LBitWriter bw,
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
    } else {
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

  final clCl = buildHuffmanCodeLengths(clFreq, 19, maxBits: 7);
  final clCodes = canonicalCodes(Int32List.fromList(clCl), 19);

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

  if (used.length == 1) {
    codeLengths[used[0]] = 0;
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
@internal
List<int> canonicalCodes(Int32List codeLengths, int numSymbols) {
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

// VP8L plane-to-code lookup table (128 entries, 8 rows × 16 cols).
// Maps 2D pixel offsets to plane codes for DistanceToPlaneCode.
const _planeLut = <int>[
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

/// A code-length symbol with optional extra bits.
class _ClSymbol {
  final int symbol;
  final int extraBits;
  final int extraValue;
  _ClSymbol(this.symbol, this.extraBits, this.extraValue);
}
