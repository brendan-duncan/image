import 'dart:typed_data';

import '../../util/_internal.dart';
import '../../util/image_exception.dart';
import '../../util/input_buffer.dart';
import '_jpeg_huffman.dart';
import 'jpeg_component.dart';
import 'jpeg_data.dart';
import 'jpeg_frame.dart';
import 'jpeg_marker.dart';

@internal
class JpegScan {
  InputBuffer input;
  JpegFrame frame;
  int? precision;
  int? samplesPerLine;
  int? scanLines;
  late int mcusPerLine;
  bool? progressive;
  int? maxH;
  int? maxV;
  List<JpegComponent> components;
  int? resetInterval;
  int spectralStart;
  int spectralEnd;
  int successivePrev;
  int successive;

  int bitsData = 0;
  int bitsCount = 0;
  int eobrun = 0;
  int successiveACState = 0;
  late int successiveACNextValue;

  JpegScan(
    this.input,
    this.frame,
    this.components,
    this.resetInterval,
    this.spectralStart,
    this.spectralEnd,
    this.successivePrev,
    this.successive,
  ) {
    precision = frame.precision;
    samplesPerLine = frame.samplesPerLine;
    scanLines = frame.scanLines;
    mcusPerLine = frame.mcusPerLine;
    progressive = frame.progressive;
    maxH = frame.maxHSamples;
    maxV = frame.maxVSamples;
  }

  void decode() {
    final componentsLength = components.length;
    JpegComponent? component;
    _DecodeFn decodeFn;

    if (progressive!) {
      if (spectralStart == 0) {
        decodeFn = successivePrev == 0 ? _decodeDCFirst : _decodeDCSuccessive;
      } else {
        decodeFn = successivePrev == 0 ? _decodeACFirst : _decodeACSuccessive;
      }
    } else {
      decodeFn = _decodeBaseline;
    }

    var mcu = 0;

    int? mcuExpected;
    if (componentsLength == 1) {
      mcuExpected = components[0].blocksPerLine * components[0].blocksPerColumn;
    } else {
      mcuExpected = mcusPerLine * frame.mcusPerColumn;
    }

    if (resetInterval == null || resetInterval == 0) {
      resetInterval = mcuExpected;
    }

    int h, v;
    while (mcu < mcuExpected) {
      // reset interval stuff
      for (var i = 0; i < componentsLength; i++) {
        components[i].pred = 0;
      }
      eobrun = 0;

      if (componentsLength == 1) {
        component = components[0];
        for (var n = 0; n < resetInterval!; n++) {
          _decodeBlock(component, decodeFn, mcu);
          mcu++;
        }
      } else {
        for (var n = 0; n < resetInterval!; n++) {
          for (var i = 0; i < componentsLength; i++) {
            component = components[i];
            h = component.hSamples;
            v = component.vSamples;
            for (var j = 0; j < v; j++) {
              for (var k = 0; k < h; k++) {
                _decodeMcu(component, decodeFn, mcu, j, k);
              }
            }
          }
          mcu++;
        }
      }

      // find marker
      bitsCount = 0;

      // do not advance if the input is exhausted, as this may lead to a
      // RangeError, specifically if the input does not contain the EOI marker,
      // which is an issue in screenshots taken on Xiaomi devices
      if (mcu >= mcuExpected) break;

      final m1 = input[0];
      final m2 = input[1];
      if (m1 == 0xff) {
        if (m2 >= JpegMarker.rst0 && m2 <= JpegMarker.rst7) {
          input.offset += 2;
        } else {
          break;
        }
      }
    }
  }

  int? _readBit() {
    if (bitsCount > 0) {
      bitsCount--;
      return (bitsData >> bitsCount) & 1;
    }

    if (input.isEOS) {
      return null;
    }

    bitsData = input.readByte();
    if (bitsData == 0xff) {
      final nextByte = input.readByte();
      if (nextByte != 0) {
        //final marker = ((bitsData << 8) | nextByte).toRadixString(16);
        //throw ImageException('unexpected marker: $marker');
        return null;
      }
    }

    bitsCount = 7;
    return (bitsData >> 7) & 1;
  }

  int? _decodeHuffman(List<HuffmanNode?> tree) {
    HuffmanNode? node = HuffmanParent(tree);
    int? bit;
    while ((bit = _readBit()) != null) {
      if (node is HuffmanParent) {
        node = node.children[bit!];
      }
      if (node is HuffmanValue) {
        return node.value;
      }
    }
    return null;
  }

  int? _receive(int length) {
    var n = 0;
    while (length > 0) {
      final bit = _readBit();
      if (bit == null) {
        return null;
      }
      n = (n << 1) | bit;
      length--;
    }
    return n;
  }

  int _receiveAndExtend(int? length) {
    if (length == null) {
      return 0;
    }
    if (length == 1) {
      return _readBit() == 1 ? 1 : -1;
    }
    final n = _receive(length);
    if (n == null) {
      return 0;
    }
    if (n >= (1 << (length - 1))) {
      return n;
    }
    return n + (-1 << length) + 1;
  }

  void _decodeBaseline(JpegComponent component, Int16List zz, int o) {
    final t = _decodeHuffman(component.huffmanTableDC);
    final diff = t == 0 ? 0 : _receiveAndExtend(t);
    component.pred += diff;
    zz[o] = component.pred;

    var k = 1;
    while (k < 64) {
      final rs = _decodeHuffman(component.huffmanTableAC);
      if (rs == null) {
        break;
      }
      var s = rs & 15;
      final r = rs >> 4;
      if (s == 0) {
        if (r < 15) {
          break;
        }
        k += 16;
        continue;
      }

      k += r;

      s = _receiveAndExtend(s);

      final z = JpegData.dctZigZag[k];
      zz[o + z] = s;
      k++;
    }
  }

  void _decodeDCFirst(JpegComponent component, Int16List zz, int o) {
    final t = _decodeHuffman(component.huffmanTableDC);
    final diff = (t == 0) ? 0 : (_receiveAndExtend(t) << successive);
    component.pred += diff;
    zz[o] = component.pred;
  }

  void _decodeDCSuccessive(JpegComponent component, Int16List zz, int o) {
    zz[o] = zz[o] | (_readBit()! << successive);
  }

  void _decodeACFirst(JpegComponent component, Int16List zz, int o) {
    if (eobrun > 0) {
      eobrun--;
      return;
    }
    var k = spectralStart;
    final e = spectralEnd;
    while (k <= e) {
      final rs = _decodeHuffman(component.huffmanTableAC)!;
      final s = rs & 15;
      final r = rs >> 4;
      if (s == 0) {
        if (r < 15) {
          eobrun = _receive(r)! + (1 << r) - 1;
          break;
        }
        k += 16;
        continue;
      }
      k += r;
      final z = JpegData.dctZigZag[k];
      zz[o + z] = _receiveAndExtend(s) * (1 << successive);
      k++;
    }
  }

  void _decodeACSuccessive(JpegComponent component, Int16List zz, int o) {
    var k = spectralStart;
    final e = spectralEnd;
    var s = 0;
    var r = 0;
    while (k <= e) {
      final z = o + JpegData.dctZigZag[k];
      switch (successiveACState) {
        case 0: // initial state
          final rs = _decodeHuffman(component.huffmanTableAC);
          if (rs == null) throw ImageException('Invalid progressive encoding');
          s = rs & 15;
          r = rs >> 4;
          if (s == 0) {
            if (r < 15) {
              eobrun = _receive(r)! + (1 << r);
              successiveACState = 4;
            } else {
              r = 16;
              successiveACState = 1;
            }
          } else {
            if (s != 1) {
              throw ImageException('invalid ACn encoding');
            }
            successiveACNextValue = _receiveAndExtend(s);
            successiveACState = r != 0 ? 2 : 3;
          }
          continue;
        case 1: // skipping r zero items
        case 2:
          if (zz[z] != 0) {
            zz[z] += _readBit()! << successive;
          } else {
            r--;
            if (r == 0) {
              successiveACState = successiveACState == 2 ? 3 : 0;
            }
          }
          break;
        case 3: // set value for a zero item
          if (zz[z] != 0) {
            zz[z] += _readBit()! << successive;
          } else {
            zz[z] = successiveACNextValue << successive;
            successiveACState = 0;
          }
          break;
        case 4: // eob
          if (zz[z] != 0) {
            zz[z] += _readBit()! << successive;
          }
          break;
      }
      k++;
    }
    if (successiveACState == 4) {
      eobrun--;
      if (eobrun == 0) {
        successiveACState = 0;
      }
    }
  }

  void _decodeMcu(
    JpegComponent component,
    _DecodeFn decodeFn,
    int mcu,
    int row,
    int col,
  ) {
    final mcuRow = mcu ~/ mcusPerLine;
    final mcuCol = mcu % mcusPerLine;
    final blockRow = mcuRow * component.vSamples + row;
    final blockCol = mcuCol * component.hSamples + col;
    if (blockRow >= component.blocksPerColumnForMcu ||
        blockCol >= component.blocksPerLineForMcu) {
      return;
    }
    decodeFn(component, component.coefficients,
        (blockRow * component.blocksPerLineForMcu + blockCol) << 6);
  }

  void _decodeBlock(
    JpegComponent component,
    _DecodeFn decodeFn,
    int mcu,
  ) {
    final blockRow = mcu ~/ component.blocksPerLine;
    final blockCol = mcu % component.blocksPerLine;
    decodeFn(component, component.coefficients,
        (blockRow * component.blocksPerLineForMcu + blockCol) << 6);
  }
}

/// Decodes the coefficients of one block, starting at [offset] in
/// [coefficients].
typedef _DecodeFn = void Function(
    JpegComponent component, Int16List coefficients, int offset);
