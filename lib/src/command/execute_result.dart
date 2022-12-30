import 'dart:typed_data';

import '../image/image.dart';
import '../util/internal.dart';

@internal
class ExecuteResult {
  Image? image;
  Uint8List? bytes;
  Object? object;
  ExecuteResult(this.image, this.bytes, this.object);
}
