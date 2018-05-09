import 'dart:typed_data';

import '../../image_exception.dart';
import '../../internal/internal.dart';
import '../../util/input_buffer.dart';
import 'exr_compressor.dart';
import 'exr_part.dart';

abstract class ExrB44Compressor extends ExrCompressor {
  factory ExrB44Compressor(ExrPart header, int maxScanLineSize, int numScanLines,
                           bool optFlatFields) = InternalExrB44Compressor;
}

@internal
class InternalExrB44Compressor extends InternalExrCompressor implements ExrB44Compressor {
  InternalExrB44Compressor(ExrPart header, this._maxScanLineSize, this._numScanLines,
                           this._optFlatFields) :
    super(header) {
  }

  int numScanLines() => _numScanLines;

  Uint8List compress(InputBuffer inPtr, int x, int y,
                     [int width, int height]) {
    throw new ImageException('B44 compression not yet supported.');
  }

  Uint8List uncompress(InputBuffer inPtr, int x, int y,
                       [int width, int height]) {
    throw new ImageException('B44 compression not yet supported.');
  }

  int _maxScanLineSize;
  int _numScanLines;
  bool _optFlatFields;
}
