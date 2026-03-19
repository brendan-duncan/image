Prebuilt native binaries for package consumers belong in this directory.

Expected layout:

- `android/arm64-v8a/libimage_native.so`
- `android/armeabi-v7a/libimage_native.so`
- `android/x86_64/libimage_native.so`
- `ios/iphoneos/libimage_native.dylib`
- `ios/iphonesimulator-arm64/libimage_native.dylib`
- `ios/iphonesimulator-x86_64/libimage_native.dylib`

These artifacts should be produced by CI before publishing so end users can
consume the package with `pub add image` and do not need a local Rust toolchain.

The iOS binaries are stored as Mach-O dylibs because Flutter native assets
package Apple binaries into frameworks during app assembly and expect dynamic
libraries, not static archives.
