import 'package:ffigen/ffigen.dart';

void main() {
  FfiGenerator(
    headers: Headers(
      entryPoints: [Uri.file('native/include/image_ffi.h')],
    ),
    functions: Functions(
      include: Declarations.includeSet({
        'image_resize_rgba8',
        'image_crop_rgba8',
        'image_gaussian_blur_rgba8',
        'image_free_buffer',
        'image_last_error_message',
      }),
    ),
    structs: Structs(
      include: Declarations.includeSet({'ImageBuffer', 'ImageResult'}),
    ),
    output: Output(
      dartFile: Uri.file('lib/src/native/bindings.dart'),
      style: const DynamicLibraryBindings(
        wrapperName: 'image_native_bindings',
        wrapperDocComment: 'Generate FFI bindings for the Rust image backend.',
      ),
    ),
  ).generate();
}
