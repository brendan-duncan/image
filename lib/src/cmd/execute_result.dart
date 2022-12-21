import 'dart:typed_data';

import '../image/image.dart';
import '../util/internal.dart';

@internal
class ExecuteResult {
  Image? image;
  Uint8List? bytes;
  ExecuteResult(this.image, this.bytes);
}
