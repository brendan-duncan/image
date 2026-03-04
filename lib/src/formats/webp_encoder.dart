import 'dart:typed_data';

import '../image/image.dart';
import '../util/output_buffer.dart';
import 'encoder.dart';

/// Encode an image to the WebP format (lossless).
///
/// Uses the VP8L lossless bitstream format wrapped in a RIFF/WebP container.
/// This encoder produces lossless images; alpha is preserved when present.
class WebPEncoder extends Encoder {
  @override
  Uint8List encode(Image image, {bool singleFrame = false}) {
    final width = image.width;
    final height = image.height;

    // Build the raw VP8L bitstream
    final vp8lData = _encodeVP8L(image, width, height);

    // Wrap in RIFF/WebP container
    final out = OutputBuffer();

    final paddedVp8lLength = vp8lData.length + (vp8lData.length.isOdd ? 1 : 0);
    final fileSize =
        4 /* 'WEBP' */ + 8 /* 'VP8L' + chunk size */ + paddedVp8lLength;
    _writeTag(out, 'RIFF');
    out.writeUint32(fileSize);

    // WEBP FourCC
    _writeTag(out, 'WEBP');

    // VP8L chunk
    _writeTag(out, 'VP8L');
    out.writeUint32(vp8lData.length);
    out.writeBytes(vp8lData);

    // RIFF chunks must be even-aligned; pad if needed
    if (vp8lData.length.isOdd) {
      out.writeByte(0);
    }

    return out.getBytes();
  }

  /// Encode image pixels into a VP8L bitstream.
  Uint8List _encodeVP8L(Image image, int width, int height) {
    final out = OutputBuffer();

    // Signature byte: 0x2f
    out.writeByte(0x2f);

    // VP8L image header (28 bits packed into 4 bytes little-endian):
    //   14 bits: width - 1
    //   14 bits: height - 1
    //    1 bit:  alpha_is_used
    //    3 bits: version (0)
    final hasAlpha = image.numChannels >= 4;
    final w = width - 1;
    final h = height - 1;
    final alphaUsed = hasAlpha ? 1 : 0;
    final header = w | (h << 14) | (alphaUsed << 28);
    out.writeByte(header & 0xff);
    out.writeByte((header >> 8) & 0xff);
    out.writeByte((header >> 16) & 0xff);
    out.writeByte((header >> 24) & 0xff);

    final bw = _BitWriter();

    // No transforms
    bw.writeBits(0, 1);

    // No color cache
    bw.writeBits(0, 1);

    // No meta Huffman codes (only at level 0)
    bw.writeBits(0, 1);

    // Build pixel data
    final numPixels = width * height;
    final green = Uint8List(numPixels);
    final red = Uint8List(numPixels);
    final blue = Uint8List(numPixels);
    final alpha = Uint8List(numPixels);

    var i = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final p = image.getPixel(x, y);
        green[i] = p.g.toInt().clamp(0, 255);
        red[i] = p.r.toInt().clamp(0, 255);
        blue[i] = p.b.toInt().clamp(0, 255);
        alpha[i] = hasAlpha ? p.a.toInt().clamp(0, 255) : 255;
        i++;
      }
    }

    // VP8L uses 5 Huffman code groups. With no color cache, alphabet sizes:
    //   Group 0 (green): 256 literals + 24 length codes = 280
    //   Group 1 (red):   256
    //   Group 2 (blue):  256
    //   Group 3 (alpha): 256
    //   Group 4 (dist):  40
    //
    // We encode each pixel as literal values (no LZ77 back-references).
    // All 256 byte values get code length 8 -> canonical fixed-length codes.

    // Groups 0-3: all 256 literal symbols with code length 8
    // For group 0 (green), alphabet_size=280 but only symbols 0..255 used
    _writeNormalHuffmanCode(bw, 280, 256); // green+meta
    _writeNormalHuffmanCode(bw, 256, 256); // red
    _writeNormalHuffmanCode(bw, 256, 256); // blue
    _writeNormalHuffmanCode(bw, 256, 256); // alpha

    // Group 4 (distance): alphabet_size=40, no symbols used.
    // Simple code with 1 symbol, symbol=0.
    // simple_code=1 (1 bit), num_symbols-1=0 (1 bit),
    // first_symbol_len_code=0 (1 bit) -> 1-bit symbol -> read 1 bit = 0
    bw.writeBits(1, 1); // is_simple_code = 1
    bw.writeBits(0, 1); // num_symbols - 1 = 0 (1 symbol)
    bw.writeBits(0, 1); // first_symbol_len_code = 0 -> 1-bit symbol
    bw.writeBits(0, 1); // symbol value = 0

    // Write pixel data
    // With canonical Huffman code for 256 symbols all of length 8,
    // the code for symbol s is the 8-bit reversal of s's position in
    // sorted order. Since all symbols have the same length, the
    // canonical code for symbol i is just reverse8(i).
    for (var j = 0; j < numPixels; j++) {
      bw.writeBits(_reverse8[green[j]], 8);
      bw.writeBits(_reverse8[red[j]], 8);
      bw.writeBits(_reverse8[blue[j]], 8);
      bw.writeBits(_reverse8[alpha[j]], 8);
    }

    bw.flush();
    out.writeBytes(bw.getBytes());
    return out.getBytes();
  }

  /// Write a normal (non-simple) Huffman code definition for [numUsed]
  /// symbols (0..numUsed-1) each with code-length 8, out of a total
  /// alphabet of [alphabetSize].
  ///
  /// The decoder reads:
  ///   1 bit: is_simple_code (0 = non-simple)
  ///   4 bits: num_code_lengths - 4
  ///   3 bits each: code-length-of-code-length in kCodeLengthOrder
  ///   then: actual code lengths read via the code-length Huffman table
  void _writeNormalHuffmanCode(_BitWriter bw, int alphabetSize, int numUsed) {
    // We want code-lengths: [8,8,...(numUsed times),0,0,...(rest)]
    //
    // To encode these code-lengths we need a code-length Huffman code.
    // Code-length alphabet (19 symbols):
    //   0-15: literal code lengths
    //   16: repeat previous 3-6 times (2 extra bits)
    //   17: repeat zero 3-10 times (3 extra bits)
    //   18: repeat zero 11-138 times (7 extra bits)
    //
    // Our strategy:
    //   - Use symbol 16 to repeat code-length 8
    //   - Use symbols 17/18 to emit zeros
    //   - Use symbol 8 for the first occurrence of code-length 8

    // Build the sequence of code-length symbols we'll emit.
    final clSymbols = <_ClSymbol>[];

    // First symbol of 8
    clSymbols.add(_ClSymbol(8, 0, 0));

    // Remaining (numUsed-1) eights using repeat-previous (symbol 16)
    var eights = numUsed - 1;
    while (eights > 0) {
      final repeat = eights.clamp(3, 6);
      if (eights < 3) {
        // Write remaining ones as literal 8s
        for (var k = 0; k < eights; k++) {
          clSymbols.add(_ClSymbol(8, 0, 0));
        }
        eights = 0;
      } else {
        clSymbols.add(_ClSymbol(16, 2, repeat - 3)); // repeat prev 3-6 times
        eights -= repeat;
      }
    }

    // Trailing zeros
    var zeros = alphabetSize - numUsed;
    while (zeros > 0) {
      if (zeros >= 11) {
        final repeat = zeros.clamp(11, 138);
        clSymbols.add(_ClSymbol(18, 7, repeat - 11));
        zeros -= repeat;
      } else if (zeros >= 3) {
        final repeat = zeros.clamp(3, 10);
        clSymbols.add(_ClSymbol(17, 3, repeat - 3));
        zeros -= repeat;
      } else {
        clSymbols.add(_ClSymbol(0, 0, 0));
        zeros--;
      }
    }

    // Determine which code-length symbols are used
    final clUsed = <int>{};
    for (final s in clSymbols) {
      clUsed.add(s.symbol);
    }

    // Assign code-lengths to the code-length symbols (for the code-length
    // Huffman code). We only need codes for used symbols.
    final clCodeLengths = Int32List(19);
    final usedList = clUsed.toList()..sort();

    if (usedList.length == 1) {
      clCodeLengths[usedList[0]] = 1;
    } else {
      // Build a minimal prefix code.
      // For 2 symbols: each gets length 1
      // For 3 symbols: one gets length 1, two get length 2
      // For 4 symbols: each gets length 2
      if (usedList.length == 2) {
        clCodeLengths[usedList[0]] = 1;
        clCodeLengths[usedList[1]] = 1;
      } else if (usedList.length == 3) {
        clCodeLengths[usedList[0]] = 1;
        clCodeLengths[usedList[1]] = 2;
        clCodeLengths[usedList[2]] = 2;
      } else if (usedList.length == 4) {
        clCodeLengths[usedList[0]] = 2;
        clCodeLengths[usedList[1]] = 2;
        clCodeLengths[usedList[2]] = 2;
        clCodeLengths[usedList[3]] = 2;
      } else {
        // Should not happen for our use case
        throw StateError('Too many code-length symbols used');
      }
    }

    // Build canonical codes
    final clCodes = _canonicalCodes(clCodeLengths, 19);

    // Determine how many entries to write in kCodeLengthOrder
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
      15
    ];

    var numClCl = 4; // minimum
    for (var k = 18; k >= 4; k--) {
      if (clCodeLengths[kCodeLengthOrder[k]] != 0) {
        numClCl = k + 1;
        break;
      }
    }

    // Write non-simple code header
    bw.writeBits(0, 1); // is_simple_code = 0

    // num_code_lengths - 4 (4 bits)
    bw.writeBits(numClCl - 4, 4);

    // Code-length-of-code-lengths (3 bits each, in kCodeLengthOrder)
    for (var k = 0; k < numClCl; k++) {
      bw.writeBits(clCodeLengths[kCodeLengthOrder[k]], 3);
    }

    // Write max_symbol flag.
    // The decoder reads 1 bit: if 1, it reads a max_symbol value.
    // We write 0 to indicate max_symbol = alphabetSize (default).
    bw.writeBits(0, 1);

    // Write the actual code-length sequence
    for (final s in clSymbols) {
      bw.writeBits(clCodes[s.symbol], clCodeLengths[s.symbol]);
      if (s.extraBits > 0) {
        bw.writeBits(s.extraValue, s.extraBits);
      }
    }
  }

  /// Compute canonical Huffman codes from code lengths (LSB-first).
  List<int> _canonicalCodes(Int32List codeLengths, int numSymbols) {
    final codes = List<int>.filled(numSymbols, 0);
    var maxLen = 0;
    for (var i = 0; i < numSymbols; i++) {
      if (codeLengths[i] > maxLen) maxLen = codeLengths[i];
    }
    if (maxLen == 0) return codes;

    final blCount = List<int>.filled(maxLen + 1, 0);
    for (var i = 0; i < numSymbols; i++) {
      if (codeLengths[i] > 0) blCount[codeLengths[i]]++;
    }

    // Per canonical Huffman code algorithm, blCount[0] must be 0
    blCount[0] = 0;

    final nextCode = List<int>.filled(maxLen + 1, 0);
    var code = 0;
    for (var bits = 1; bits <= maxLen; bits++) {
      code = (code + blCount[bits - 1]) << 1;
      nextCode[bits] = code;
    }

    for (var i = 0; i < numSymbols; i++) {
      final len = codeLengths[i];
      if (len > 0) {
        codes[i] = _reverseBits(nextCode[len], len);
        nextCode[len]++;
      }
    }

    return codes;
  }

  int _reverseBits(int value, int numBits) {
    var result = 0;
    for (var i = 0; i < numBits; i++) {
      result = (result << 1) | (value & 1);
      value >>= 1;
    }
    return result;
  }

  void _writeTag(OutputBuffer out, String tag) {
    for (var i = 0; i < tag.length; i++) {
      out.writeByte(tag.codeUnitAt(i));
    }
  }

  /// Precomputed table of 8-bit reversed values.
  static final _reverse8 = _buildReverse8();

  static List<int> _buildReverse8() {
    final table = List<int>.filled(256, 0);
    for (var i = 0; i < 256; i++) {
      var v = i;
      var r = 0;
      for (var b = 0; b < 8; b++) {
        r = (r << 1) | (v & 1);
        v >>= 1;
      }
      table[i] = r;
    }
    return table;
  }
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
