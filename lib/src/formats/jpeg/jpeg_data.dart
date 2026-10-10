import 'dart:math';
import 'dart:typed_data';

import '../../exif/exif_data.dart';
import '../../image/icc_profile.dart';
import '../../image/image.dart';
import '../../util/_internal.dart';
import '../../util/image_exception.dart';
import '../../util/input_buffer.dart';
import '_component_data.dart';
import '_jpeg_huffman.dart';
import '_jpeg_image.dart';
import '_jpeg_quantize_html.dart' if (dart.library.io) '_jpeg_quantize_io.dart';
import 'jpeg_adobe.dart';
import 'jpeg_component.dart';
import 'jpeg_frame.dart';
import 'jpeg_info.dart';
import 'jpeg_jfif.dart';
import 'jpeg_marker.dart';
import 'jpeg_scan.dart';

@internal
class JpegData {
  static final dctZigZag = Uint8List.fromList([
    0, 1, 8, 16, 9, 2, 3, 10,
    17, 24, 32, 25, 18, 11, 4, 5,
    12, 19, 26, 33, 40, 48, 41, 34,
    27, 20, 13, 6, 7, 14, 21, 28,
    35, 42, 49, 56, 57, 50, 43, 36,
    29, 22, 15, 23, 30, 37, 44, 51,
    58, 59, 52, 45, 38, 31, 39, 46,
    53, 60, 61, 54, 47, 55, 62, 63,
    63, 63, 63, 63, 63, 63, 63, 63, // extra entries for safety in decoder
    63, 63, 63, 63, 63, 63, 63, 63
  ]);

  static const dctSize = 8; // The basic DCT block is 8x8 samples
  static const dctSize2 = 64; // DCTSIZE squared; # of elements in a block
  static const numQuantizationTables = 4; // Quantization tables are 0..3
  static const numHuffmanTables = 4; // Huffman tables are numbered 0..3
  static const numArithTables = 16; // Arith-coding tables are numbered 0..15
  static const maxCompsInScan = 4; // JPEG limit on # of components in one scan
  static const maxSamplingFactor = 4; // JPEG limit on sampling factors

  /// The maximum number of pixels (width * height) [read] will decode. Frames
  /// declaring more throw an [ImageException] before any pixel data is
  /// allocated. A value <= 0 disables the limit.
  int maxPixels = 0;

  /// The factor the image is scaled down by while decoding: 1, 2, 4 or 8.
  /// Scaling reduces the work and memory of the inverse DCT output and the
  /// decoded image, making it a fast way to decode a thumbnail.
  int scale = 1;

  late InputBuffer input;
  late JpegJfif jfif;
  JpegAdobe? adobe;
  JpegFrame? frame;
  int? resetInterval;
  String? comment;
  IccProfile? iccProfile;
  final exif = ExifData();
  final quantizationTables =
      List<Int16List?>.filled(numQuantizationTables, null);
  final frames = <JpegFrame?>[];
  final huffmanTablesAC = List<List<HuffmanNode?>?>.empty(growable: true);
  final huffmanTablesDC = List<List<HuffmanNode?>?>.empty(growable: true);
  final components = <ComponentData>[];

  bool validate(List<int> bytes) {
    input = InputBuffer(bytes, bigEndian: true);

    // Some other formats have embedded jpeg, or jpeg-like data.
    // Only validate if the image starts with the StartOfImage tag.
    final soiCheck = input.peekBytes(2);
    if (soiCheck[0] != 0xff || soiCheck[1] != 0xd8) {
      return false;
    }

    var marker = _nextMarker();
    if (marker != JpegMarker.soi) {
      return false;
    }

    var hasSOF = false;
    var hasSOS = false;

    marker = _nextMarker();
    while (marker != JpegMarker.eoi && !input.isEOS) {
      // EOI (End of image)
      final sectionByteSize = input.readUint16();
      if (sectionByteSize < 2) {
        // jpeg section consists of more than 2 bytes at least
        // return success only when SOF and SOS have already found (as a jpeg
        // without EOF.)
        break;
      }
      input.offset += sectionByteSize - 2;

      switch (marker) {
        case JpegMarker.sof0: // SOF0 (Start of Frame, Baseline DCT)
        case JpegMarker.sof1: // SOF1 (Start of Frame, Extended DCT)
        case JpegMarker.sof2: // SOF2 (Start of Frame, Progressive DCT)
          hasSOF = true;
          break;
        case JpegMarker.sos: // SOS (Start of Scan)
          // The entropy-coded data follows; scanning it to EOI would only
          // cost a pass over the whole file.
          if (hasSOF) {
            return true;
          }
          hasSOS = true;
          break;
        default:
      }

      marker = _nextMarker();
    }

    return hasSOF && hasSOS;
  }

  JpegInfo? readInfo(List<int> bytes) {
    input = InputBuffer(bytes, bigEndian: true);

    var marker = _nextMarker();
    if (marker != JpegMarker.soi) {
      return null;
    }

    final info = JpegInfo();

    var hasSOF = false;
    var hasSOS = false;

    marker = _nextMarker();
    while (marker != JpegMarker.eoi && !input.isEOS) {
      // EOI (End of image)
      switch (marker) {
        case JpegMarker.sof0: // SOF0 (Start of Frame, Baseline DCT)
        case JpegMarker.sof1: // SOF1 (Start of Frame, Extended DCT)
        case JpegMarker.sof2: // SOF2 (Start of Frame, Progressive DCT)
          hasSOF = true;
          _readFrame(marker, _readBlock(), prepare: false);
          break;
        case JpegMarker.sos: // SOS (Start of Scan)
          hasSOS = true;
          _skipBlock();
          break;
        default:
          _skipBlock();
          break;
      }

      marker = _nextMarker();
    }

    if (frame != null) {
      info
        ..width = frame!.samplesPerLine!
        ..height = frame!.scanLines!
        ..numComponents = frame!.components.length;
    }
    frame = null;
    frames.clear();

    return (hasSOF && hasSOS) ? info : null;
  }

  void read(List<int> bytes) {
    input = InputBuffer(bytes, bigEndian: true);
    _read();

    if (frames.length != 1) {
      throw ImageException('Only single frame JPEGs supported');
    }

    final f = frame!;
    if (_writer != null) {
      // The image was decoded a band at a time.
      return;
    }
    if (!_prepared) {
      // No scans: the coefficients are all zero.
      _prepared = true;
      f.prepare(dcOnly: scale == 8);
    }
    for (var i = 0; i < f.componentsOrder.length; ++i) {
      final component = f.components[f.componentsOrder[i]]!;
      components.add(ComponentData(
          component.hSamples,
          f.maxHSamples,
          component.vSamples,
          f.maxVSamples,
          _buildComponentData(f, component)));
    }
  }

  int? get width => frame!.samplesPerLine;

  int? get height => frame!.scanLines;

  /// The width of the decoded image, [width] divided by [scale].
  int get scaledWidth => (width! + scale - 1) ~/ scale;

  /// The height of the decoded image, [height] divided by [scale].
  int get scaledHeight => (height! + scale - 1) ~/ scale;

  Image getImage() => getImageFromJpeg(this);

  void _read() {
    var marker = _nextMarker();
    if (marker != JpegMarker.soi) {
      // SOI (Start of Image)
      throw ImageException('Start Of Image marker not found.');
    }

    marker = _nextMarker();
    while (marker != JpegMarker.eoi && !input.isEOS) {
      // RSTn and TEM markers are standalone and have no length or payload.
      if ((marker >= JpegMarker.rst0 && marker <= JpegMarker.rst7) ||
          marker == JpegMarker.tem) {
        marker = _nextMarker();
        continue;
      }

      final block = _readBlock();
      switch (marker) {
        case JpegMarker.app0:
        case JpegMarker.app1:
        case JpegMarker.app2:
        case JpegMarker.app3:
        case JpegMarker.app4:
        case JpegMarker.app5:
        case JpegMarker.app6:
        case JpegMarker.app7:
        case JpegMarker.app8:
        case JpegMarker.app9:
        case JpegMarker.app10:
        case JpegMarker.app11:
        case JpegMarker.app12:
        case JpegMarker.app13:
        case JpegMarker.app14:
        case JpegMarker.app15:
        case JpegMarker.com:
          _readAppData(marker, block);
          break;

        case JpegMarker.dqt: // DQT (Define Quantization Tables)
          _readDQT(block);
          break;

        case JpegMarker.sof0: // SOF0 (Start of Frame, Baseline DCT)
        case JpegMarker.sof1: // SOF1 (Start of Frame, Extended DCT)
        case JpegMarker.sof2: // SOF2 (Start of Frame, Progressive DCT)
          _readFrame(marker, block);
          break;

        case JpegMarker.sof3:
        case JpegMarker.sof5:
        case JpegMarker.sof6:
        case JpegMarker.sof7:
        case JpegMarker.jpg:
        case JpegMarker.sof9:
        case JpegMarker.sof10:
        case JpegMarker.sof11:
        case JpegMarker.sof13:
        case JpegMarker.sof14:
        case JpegMarker.sof15:
          throw ImageException(
              'Unhandled frame type ${marker.toRadixString(16)}');

        case JpegMarker.dht: // DHT (Define Huffman Tables)
          _readDHT(block);
          break;

        case JpegMarker.dri: // DRI (Define Restart Interval)
          _readDRI(block);
          break;

        case JpegMarker.sos: // SOS (Start of Scan)
          _readSOS(block);
          break;

        case 0xff: // Fill bytes
          if (input[0] != 0xff) {
            input.offset--;
          }
          break;

        default:
          if (input[-3] == 0xff && input[-2] >= 0xc0 && input[-2] <= 0xfe) {
            // could be incorrect encoding -- last 0xFF byte of the previous
            // block was eaten by the encoder
            input.offset -= 3;
            break;
          }

          if (marker != 0) {
            throw ImageException(
                'Unknown JPEG marker ${marker.toRadixString(16)}');
          }
          break;
      }

      marker = _nextMarker();
    }
  }

  void _skipBlock() {
    final length = input.readUint16();
    if (length < 2) {
      throw ImageException('Invalid Block');
    }
    input.offset += length - 2;
  }

  InputBuffer _readBlock() {
    final length = input.readUint16();
    if (length < 2) {
      throw ImageException('Invalid Block');
    }
    return input.readBytes(length - 2);
  }

  int _nextMarker() {
    var c = 0;
    if (input.isEOS) {
      return c;
    }

    do {
      do {
        c = input.readByte();
      } while (c != 0xff && !input.isEOS);

      if (input.isEOS) {
        return c;
      }

      do {
        c = input.readByte();
      } while (c == 0xff && !input.isEOS);
    } while (c == 0 && !input.isEOS);

    return c;
  }

  void _readIccProfile(InputBuffer block) {
    const iccProfileSignature = [
      0x49,
      0x43,
      0x43,
      0x5F,
      0x50,
      0x52,
      0x4F,
      0x46,
      0x49,
      0x4C,
      0x45,
      0x00
    ]; // "ICC_PROFILE\0"
    for (var i = 0; i < iccProfileSignature.length; i++) {
      final b = block.readByte();
      if (b != iccProfileSignature[i]) {
        return;
      }
    }

    final data = block.toUint8List();
    iccProfile =
        new IccProfile("ICC_PROFILE", IccProfileCompression.none, data);
  }

  void _readExifData(InputBuffer block) {
    // Exif Header
    const exifSignature = 0x45786966; // Exif\0\0
    final signature = block.readUint32();
    if (signature != exifSignature) {
      return;
    }
    if (block.readUint16() != 0) {
      return;
    }

    exif.read(block);
  }

  void _readAppData(int marker, InputBuffer block) {
    final appData = block;

    // EXIF orientation and the Adobe color transform are used by bands that
    // have already been converted.
    if (_writer != null &&
        (marker == JpegMarker.app1 || marker == JpegMarker.app14)) {
      _restartNeeded = true;
    }

    if (marker == JpegMarker.app0) {
      // 'JFIF\0'
      if (appData[0] == 0x4A &&
          appData[1] == 0x46 &&
          appData[2] == 0x49 &&
          appData[3] == 0x46 &&
          appData[4] == 0) {
        jfif = JpegJfif()
          ..majorVersion = appData[5]
          ..minorVersion = appData[6]
          ..densityUnits = appData[7]
          ..xDensity = (appData[8] << 8) | appData[9]
          ..yDensity = (appData[10] << 8) | appData[11]
          ..thumbWidth = appData[12]
          ..thumbHeight = appData[13];
        final thumbSize = 3 * jfif.thumbWidth * jfif.thumbHeight;
        jfif.thumbData = appData.subset(14 + thumbSize, offset: 14);
      }
    } else if (marker == JpegMarker.app1) {
      // 'EXIF\0'
      _readExifData(appData);
    } else if (marker == JpegMarker.app2) {
      _readIccProfile(appData);
    } else if (marker == JpegMarker.app14) {
      // 'Adobe\0'
      if (appData[0] == 0x41 &&
          appData[1] == 0x64 &&
          appData[2] == 0x6F &&
          appData[3] == 0x62 &&
          appData[4] == 0x65 &&
          appData[5] == 0) {
        final a = JpegAdobe()
          ..version = appData[6]
          ..flags0 = (appData[7] << 8) | appData[8]
          ..flags1 = (appData[9] << 8) | appData[10]
          ..transformCode = appData[11];
        adobe = a;
      }
    } else if (marker == JpegMarker.com) {
      // Comment
      try {
        comment = appData.readStringUtf8();
      } catch (_) {
        // readString without 0x00 terminator causes exception. Technically
        // bad data, but no reason to abort the rest of the image decoding.
      }
    }
  }

  void _readDQT(InputBuffer block) {
    while (!block.isEOS) {
      var n = block.readByte();
      final prec = n >> 4;
      n &= 0x0F;

      if (n >= numQuantizationTables) {
        throw ImageException('Invalid number of quantization tables');
      }

      if (quantizationTables[n] == null) {
        quantizationTables[n] = Int16List(64);
      }

      final tableData = quantizationTables[n];
      for (var i = 0; i < dctSize2; i++) {
        int tmp;
        if (prec != 0) {
          tmp = block.readUint16();
        } else {
          tmp = block.readByte();
        }

        tableData![dctZigZag[i]] = tmp;
      }
    }

    if (!block.isEOS) {
      throw ImageException('Bad length for DQT block');
    }
  }

  void _readFrame(int marker, InputBuffer block, {bool prepare = true}) {
    if (frame != null) {
      throw ImageException('Duplicate JPG frame data found.');
    }

    final f = JpegFrame()
      ..extended = (marker == JpegMarker.sof1)
      ..progressive = (marker == JpegMarker.sof2)
      ..precision = block.readByte()
      ..scanLines = block.readUint16()
      ..samplesPerLine = block.readUint16();

    final numComponents = block.readByte();

    for (var i = 0; i < numComponents; i++) {
      final componentId = block.readByte();
      final x = block.readByte();
      final h = (x >> 4) & 15;
      final v = x & 15;
      final qId = block.readByte();
      f.componentsOrder.add(componentId);
      f.components[componentId] = JpegComponent(h, v, quantizationTables, qId);
    }

    // The coefficient blocks are allocated by the first scan, once it's known
    // whether the image can be decoded a band at a time, but the declared
    // dimensions are validated now.
    if (prepare) {
      _validateFrame(f);
    }
    frame = f;
    frames.add(f);
  }

  void _validateFrame(JpegFrame f) {
    final width = f.samplesPerLine!;
    final height = f.scanLines!;
    if (width == 0 || height == 0) {
      throw ImageException('Invalid JPEG dimensions ${width}x$height');
    }
    if (maxPixels > 0 && width * height > maxPixels) {
      throw ImageException('JPEG dimensions ${width}x$height exceed the '
          'maximum of $maxPixels pixels');
    }
    if (f.components.isEmpty || f.components.length > maxCompsInScan) {
      throw ImageException(
          'Unsupported number of JPEG components: ${f.components.length}');
    }
    for (final c in f.components.values) {
      if (c.hSamples < 1 ||
          c.hSamples > maxSamplingFactor ||
          c.vSamples < 1 ||
          c.vSamples > maxSamplingFactor) {
        throw ImageException('Invalid JPEG sampling factor');
      }
    }
  }

  void _readDHT(InputBuffer block) {
    while (!block.isEOS) {
      var index = block.readByte();

      final bits = Uint8List(16);
      var count = 0;
      for (var j = 0; j < 16; j++) {
        bits[j] = block.readByte();
        count += bits[j];
      }

      final huffmanValues = block.readBytes(count).toUint8List();

      List<List<HuffmanNode?>?> ht;
      if (index & 0x10 != 0) {
        // AC table definition
        index -= 0x10;
        ht = huffmanTablesAC;
      } else {
        // DC table definition
        ht = huffmanTablesDC;
      }

      if (ht.length <= index) {
        ht.length = index + 1;
      }

      ht[index] = _buildHuffmanTable(bits, huffmanValues);
    }
  }

  void _readDRI(InputBuffer block) {
    resetInterval = block.readUint16();
  }

  void _readSOS(InputBuffer block) {
    final n = block.readByte();
    if (n < 1 || n > maxCompsInScan) {
      throw ImageException('Invalid SOS block');
    }

    final f = frame!;
    final components = <JpegComponent>[];
    for (var i = 0; i < n; i++) {
      final id = block.readByte();
      final c = block.readByte();

      if (!f.components.containsKey(id)) {
        throw ImageException('Invalid Component in SOS block');
      }

      final component = f.components[id]!;

      final dcTblNo = (c >> 4) & 15;
      final acTblNo = c & 15;

      if (dcTblNo < huffmanTablesDC.length) {
        final table = huffmanTablesDC[dcTblNo]!;
        component
          ..huffmanTableDC = table
          ..huffmanLookupDC = huffmanLookup(table);
      }
      if (acTblNo < huffmanTablesAC.length) {
        final table = huffmanTablesAC[acTblNo]!;
        component
          ..huffmanTableAC = table
          ..huffmanLookupAC = huffmanLookup(table);
      }

      components.add(component);
    }

    final spectralStart = block.readByte();
    final spectralEnd = block.readByte();
    final successiveApproximation = block.readByte();

    final ah = (successiveApproximation >> 4) & 15;
    final al = successiveApproximation & 15;

    // At 1/8 scale, the AC coefficients aren't used, so progressive AC scans
    // are skipped: the scan data is passed over when looking for the next
    // marker.
    if (f.progressive! && scale == 8 && spectralStart > 0) {
      return;
    }

    if (_writer != null) {
      // Another scan would change bands that have already been converted.
      throw const _RestartDecode();
    }

    var streaming = false;
    if (!_prepared) {
      _prepared = true;
      // A baseline scan of all of the components holds the whole image, so it
      // can be decoded a band at a time. (A scan of one component is one
      // block per MCU, so that's only done for 1x1 sampling.)
      final first = f.components[f.componentsOrder[0]]!;
      streaming = _allowStreaming &&
          !f.progressive! &&
          components.length == f.components.length &&
          (components.length > 1 ||
              (first.hSamples == 1 && first.vSamples == 1));
      f.prepare(dcOnly: scale == 8, band: streaming);
      if (streaming) {
        _startBands(f);
      }
    }

    final scan = JpegScan(input, f, components, resetInterval, spectralStart,
        spectralEnd, ah, al);
    if (streaming) {
      scan.onRow = _decodeBand;
    }
    scan.decode();
  }

  List<HuffmanNode?> _buildHuffmanTable(
      Uint8List codeLengths, Uint8List values) {
    var k = 0;
    final code = <_JpegHuffman>[];
    var length = 16;

    while (length > 0 && (codeLengths[length - 1] == 0)) {
      length--;
    }

    code.add(_JpegHuffman());

    var p = code[0];
    _JpegHuffman q;

    for (var i = 0; i < length; i++) {
      for (var j = 0; j < codeLengths[i]; j++) {
        p = code.removeLast();
        p.children[p.index] = HuffmanValue(values[k]);
        while (p.index > 0) {
          p = code.removeLast();
        }
        p.index++;
        code.add(p);
        while (code.length <= i) {
          q = _JpegHuffman();
          code.add(q);
          p.children[p.index] = HuffmanParent(q.children);
          p = q;
        }
        k++;
      }

      if ((i + 1) < length) {
        q = _JpegHuffman();
        code.add(q);
        p.children[p.index] = HuffmanParent(q.children);
        p = q;
      }
    }

    return code[0].children;
  }

  List<Uint8List?> _buildComponentData(
      JpegFrame frame, JpegComponent component) {
    final blocksPerLine = component.blocksPerLine;
    final blocksPerColumn = component.blocksPerColumn;
    // The size of a decoded block.
    final bs = 8 ~/ scale;
    final samplesPerLine = blocksPerLine * bs;
    final R = Int32List(64);
    final r = Uint8List(64);
    final lines = List<Uint8List?>.filled(blocksPerColumn * bs, null);
    for (var blockRow = 0; blockRow < blocksPerColumn; blockRow++) {
      for (var i = 0; i < bs; i++) {
        lines[blockRow * bs + i] = Uint8List(samplesPerLine);
      }
      _buildBlockRow(component, blockRow, lines, blockRow * bs, r, R);
    }

    // The coefficients are no longer needed once the lines are built.
    component.coefficients = Int16List(0);

    return lines;
  }

  // Decodes the blocks of row [coeffRow] of [component.coefficients] into the
  // lines of [lines] starting at [scanLine].
  void _buildBlockRow(JpegComponent component, int coeffRow,
      List<Uint8List?> lines, int scanLine, Uint8List r, Int32List R) {
    final bs = 8 ~/ scale;
    final coefficients = component.coefficients;
    final blocksPerLineForMcu = component.blocksPerLineForMcu;
    final quantizationTable = component.quantizationTable!;
    for (var blockCol = 0; blockCol < component.blocksPerLine; blockCol++) {
      final block = coeffRow * blocksPerLineForMcu + blockCol;
      final offset = block << 6;
      if (bs == 1) {
        // A block scaled to one pixel is its average, given by the DC
        // coefficient alone.
        final dc = coefficients[component.dcOnly ? block : offset];
        lines[scanLine]![blockCol] = _dcValue(dc * quantizationTable[0]);
        continue;
      }

      quantizeAndInverse(quantizationTable, coefficients, offset, r, R);

      final sample = blockCol * bs;
      if (bs == 8) {
        for (var j = 0; j < 8; j++) {
          lines[scanLine + j]?.setRange(sample, sample + 8, r, j << 3);
        }
      } else {
        _scaleBlock(r, bs, lines, scanLine, sample);
      }
    }
  }

  /// Decodes [bytes] to an [Image]. Baseline images are decoded a band of
  /// rows at a time when they can be, which needs much less memory than
  /// [read] followed by [getImage], as the coefficients and lines of the
  /// whole image aren't kept.
  Image decodeImage(List<int> bytes) {
    _allowStreaming = true;
    try {
      read(bytes);
    } on _RestartDecode {
      return _decodeFully(bytes);
    }
    final writer = _writer;
    if (writer == null) {
      return getImage();
    }
    if (_restartNeeded) {
      return _decodeFully(bytes);
    }
    return writer.image..iccProfile = iccProfile;
  }

  // Decodes [bytes] with a new JpegData that doesn't decode in bands.
  Image _decodeFully(List<int> bytes) {
    final jpeg = JpegData()
      ..maxPixels = maxPixels
      ..scale = scale
      ..read(bytes);
    return jpeg.getImage();
  }

  // Sets up decoding the image a band (a row of MCUs) at a time.
  void _startBands(JpegFrame f) {
    final bs = 8 ~/ scale;
    _bandLines.clear();
    for (final id in f.componentsOrder) {
      final component = f.components[id]!;
      components.add(ComponentData(
          component.hSamples,
          f.maxHSamples,
          component.vSamples,
          f.maxVSamples,
          List<Uint8List?>.filled(component.blocksPerColumn * bs, null)));
      _bandLines.add(List<Uint8List>.generate(component.vSamples * bs,
          (_) => Uint8List(component.blocksPerLine * bs)));
    }
    _writer = JpegImageWriter(this);
  }

  // Decodes band [row] of the image, and converts its rows of pixels.
  void _decodeBand(int row) {
    final f = frame!;
    final bs = 8 ~/ scale;
    for (var ci = 0; ci < f.componentsOrder.length; ++ci) {
      final component = f.components[f.componentsOrder[ci]]!;
      final lines = components[ci].lines;
      final bandLines = _bandLines[ci];
      for (var r = 0; r < component.vSamples; ++r) {
        final blockRow = row * component.vSamples + r;
        if (blockRow >= component.blocksPerColumn) {
          break;
        }
        for (var j = 0; j < bs; ++j) {
          lines[blockRow * bs + j] = bandLines[r * bs + j];
        }
        _buildBlockRow(component, r, lines, blockRow * bs, _bandR, _bandRInt);
      }
      // The next band starts with zero coefficients. (Copying zeros is much
      // faster than fillRange.)
      final coefficients = component.coefficients;
      if (_zeros.length < coefficients.length) {
        _zeros = Int16List(coefficients.length);
      }
      coefficients.setRange(0, coefficients.length, _zeros);
    }

    final rowsPerBand = f.maxVSamples * bs;
    final y0 = row * rowsPerBand;
    final y1 = min(y0 + rowsPerBand, scaledHeight);
    if (y0 < y1) {
      _writer!.writeRows(y0, y1);
    }

    // The band's line buffers are reused by the next band.
    for (var ci = 0; ci < f.componentsOrder.length; ++ci) {
      final component = f.components[f.componentsOrder[ci]]!;
      final lines = components[ci].lines;
      final first = row * component.vSamples * bs;
      for (var i = first;
          i < first + component.vSamples * bs && i < lines.length;
          ++i) {
        lines[i] = null;
      }
    }
  }

  bool _prepared = false;
  bool _allowStreaming = false;
  bool _restartNeeded = false;
  JpegImageWriter? _writer;
  final _bandLines = <List<Uint8List>>[];
  final _bandR = Uint8List(64);
  final _bandRInt = Int32List(64);
  var _zeros = Int16List(0);

  // The value of each pixel of a block with only the DC coefficient [p0]
  // (dequantized), as quantizeAndInverse computes it. Floor division of
  // doubles, which are exact here, is used instead of shifts, which would
  // overflow 32 bits on the web.
  static int _dcValue(int p0) {
    final t = ((5793 * p0 + 512) / 1024).floor();
    final t2 = ((5793 * t + 8192) / 16384).floor();
    final v = 128 + ((t2 + 8) / 16).floor();
    return v < 0
        ? 0
        : v > 255
            ? 255
            : v;
  }

  // Averages the 8x8 block [r] down to bs x bs pixels at [sample] of
  // [lines], starting at [scanLine].
  static void _scaleBlock(
      Uint8List r, int bs, List<Uint8List?> lines, int scanLine, int sample) {
    final n = 8 ~/ bs;
    final count = n * n;
    for (var y = 0; y < bs; ++y) {
      final line = lines[scanLine + y]!;
      for (var x = 0; x < bs; ++x) {
        var sum = 0;
        for (var j = 0; j < n; ++j) {
          final row = (y * n + j) * 8 + x * n;
          for (var i = 0; i < n; ++i) {
            sum += r[row + i];
          }
        }
        line[sample + x] = (sum + (count >> 1)) ~/ count;
      }
    }
  }

  static int toFix(double val) {
    const fixedPoint = 20;
    const one = 1 << fixedPoint;
    return (val * one).toInt() & 0xffffffff;
  }
}

class _JpegHuffman {
  final children = List<HuffmanNode?>.filled(2, null);
  int index = 0;
}

// Thrown when an image being decoded a band at a time can't be: it's then
// decoded fully.
class _RestartDecode implements Exception {
  const _RestartDecode();
}
