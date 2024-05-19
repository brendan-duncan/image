import 'dart:typed_data';

import '../color/color.dart';
import '../color/format.dart';
import '../image/image.dart';
import '../util/input_buffer.dart';
import 'decode_info.dart';
import 'decoder.dart';
import 'image_format.dart';

enum PnmFormat { invalid, pbm, pgm2, pgm5, ppm3, ppm6 }

class PnmInfo extends DecodeInfo {
  // The width of the image canvas.
  @override
  int width = 0;

  /// The height of the image canvas.
  @override
  int height = 0;

  /// The suggested background color of the canvas.
  @override
  Color? backgroundColor;

  /// The number of frames that can be decoded.
  @override
  int numFrames = 1;
  PnmFormat format = PnmFormat.invalid;
}

/// Decode a PNM image.
class PnmDecoder extends Decoder {
  PnmInfo? info;
  InputBuffer? input;
  final _tokens = <String>[];

  @override
  ImageFormat get format => ImageFormat.pnm;

  /// Is the given file a valid TGA image?
  @override
  bool isValidFile(Uint8List data) {
    input = InputBuffer(data);
    final tk = _getNextToken();
    if (tk == 'P1' || tk == 'P2' || tk == 'P5' || tk == 'P3' || tk == 'P6') {
      return true;
    }
    return false;
  }

  @override
  Image? decode(Uint8List bytes, {int? frame}) {
    if (startDecode(bytes) == null) {
      return null;
    }
    return decodeFrame(frame ?? 0);
  }

  @override
  DecodeInfo? startDecode(Uint8List bytes) {
    input = InputBuffer(bytes);

    final tk = _getNextToken();
    if (tk == 'P1') {
      info = PnmInfo();
      info!.format = PnmFormat.pbm;
    } else if (tk == 'P2') {
      info = PnmInfo();
      info!.format = PnmFormat.pgm2;
    } else if (tk == 'P5') {
      info = PnmInfo();
      info!.format = PnmFormat.pgm5;
    } else if (tk == 'P3') {
      info = PnmInfo();
      info!.format = PnmFormat.ppm3;
    } else if (tk == 'P6') {
      info = PnmInfo();
      info!.format = PnmFormat.ppm6;
    } else {
      input = null;
      return null;
    }

    info!.width = _parseNextInt();
    info!.height = _parseNextInt();

    if (info!.width == 0 || info!.height == 0) {
      input = null;
      info = null;
      return null;
    }

    return info;
  }

  @override
  int numFrames() => info != null ? 1 : 0;

  @override
  Image? decodeFrame(int frame) {
    if (info == null) {
      return null;
    }

    if (info!.format == PnmFormat.pbm) {
      final image = Image(
          width: info!.width,
          height: info!.height,
          numChannels: 1,
          format: Format.uint1);
      for (final p in image) {
        final tk = _getNextToken();
        if (tk == '1') {
          p.setRgb(1, 1, 1);
        } else {
          p.setRgb(0, 0, 0);
        }
      }
      return image;
    } else if (info!.format == PnmFormat.pgm2 ||
        info!.format == PnmFormat.pgm5) {
      final maxValue = _parseNextInt();
      if (maxValue == 0) {
        return null;
      }
      final image = Image(
          width: info!.width,
          height: info!.height,
          numChannels: 1,
          format: formatFromMaxValue(maxValue));
      for (final p in image) {
        final g = _readValue(info!.format, maxValue);
        p.setRgb(g, g, g);
      }
      return image;
    } else if (info!.format == PnmFormat.ppm3 ||
        info!.format == PnmFormat.ppm6) {
      final maxValue = _parseNextInt();
      if (maxValue == 0) {
        return null;
      }
      final image = Image(
          width: info!.width,
          height: info!.height,
          format: formatFromMaxValue(maxValue));
      for (final p in image) {
        final r = _readValue(info!.format, maxValue);
        final g = _readValue(info!.format, maxValue);
        final b = _readValue(info!.format, maxValue);
        p.setRgb(r, g, b);
      }
      return image;
    }

    return null;
  }

  Format formatFromMaxValue(int maxValue) {
    if (maxValue > 255) {
      return Format.uint16;
    }
    if (maxValue > 15) {
      return Format.uint8;
    }
    if (maxValue > 3) {
      return Format.uint4;
    }
    if (maxValue > 1) {
      return Format.uint2;
    }
    return Format.uint1;
  }

  int _readValue(PnmFormat format, int maxValue) {
    if (format == PnmFormat.pgm5 || format == PnmFormat.ppm6) {
      return input!.readByte();
    }
    return _parseNextInt();
  }

  int _parseNextInt() {
    final tk = _getNextToken();
    if (tk.isEmpty) {
      return 0;
    }
    try {
      return int.parse(tk);
    } catch (e) {
      return 0;
    }
  }

  String _getNextToken() {
    if (input == null) {
      return '';
    }
    if (_tokens.isNotEmpty) {
      return _tokens.removeAt(0);
    }
    var line = input!.readStringLine().trim();
    if (line.isEmpty) {
      return '';
    }
    while (line.startsWith('#')) {
      line = input!.readStringLine(70).trim();
    }
    final tk = line.split(' ').where((element) => element != "").toList();
    for (var i = 0; i < tk.length; ++i) {
      if (tk[i].startsWith('#')) {
        tk.length = i;
        break;
      }
    }
    _tokens.addAll(tk);
    if (_tokens.isEmpty) {
      return '';
    }
    return _tokens.removeAt(0);
  }
}
