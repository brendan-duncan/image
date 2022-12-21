import 'dart:typed_data';

import '../image/image.dart';
import 'execute_result.dart';
import 'image_command.dart';


Future<ExecuteResult> executeCommandAsync(ImageCommand? command) async =>
    throw UnsupportedError('Cannot use without dart:html or dart:io');

Image? executeCommandImage(ImageCommand? command) =>
    throw UnsupportedError('Cannot use without dart:html or dart:io');

Future<Image?> executeCommandImageAsync(ImageCommand? command) async =>
    throw UnsupportedError('Cannot use without dart:html or dart:io');

Uint8List? executeCommandBytes(ImageCommand? command) =>
    throw UnsupportedError('Cannot use without dart:html or dart:io');

Future<Uint8List?> executeCommandBytesAsync(ImageCommand? command) async =>
    throw UnsupportedError('Cannot use without dart:html or dart:io');
