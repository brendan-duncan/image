part of image;

class JpegData  {
  ProgressCallback progressCallback;
  InputBuffer input;
  JpegJfif jfif;
  JpegAdobe adobe;
  JpegFrame frame;
  int resetInterval;
  final List quantizationTables = new List(Jpeg.NUM_QUANT_TBLS);
  final List<JpegFrame> frames = [];
  final List huffmanTablesAC = [];
  final List huffmanTablesDC = [];
  final List<Map> components = [];

  bool validate(List<int> bytes) {
    input = new InputBuffer(bytes, bigEndian: true);

    int marker = _nextMarker();
    if (marker != Jpeg.M_SOI) {
      return false;
    }

    bool hasSOF = false;
    bool hasSOS = false;

    marker = _nextMarker();
    while (marker != Jpeg.M_EOI && !input.isEOS) { // EOI (End of image)
      _skipBlock();
      switch (marker) {
        case Jpeg.M_SOF0: // SOF0 (Start of Frame, Baseline DCT)
        case Jpeg.M_SOF1: // SOF1 (Start of Frame, Extended DCT)
        case Jpeg.M_SOF2: // SOF2 (Start of Frame, Progressive DCT)
          hasSOF = true;
          break;
        case Jpeg.M_SOS: // SOS (Start of Scan)
          hasSOS = true;
          break;
      }

      marker = _nextMarker();
    }

    return hasSOF && hasSOS;
  }

  JpegInfo readInfo(List<int> bytes) {
    input = new InputBuffer(bytes, bigEndian: true);

    int marker = _nextMarker();
    if (marker != Jpeg.M_SOI) {
      return null;
    }

    JpegInfo info;

    bool hasSOF = false;
    bool hasSOS = false;

    marker = _nextMarker();
    while (marker != Jpeg.M_EOI && !input.isEOS) { // EOI (End of image)
      switch (marker) {
        case Jpeg.M_SOF0: // SOF0 (Start of Frame, Baseline DCT)
        case Jpeg.M_SOF1: // SOF1 (Start of Frame, Extended DCT)
        case Jpeg.M_SOF2: // SOF2 (Start of Frame, Progressive DCT)
          hasSOF = true;
          _readFrame(marker, _readBlock());
          break;
        case Jpeg.M_SOS: // SOS (Start of Scan)
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
      info.width = frame.samplesPerLine;
      info.height = frame.scanLines;
    }
    frame = null;
    frames.clear();

    return (hasSOF && hasSOS) ? info : null;
  }

  void read(List<int> bytes) {
    input = new InputBuffer(bytes, bigEndian: true);

    _read();

    if (frames.length != 1) {
      throw new ImageException('Only single frame JPEGs supported');
    }

    _progressTotal = 0;
    _progress = 0;
    for (int i = 0; i < frame.componentsOrder.length; ++i) {
      JpegComponent component = frame.components[frame.componentsOrder[i]];
      _progressTotal += component.blocksPerColumn;
    }

    for (int i = 0; i < frame.componentsOrder.length; ++i) {
      JpegComponent component = frame.components[frame.componentsOrder[i]];
      components.add({
        'scaleX': component.h / frame.maxH,
        'scaleY': component.v / frame.maxV,
        'lines': _buildComponentData(frame, component)
      });
    }
  }

  int get width => frame.samplesPerLine;

  int get height => frame.scanLines;

  Uint8List getData(int width, int height) {
    num scaleX = 1;
    num scaleY = 1;
    Map component1;
    Map component2;
    Map component3;
    Map component4;
    Uint8List component1Line;
    Uint8List component2Line;
    Uint8List component3Line;
    Uint8List component4Line;
    int offset = 0;
    int Y, Cb, Cr, K, C, M, Ye, R, G, B;
    bool colorTransform = false;
    int dataLength = width * height * components.length;
    Uint8List data = new Uint8List(dataLength);

    switch (components.length) {
      case 1:
        component1 = components[0];
        for (int y = 0; y < height; y++) {
          component1Line = component1['lines'][(y * component1['scaleY'] * scaleY).toInt()];
          for (int x = 0; x < width; x++) {
            Y = component1Line[(x * component1['scaleX'] * scaleX).toInt()];
            data[offset++] = Y;
          }
        }
        break;
      case 2:
        // PDF might compress two component data in custom colorspace
        component1 = components[0];
        component2 = components[1];
        for (int y = 0; y < height; y++) {
          component1Line = component1['lines'][(y * component1['scaleY'] * scaleY)];
          component2Line = component2['lines'][(y * component2['scaleY'] * scaleY)];
          for (int x = 0; x < width; x++) {
            Y = component1Line[(x * component1['scaleX'] * scaleX).toInt()];
            data[offset++] = Y;
            Y = component2Line[(x * component2['scaleX'] * scaleX).toInt()];
            data[offset++] = Y;
          }
        }
        break;
      case 3:
        // The default transform for three components is true
        colorTransform = true;
        // The adobe transform marker overrides any previous setting
        /*if (this.adobe && this.adobe.transformCode)
          colorTransform = true;
        else if (typeof this.colorTransform !== 'undefined')
          colorTransform = !!this.colorTransform;*/

        component1 = components[0];
        component2 = components[1];
        component3 = components[2];

        double sy1 = (component1['scaleY'] * scaleY).toDouble();
        double sy2 = (component2['scaleY'] * scaleY).toDouble();
        double sy3 = (component3['scaleY'] * scaleY).toDouble();
        double sx1 = (component1['scaleX'] * scaleX).toDouble();
        double sx2 = (component2['scaleX'] * scaleX).toDouble();
        double sx3 = (component3['scaleX'] * scaleX).toDouble();

        List<Uint8List> lines1 = component1['lines'];
        List<Uint8List> lines2 = component2['lines'];
        List<Uint8List> lines3 = component3['lines'];

        for (int y = 0; y < height; y++) {
          component1Line = lines1[(y * sy1).toInt()];
          component2Line = lines2[(y * sy2).toInt()];
          component3Line = lines3[(y * sy3).toInt()];
          for (int x = 0; x < width; x++) {
            if (!colorTransform) {
              data[offset++] = component1Line[(x * sx1).toInt()];
              data[offset++] = component2Line[(x * sx2).toInt()];
              data[offset++] = component3Line[(x * sx3).toInt()];
            } else {
              Y = component1Line[(x * sx1).toInt()];
              Cb = component2Line[(x * sx2).toInt()];
              Cr = component3Line[(x * sx3).toInt()];

              R = (Y16[Y] + R_CR[Cr]);
              G = (Y16[Y] - G_CB[Cb] - G_CR[Cr]);
              B = (Y16[Y] + B_CB[Cb]);
              data[offset++] = (R > 0) ? _clamp(R >> 4) : 0;
              data[offset++] = (G > 0) ? _clamp(G >> 4) : 0;
              data[offset++] = (B > 0) ? _clamp(B >> 4) : 0;
            }
          }
        }
        break;
      case 4:
        if (adobe == null) {
          throw new ImageException('Unsupported color mode (4 components)');
        }
        // The default transform for four components is false
        colorTransform = false;
        // The adobe transform marker overrides any previous setting
        if (adobe.transformCode != 0) {
          colorTransform = true;
        } /*else if (typeof this.colorTransform !== 'undefined') {
          colorTransform = !!this.colorTransform;
        }*/

        component1 = components[0];
        component2 = components[1];
        component3 = components[2];
        component4 = components[3];

        for (int y = 0; y < height; y++) {
          component1Line = component1['lines'][(y * component1['scaleY'] * scaleY)];
          component2Line = component2['lines'][(y * component2['scaleY'] * scaleY)];
          component3Line = component3['lines'][(y * component3['scaleY'] * scaleY)];
          component4Line = component4['lines'][(y * component4['scaleY'] * scaleY)];
          for (int x = 0; x < width; x++) {
            if (!colorTransform) {
              C = component1Line[(x * component1['scaleX'] * scaleX)];
              M = component2Line[(x * component2['scaleX'] * scaleX)];
              Ye = component3Line[(x * component3['scaleX'] * scaleX)];
              K = component4Line[(x * component4['scaleX'] * scaleX)];
            } else {
              Y = component1Line[(x * component1['scaleX'] * scaleX)];
              Cb = component2Line[(x * component2['scaleX'] * scaleX)];
              Cr = component3Line[(x * component3['scaleX'] * scaleX)];
              K = component4Line[(x * component4['scaleX'] * scaleX)];

              C = 255 - _clamp((Y + 1.402 * (Cr - 128)).toInt());
              M = 255 - _clamp((Y - 0.3441363 * (Cb - 128) - 0.71413636 * (Cr - 128)).toInt());
              Ye = 255 - _clamp((Y + 1.772 * (Cb - 128)).toInt());
            }
            data[offset++] = C;
            data[offset++] = M;
            data[offset++] = Ye;
            data[offset++] = K;
          }
        }
        break;
      default:
        throw new ImageException('Unsupported color mode');
    }
    return data;
  }

  void _read() {
    int marker = _nextMarker();
    if (marker != Jpeg.M_SOI) { // SOI (Start of Image)
      throw new ImageException('Start Of Image marker not found.');
    }

    marker = _nextMarker();
    while (marker != Jpeg.M_EOI && !input.isEOS) {
      InputBuffer block = _readBlock();
      switch (marker) {
        case Jpeg.M_APP0:
        case Jpeg.M_APP1:
        case Jpeg.M_APP2:
        case Jpeg.M_APP3:
        case Jpeg.M_APP4:
        case Jpeg.M_APP5:
        case Jpeg.M_APP6:
        case Jpeg.M_APP7:
        case Jpeg.M_APP8:
        case Jpeg.M_APP9:
        case Jpeg.M_APP10:
        case Jpeg.M_APP11:
        case Jpeg.M_APP12:
        case Jpeg.M_APP13:
        case Jpeg.M_APP14:
        case Jpeg.M_APP15:
        case Jpeg.M_COM:
          _readAppData(marker, block);
          break;

        case Jpeg.M_DQT: // DQT (Define Quantization Tables)
          _readDQT(block);
          break;

        case Jpeg.M_SOF0: // SOF0 (Start of Frame, Baseline DCT)
        case Jpeg.M_SOF1: // SOF1 (Start of Frame, Extended DCT)
        case Jpeg.M_SOF2: // SOF2 (Start of Frame, Progressive DCT)
          _readFrame(marker, block);
          break;

        case Jpeg.M_SOF3:
        case Jpeg.M_SOF5:
        case Jpeg.M_SOF6:
        case Jpeg.M_SOF7:
        case Jpeg.M_JPG:
        case Jpeg.M_SOF9:
        case Jpeg.M_SOF10:
        case Jpeg.M_SOF11:
        case Jpeg.M_SOF13:
        case Jpeg.M_SOF14:
        case Jpeg.M_SOF15:
          throw new ImageException('Unhandled frame type ${marker.toRadixString(16)}');

        case Jpeg.M_DHT: // DHT (Define Huffman Tables)
          _readDHT(block);
          break;

        case Jpeg.M_DRI: // DRI (Define Restart Interval)
          _readDRI(block);
          break;

        case Jpeg.M_SOS: // SOS (Start of Scan)
          _readSOS(block);
          break;

        default:
          if (input[-3] == 0xff && input[-2] >= 0xc0 && input[-2] <= 0xfe) {
            // could be incorrect encoding -- last 0xFF byte of the previous
            // block was eaten by the encoder
            input.offset -= 3;
            break;
          }

          if (marker != 0) {
            throw new ImageException('Unknown JPEG marker ' +
                marker.toRadixString(16));
          }
          break;
      }

      marker = _nextMarker();
    }
  }

  void _skipBlock() {
    int length = input.readUint16();
    if (length < 2) {
      throw new ImageException('Invalid Block');
    }
    input.offset += length - 2;
  }

  InputBuffer _readBlock() {
    int length = input.readUint16();
    if (length < 2) {
      throw new ImageException('Invalid Block');
    }
    return input.readBytes(length - 2);
  }

  int _nextMarker() {
    int c = 0;

    do {
      do {
        c = input.readByte();
      } while (c != 0xff && !input.isEOS);

      do {
        c = input.readByte();
      } while (c == 0xff && !input.isEOS);
    } while (c == 0 && !input.isEOS);

    return c;
  }

  void _readAppData(int marker, InputBuffer block) {
    InputBuffer appData = block;//.buffer;

    if (marker == Jpeg.M_APP0) {
      // 'JFIF\0'
      if (appData[0] == 0x4A && appData[1] == 0x46 &&
          appData[2] == 0x49 && appData[3] == 0x46 && appData[4] == 0) {
        jfif = new JpegJfif();
        jfif.majorVersion = appData[5];
        jfif.minorVersion = appData[6];
        jfif.densityUnits = appData[7];
        jfif.xDensity = _shiftL(appData[8], 8) | appData[9];
        jfif.yDensity = _shiftL(appData[10], 8) | appData[11];
        jfif.thumbWidth = appData[12];
        jfif.thumbHeight = appData[13];
        int thumbSize = 3 * jfif.thumbWidth * jfif.thumbHeight;
        jfif.thumbData = appData.subset(14 + thumbSize, offset: 14);
      }
    }

    if (marker == Jpeg.M_APP14) {
      // 'Adobe\0'
      if (appData[0] == 0x41 && appData[1] == 0x64 &&
          appData[2] == 0x6F && appData[3] == 0x62 &&
          appData[4] == 0x65 && appData[5] == 0) {
        adobe = new JpegAdobe();
        adobe.version = appData[6];
        adobe.flags0 = _shiftL(appData[7], 8) | appData[8];
        adobe.flags1 = _shiftL(appData[9], 8) | appData[10];
        adobe.transformCode = appData[11];
      }
    }
  }

  void _readDQT(InputBuffer block) {
    while (!block.isEOS) {
      int n = block.readByte();
      int prec = _shiftR(n, 4);
      n &= 0x0F;

      if (n >= Jpeg.NUM_QUANT_TBLS) {
        throw new ImageException('Invalid number of quantization tables');
      }

      if (quantizationTables[n] == null) {
        quantizationTables[n] = new Int32List(64);;
      }

      Int32List tableData = quantizationTables[n];
      for (int i = 0; i < Jpeg.DCTSIZE2; i++) {
        int tmp;
        if (prec != 0) {
          tmp = block.readUint16();
        } else {
          tmp = block.readByte();
        }

        tableData[Jpeg.dctNaturalOrder[i]] = tmp;
      }
    }

    if (!block.isEOS) {
      throw new ImageException('Bad length for DQT block');
    }
  }

  void _readFrame(int marker, InputBuffer block) {
    if (frame != null) {
      throw new ImageException('Duplicate JPG frame data found.');
    }

    frame = new JpegFrame();
    frame.extended = (marker == Jpeg.M_SOF1);
    frame.progressive = (marker == Jpeg.M_SOF2);
    frame.precision = block.readByte();
    frame.scanLines = block.readUint16();
    frame.samplesPerLine = block.readUint16();

    int numComponents = block.readByte();

    for (int i = 0; i < numComponents; i++) {
      int componentId = block.readByte();
      int x = block.readByte();
      int h = _shiftR(x, 4) & 15;
      int v = x & 15;
      int qId = block.readByte();
      frame.componentsOrder.add(componentId);
      frame.components[componentId] =
          new JpegComponent(h, v, quantizationTables, qId);
    }

    frame.prepare();
    frames.add(frame);
  }

  void _readDHT(InputBuffer block) {
    while (!block.isEOS) {
      int index = block.readByte();

      Uint8List bits = new Uint8List(16);
      int count = 0;
      for (int j = 0; j < 16; j++) {
        bits[j] = block.readByte();
        count += bits[j];
      }

      Uint8List huffmanValues = new Uint8List(count);
      for (int j = 0; j < count; j++) {
        huffmanValues[j] = block.readByte();
      }

      List ht;
      if (index & 0x10 != 0) { // AC table definition
        index -= 0x10;
        ht = huffmanTablesAC;
      } else { // DC table definition
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
    int n = block.readByte();

    if (n < 1 || n > Jpeg.MAX_COMPS_IN_SCAN) {
      throw new ImageException('Invalid SOS block');
    }

    List components = new List(n);
    for (int i = 0; i < n; i++) {
      int id = block.readByte();
      int c = block.readByte();

      if (!frame.components.containsKey(id)) {
        throw new ImageException('Invalid Component in SOS block');
      }

      JpegComponent component = frame.components[id];
      components[i] = component;

      int dc_tbl_no = _shiftR(c, 4) & 15;
      int ac_tbl_no = c & 15;

      if (dc_tbl_no < huffmanTablesDC.length) {
        component.huffmanTableDC = huffmanTablesDC[dc_tbl_no];
      }
      if (ac_tbl_no < huffmanTablesAC.length) {
        component.huffmanTableAC = huffmanTablesAC[ac_tbl_no];
      }
    }

    int spectralStart = block.readByte();
    int spectralEnd = block.readByte();
    int successiveApproximation = block.readByte();

    int Ah = _shiftR(successiveApproximation, 4) & 15;
    int Al = successiveApproximation & 15;

    new JpegScan(input, frame, components, resetInterval,
                  spectralStart, spectralEnd, Ah, Al).decode();
  }

  List _buildHuffmanTable(List codeLengths, List values) {
    int k = 0;
    List code = [];
    int length = 16;

    while (length > 0 && codeLengths[length - 1] == 0) {
      length--;
    }

    code.add({'children': [], 'index': 0});

    Map p = code[0];
    Map q;

    for (int i = 0; i < length; i++) {
      for (int j = 0; j < codeLengths[i]; j++) {
        p = code.removeLast();
        if (p['children'].length <= p['index']) {
          p['children'].length = p['index'] + 1;
        }
        p['children'][p['index']] = values[k];
        while (p['index'] > 0) {
          p = code.removeLast();
        }
        p['index']++;
        code.add(p);
        while (code.length <= i) {
          q = {'children': [], 'index': 0};
          code.add(q);
          if (p['children'].length <= p['index']) {
            p['children'].length = p['index'] + 1;
          }
          p['children'][p['index']] = q['children'];
          p = q;
        }
        k++;
      }

      if (i + 1 < length) {
        // p here points to last code
        q = { 'children': [],
              'index': 0 };
        code.add(q);
        if (p['children'].length <= p['index']) {
          p['children'].length = p['index'] + 1;
        }
        p['children'][p['index']] = q['children'];
        p = q;
      }
    }

    return code[0]['children'];
  }

  List<Uint8List> _buildComponentData(JpegFrame frame,
                                      JpegComponent component) {
    final int blocksPerLine = component.blocksPerLine;
    final int blocksPerColumn = component.blocksPerColumn;
    int samplesPerLine = _shiftL(blocksPerLine, 3);
    Int32List R = new Int32List(64);
    Uint8List r = new Uint8List(64);
    List<Uint8List> lines = new List(blocksPerColumn * 8);

    int l = 0;
    for (int blockRow = 0; blockRow < blocksPerColumn; blockRow++) {
      if (progressCallback != null) {
        progressCallback(0, 1, _progress++, _progressTotal);
      }
      int scanLine = _shiftL(blockRow, 3);
      for (int i = 0; i < 8; i++) {
        lines[l++] = new Uint8List(samplesPerLine);
      }

      for (int blockCol = 0; blockCol < blocksPerLine; blockCol++) {
        _quantizeAndInverse(component.quantizationTable,
                            component.blocks[blockRow][blockCol],
                            r, R);

        int offset = 0;
        int sample = _shiftL(blockCol, 3);
        for (int j = 0; j < 8; j++) {
          Uint8List line = lines[scanLine + j];
          for (int i = 0; i < 8; i++) {
            line[sample + i] = r[offset++];
          }
        }
      }
    }

    return lines;
  }

  static Uint8List dctClip;
  /**
   * A port of poppler's IDCT method which in turn is taken from:
   * Christoph Loeffler, Adriaan Ligtenberg, George S. Moschytz,
   * "Practical Fast 1-D DCT Algorithms with 11 Multiplications",
   * IEEE Intl. Conf. on Acoustics, Speech & Signal Processing, 1989, 988-991.
   */
  void _quantizeAndInverse(Int32List quantizationTable,
                           Int32List coefBlock,
                           Uint8List dataOut,
                           Int32List dataIn) {
    Int32List p = dataIn;

    const int dctClipOffset = 256;
    const int dctClipLength = 768;
    if (dctClip == null) {
      dctClip = new Uint8List(dctClipLength);
      int i;
      for (i = -256; i < 0; ++i) {
        dctClip[dctClipOffset + i] = 0;
      }
      for (i = 0; i < 256; ++i) {
        dctClip[dctClipOffset + i] = i;
      }
      for (i = 256; i < 512; ++i) {
        dctClip[dctClipOffset + i] = 255;
      }
    }

    // IDCT constants (20.12 fixed point format)
    const int COS_1 = 4017;  // cos(pi/16)
    const int SIN_1 = 799;   // sin(pi/16)
    const int COS_3 = 3406;  // cos(3*pi/16)
    const int SIN_3 = 2276;  // sin(3*pi/16)
    const int COS_6 = 1567;  // cos(6*pi/16)
    const int SIN_6 = 3784;  // sin(6*pi/16)
    const int SQRT_2 = 5793;  // sqrt(2)
    const int SQRT_1D2 = 2896; // sqrt(2) / 2

    // de-quantize
    for (int i = 0; i < 64; i++) {
      p[i] = (coefBlock[i] * quantizationTable[i]);
    }

    // inverse DCT on rows
    int row = 0;
    for (int i = 0; i < 8; ++i, row += 8) {
      // check for all-zero AC coefficients
      if (p[1 + row] == 0 &&
          p[2 + row] == 0 &&
          p[3 + row] == 0 &&
          p[4 + row] == 0 &&
          p[5 + row] == 0 &&
          p[6 + row] == 0 &&
          p[7 + row] == 0) {
        int t = _shiftR((SQRT_2 * p[0 + row] + 512), 10);
        p[row + 0] = t;
        p[row + 1] = t;
        p[row + 2] = t;
        p[row + 3] = t;
        p[row + 4] = t;
        p[row + 5] = t;
        p[row + 6] = t;
        p[row + 7] = t;
        continue;
      }

      // stage 4
      int v0 = _shiftR((SQRT_2 * p[0 + row] + 128), 8);
      int v1 = _shiftR((SQRT_2 * p[4 + row] + 128), 8);
      int v2 = p[2 + row];
      int v3 = p[6 + row];
      int v4 = _shiftR((SQRT_1D2 * (p[1 + row] - p[7 + row]) + 128), 8);
      int v7 = _shiftR((SQRT_1D2 * (p[1 + row] + p[7 + row]) + 128), 8);
      int v5 = _shiftL(p[3 + row], 4);
      int v6 = _shiftL(p[5 + row], 4);

      // stage 3
      int t = _shiftR((v0 - v1 + 1), 1);
      v0 = _shiftR((v0 + v1 + 1), 1);
      v1 = t;
      t = _shiftR((v2 * SIN_6 + v3 * COS_6 + 128), 8);
      v2 = _shiftR((v2 * COS_6 - v3 * SIN_6 + 128), 8);
      v3 = t;
      t = _shiftR((v4 - v6 + 1), 1);
      v4 = _shiftR((v4 + v6 + 1), 1);
      v6 = t;
      t = _shiftR((v7 + v5 + 1), 1);
      v5 = _shiftR((v7 - v5 + 1), 1);
      v7 = t;

      // stage 2
      t = _shiftR((v0 - v3 + 1), 1);
      v0 = _shiftR((v0 + v3 + 1), 1);
      v3 = t;
      t = _shiftR((v1 - v2 + 1), 1);
      v1 = _shiftR((v1 + v2 + 1), 1);
      v2 = t;
      t = _shiftR((v4 * SIN_3 + v7 * COS_3 + 2048), 12);
      v4 = _shiftR((v4 * COS_3 - v7 * SIN_3 + 2048), 12);
      v7 = t;
      t = _shiftR((v5 * SIN_1 + v6 * COS_1 + 2048), 12);
      v5 = _shiftR((v5 * COS_1 - v6 * SIN_1 + 2048), 12);
      v6 = t;

      // stage 1
      p[0 + row] = (v0 + v7);
      p[7 + row] = (v0 - v7);
      p[1 + row] = (v1 + v6);
      p[6 + row] = (v1 - v6);
      p[2 + row] = (v2 + v5);
      p[5 + row] = (v2 - v5);
      p[3 + row] = (v3 + v4);
      p[4 + row] = (v3 - v4);
    }

    // inverse DCT on columns
    for (int i = 0; i < 8; ++i) {
      int col = i;

      // check for all-zero AC coefficients
      if (p[1 * 8 + col] == 0 &&
          p[2 * 8 + col] == 0 &&
          p[3 * 8 + col] == 0 &&
          p[4 * 8 + col] == 0 &&
          p[5 * 8 + col] == 0 &&
          p[6 * 8 + col] == 0 &&
          p[7 * 8 + col] == 0) {
        int t = _shiftR((SQRT_2 * dataIn[i] + 8192), 14);
        p[0 * 8 + col] = t;
        p[1 * 8 + col] = t;
        p[2 * 8 + col] = t;
        p[3 * 8 + col] = t;
        p[4 * 8 + col] = t;
        p[5 * 8 + col] = t;
        p[6 * 8 + col] = t;
        p[7 * 8 + col] = t;
        continue;
      }

      // stage 4
      int v0 = _shiftR((SQRT_2 * p[0 * 8 + col] + 2048), 12);
      int v1 = _shiftR((SQRT_2 * p[4 * 8 + col] + 2048), 12);
      int v2 = p[2 * 8 + col];
      int v3 = p[6 * 8 + col];
      int v4 = _shiftR((SQRT_1D2 * (p[1 * 8 + col] - p[7 * 8 + col]) + 2048), 12);
      int v7 = _shiftR((SQRT_1D2 * (p[1 * 8 + col] + p[7 * 8 + col]) + 2048), 12);
      int v5 = p[3 * 8 + col];
      int v6 = p[5 * 8 + col];

      // stage 3
      int t = _shiftR((v0 - v1 + 1), 1);
      v0 = _shiftR((v0 + v1 + 1), 1);
      v1 = t;
      t = _shiftR((v2 * SIN_6 + v3 * COS_6 + 2048), 12);
      v2 = _shiftR((v2 * COS_6 - v3 * SIN_6 + 2048), 12);
      v3 = t;
      t = _shiftR((v4 - v6 + 1), 1);
      v4 = _shiftR((v4 + v6 + 1), 1);
      v6 = t;
      t = _shiftR((v7 + v5 + 1), 1);
      v5 = _shiftR((v7 - v5 + 1), 1);
      v7 = t;

      // stage 2
      t = _shiftR((v0 - v3 + 1), 1);
      v0 = _shiftR((v0 + v3 + 1), 1);
      v3 = t;
      t = _shiftR((v1 - v2 + 1), 1);
      v1 = _shiftR((v1 + v2 + 1), 1);
      v2 = t;
      t = _shiftR((v4 * SIN_3 + v7 * COS_3 + 2048), 12);
      v4 = _shiftR((v4 * COS_3 - v7 * SIN_3 + 2048), 12);
      v7 = t;
      t = _shiftR((v5 * SIN_1 + v6 * COS_1 + 2048), 12);
      v5 = _shiftR((v5 * COS_1 - v6 * SIN_1 + 2048), 12);
      v6 = t;

      // stage 1
      p[0 * 8 + col] = (v0 + v7);
      p[7 * 8 + col] = (v0 - v7);
      p[1 * 8 + col] = (v1 + v6);
      p[6 * 8 + col] = (v1 - v6);
      p[2 * 8 + col] = (v2 + v5);
      p[5 * 8 + col] = (v2 - v5);
      p[3 * 8 + col] = (v3 + v4);
      p[4 * 8 + col] = (v3 - v4);
    }

    // convert to 8-bit integers
    for (int i = 0; i < 64; ++i) {
      dataOut[i] = dctClip[(dctClipOffset + 128 + _shiftR((p[i] + 8), 4))];
    }
  }

  int _clamp(int i) => i < 0 ? 0 : i > 255 ? 255 : i;

  int _progressTotal = 0;
  int _progress = 0;

  static const List<int> Y16 = const [
        0, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176, 192, 208, 224, 240,
        256, 272, 288, 304, 320, 336, 352, 368, 384, 400, 416, 432, 448, 464, 480,
        496, 512, 528, 544, 560, 576, 592, 608, 624, 640, 656, 672, 688, 704, 720,
        736, 752, 768, 784, 800, 816, 832, 848, 864, 880, 896, 912, 928, 944, 960,
        976, 992, 1008, 1024, 1040, 1056, 1072, 1088, 1104, 1120, 1136, 1152,
        1168, 1184, 1200, 1216, 1232, 1248, 1264, 1280, 1296, 1312, 1328, 1344,
        1360, 1376, 1392, 1408, 1424, 1440, 1456, 1472, 1488, 1504, 1520, 1536,
        1552, 1568, 1584, 1600, 1616, 1632, 1648, 1664, 1680, 1696, 1712, 1728,
        1744, 1760, 1776, 1792, 1808, 1824, 1840, 1856, 1872, 1888, 1904, 1920,
        1936, 1952, 1968, 1984, 2000, 2016, 2032, 2048, 2064, 2080, 2096, 2112,
        2128, 2144, 2160, 2176, 2192, 2208, 2224, 2240, 2256, 2272, 2288, 2304,
        2320, 2336, 2352, 2368, 2384, 2400, 2416, 2432, 2448, 2464, 2480, 2496,
        2512, 2528, 2544, 2560, 2576, 2592, 2608, 2624, 2640, 2656, 2672, 2688,
        2704, 2720, 2736, 2752, 2768, 2784, 2800, 2816, 2832, 2848, 2864, 2880,
        2896, 2912, 2928, 2944, 2960, 2976, 2992, 3008, 3024, 3040, 3056, 3072,
        3088, 3104, 3120, 3136, 3152, 3168, 3184, 3200, 3216, 3232, 3248, 3264,
        3280, 3296, 3312, 3328, 3344, 3360, 3376, 3392, 3408, 3424, 3440, 3456,
        3472, 3488, 3504, 3520, 3536, 3552, 3568, 3584, 3600, 3616, 3632, 3648,
        3664, 3680, 3696, 3712, 3728, 3744, 3760, 3776, 3792, 3808, 3824, 3840,
        3856, 3872, 3888, 3904, 3920, 3936, 3952, 3968, 3984, 4000, 4016, 4032,
        4048, 4064, 4080];

    static const List<int> R_CR = const [
        -2872, -2849, -2827, -2804, -2782, -2760, -2737, -2715, -2692, -2670,
        -2647, -2625, -2603, -2580, -2558, -2535, -2513, -2490, -2468, -2446,
        -2423, -2401, -2378, -2356, -2333, -2311, -2289, -2266, -2244, -2221,
        -2199, -2176, -2154, -2132, -2109, -2087, -2064, -2042, -2019, -1997,
        -1975, -1952, -1930, -1907, -1885, -1862, -1840, -1817, -1795, -1773,
        -1750, -1728, -1705, -1683, -1660, -1638, -1616, -1593, -1571, -1548,
        -1526, -1503, -1481, -1459, -1436, -1414, -1391, -1369, -1346, -1324,
        -1302, -1279, -1257, -1234, -1212, -1189, -1167, -1145, -1122, -1100,
        -1077, -1055, -1032, -1010, -988, -965, -943, -920, -898, -875, -853,
        -830, -808, -786, -763, -741, -718, -696, -673, -651, -629, -606, -584,
        -561, -539, -516, -494, -472, -449, -427, -404, -382, -359, -337, -315,
        -292, -270, -247, -225, -202, -180, -158, -135, -113, -90, -68, -45, -23,
        0, 22, 44, 67, 89, 112, 134, 157, 179, 201, 224, 246, 269, 291, 314, 336,
        358, 381, 403, 426, 448, 471, 493, 515, 538, 560, 583, 605, 628, 650, 672,
        695, 717, 740, 762, 785, 807, 829, 852, 874, 897, 919, 942, 964, 987,
        1009, 1031, 1054, 1076, 1099, 1121, 1144, 1166, 1188, 1211, 1233, 1256,
        1278, 1301, 1323, 1345, 1368, 1390, 1413, 1435, 1458, 1480, 1502, 1525,
        1547, 1570, 1592, 1615, 1637, 1659, 1682, 1704, 1727, 1749, 1772, 1794,
        1816, 1839, 1861, 1884, 1906, 1929, 1951, 1974, 1996, 2018, 2041, 2063,
        2086, 2108, 2131, 2153, 2175, 2198, 2220, 2243, 2265, 2288, 2310, 2332,
        2355, 2377, 2400, 2422, 2445, 2467, 2489, 2512, 2534, 2557, 2579, 2602,
        2624, 2646, 2669, 2691, 2714, 2736, 2759, 2781, 2804, 2826, 2848];

    static const List<int> G_CB = const [
        -705, -700, -694, -689, -683, -678, -672, -667, -661, -656, -650, -645,
        -639, -634, -628, -623, -617, -612, -606, -601, -595, -590, -584, -579,
        -573, -568, -562, -557, -551, -546, -540, -535, -529, -524, -518, -513,
        -507, -502, -496, -491, -485, -480, -474, -469, -463, -458, -452, -447,
        -441, -435, -430, -424, -419, -413, -408, -402, -397, -391, -386, -380,
        -375, -369, -364, -358, -353, -347, -342, -336, -331, -325, -320, -314,
        -309, -303, -298, -292, -287, -281, -276, -270, -265, -259, -254, -248,
        -243, -237, -232, -226, -221, -215, -210, -204, -199, -193, -188, -182,
        -177, -171, -166, -160, -155, -149, -144, -138, -133, -127, -122, -116,
        -111, -105, -100, -94, -89, -83, -78, -72, -67, -61, -56, -50, -45, -39,
        -34, -28, -23, -17, -12, -6, 0, 5, 11, 16, 22, 27, 33, 38, 44, 49, 55, 60,
        66, 71, 77, 82, 88, 93, 99, 104, 110, 115, 121, 126, 132, 137, 143, 148,
        154, 159, 165, 170, 176, 181, 187, 192, 198, 203, 209, 214, 220, 225, 231,
        236, 242, 247, 253, 258, 264, 269, 275, 280, 286, 291, 297, 302, 308, 313,
        319, 324, 330, 335, 341, 346, 352, 357, 363, 368, 374, 379, 385, 390, 396,
        401, 407, 412, 418, 423, 429, 434, 440, 446, 451, 457, 462, 468, 473, 479,
        484, 490, 495, 501, 506, 512, 517, 523, 528, 534, 539, 545, 550, 556, 561,
        567, 572, 578, 583, 589, 594, 600, 605, 611, 616, 622, 627, 633, 638, 644,
        649, 655, 660, 666, 671, 677, 682, 688, 693, 699];

    static const List<int> G_CR = const [
        -1463, -1452, -1440, -1429, -1417, -1406, -1394, -1383, -1372, -1360,
        -1349, -1337, -1326, -1315, -1303, -1292, -1280, -1269, -1257, -1246,
        -1235, -1223, -1212, -1200, -1189, -1177, -1166, -1155, -1143, -1132,
        -1120, -1109, -1097, -1086, -1075, -1063, -1052, -1040, -1029, -1017,
        -1006, -995, -983, -972, -960, -949, -937, -926, -915, -903, -892, -880,
        -869, -857, -846, -835, -823, -812, -800, -789, -777, -766, -755, -743,
        -732, -720, -709, -697, -686, -675, -663, -652, -640, -629, -618, -606,
        -595, -583, -572, -560, -549, -538, -526, -515, -503, -492, -480, -469,
        -458, -446, -435, -423, -412, -400, -389, -378, -366, -355, -343, -332,
        -320, -309, -298, -286, -275, -263, -252, -240, -229, -218, -206, -195,
        -183, -172, -160, -149, -138, -126, -115, -103, -92, -80, -69, -58, -46,
        -35, -23, -12, 0, 11, 22, 34, 45, 57, 68, 79, 91, 102, 114, 125, 137, 148,
        159, 171, 182, 194, 205, 217, 228, 239, 251, 262, 274, 285, 297, 308, 319,
        331, 342, 354, 365, 377, 388, 399, 411, 422, 434, 445, 457, 468, 479, 491,
        502, 514, 525, 537, 548, 559, 571, 582, 594, 605, 617, 628, 639, 651, 662,
        674, 685, 696, 708, 719, 731, 742, 754, 765, 776, 788, 799, 811, 822, 834,
        845, 856, 868, 879, 891, 902, 914, 925, 936, 948, 959, 971, 982, 994,
        1005, 1016, 1028, 1039, 1051, 1062, 1074, 1085, 1096, 1108, 1119, 1131,
        1142, 1154, 1165, 1176, 1188, 1199, 1211, 1222, 1234, 1245, 1256, 1268,
        1279, 1291, 1302, 1314, 1325, 1336, 1348, 1359, 1371, 1382, 1393, 1405,
        1416, 1428, 1439, 1451];

    static const List<int> B_CB = const [
        -3630, -3601, -3573, -3544, -3516, -3488, -3459, -3431, -3403, -3374,
        -3346, -3318, -3289, -3261, -3233, -3204, -3176, -3148, -3119, -3091,
        -3063, -3034, -3006, -2977, -2949, -2921, -2892, -2864, -2836, -2807,
        -2779, -2751, -2722, -2694, -2666, -2637, -2609, -2581, -2552, -2524,
        -2495, -2467, -2439, -2410, -2382, -2354, -2325, -2297, -2269, -2240,
        -2212, -2184, -2155, -2127, -2099, -2070, -2042, -2013, -1985, -1957,
        -1928, -1900, -1872, -1843, -1815, -1787, -1758, -1730, -1702, -1673,
        -1645, -1617, -1588, -1560, -1532, -1503, -1475, -1446, -1418, -1390,
        -1361, -1333, -1305, -1276, -1248, -1220, -1191, -1163, -1135, -1106,
        -1078, -1050, -1021, -993, -964, -936, -908, -879, -851, -823, -794,
        -766, -738, -709, -681, -653, -624, -596, -568, -539, -511, -482, -454,
        -426, -397, -369, -341, -312, -284, -256, -227, -199, -171, -142, -114,
        -86, -57, -29, 0, 28, 56, 85, 113, 141, 170, 198, 226, 255, 283, 311,
        340, 368, 396, 425, 453, 481, 510, 538, 567, 595, 623, 652, 680, 708,
        737, 765, 793, 822, 850, 878, 907, 935, 963, 992, 1020, 1049, 1077, 1105,
        1134, 1162, 1190, 1219, 1247, 1275, 1304, 1332, 1360, 1389, 1417, 1445,
        1474, 1502, 1531, 1559, 1587, 1616, 1644, 1672, 1701, 1729, 1757, 1786,
        1814, 1842, 1871, 1899, 1927, 1956, 1984, 2012, 2041, 2069, 2098, 2126,
        2154, 2183, 2211, 2239, 2268, 2296, 2324, 2353, 2381, 2409, 2438, 2466,
        2494, 2523, 2551, 2580, 2608, 2636, 2665, 2693, 2721, 2750, 2778, 2806,
        2835, 2863, 2891, 2920, 2948, 2976, 3005, 3033, 3062, 3090, 3118, 3147,
        3175, 3203, 3232, 3260, 3288, 3317, 3345, 3373, 3402, 3430, 3458, 3487,
        3515, 3544, 3572, 3600];
}
