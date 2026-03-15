import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) {
      return;
    }

    final packageRoot = input.packageRoot;
    final targetOs = input.config.code.targetOS.name.toLowerCase();
    final architecture = input.config.code.targetArchitecture.name.toLowerCase();
    final iosSdkType = targetOs == 'ios'
        ? input.config.code.iOS.targetSdk.type.toLowerCase()
        : null;
    final sourceAsset = _prebuiltAssetForTarget(
      packageRoot,
      targetOs: targetOs,
      architecture: architecture,
      iosSdkType: iosSdkType,
    );
    if (sourceAsset == null) {
      return;
    }
    final builtLibrary = await _copyBundledAsset(
      sourceAsset: sourceAsset,
      outputDir: input.outputDirectoryShared,
      targetOs: targetOs,
      architecture: architecture,
      iosSdkType: iosSdkType,
    );

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: 'src/native/bindings.dart',
        linkMode: _linkModeForTarget(targetOs),
        file: builtLibrary,
      ),
    );
    output.dependencies.add(sourceAsset);
    output.dependencies.add(packageRoot.resolve('native/include/image_ffi.h'));
  });
}

Uri? _prebuiltAssetForTarget(
  Uri packageRoot, {
  required String targetOs,
  required String architecture,
  required String? iosSdkType,
}) {
  final relativePath = switch ((targetOs, architecture)) {
    ('android', 'arm64') => 'native/prebuilt/android/arm64-v8a/libimage_native.so',
    ('android', 'arm') => 'native/prebuilt/android/armeabi-v7a/libimage_native.so',
    ('android', 'x64') => 'native/prebuilt/android/x86_64/libimage_native.so',
    ('ios', _) => _iosPrebuiltAssetPath(
        architecture: architecture,
        sdkType: iosSdkType,
      ),
    _ => null,
  };
  if (relativePath == null) {
    return null;
  }
  return packageRoot.resolve(relativePath);
}

LinkMode _linkModeForTarget(String targetOs) {
  return switch (targetOs) {
    'android' || 'ios' => DynamicLoadingBundled(),
    _ => throw UnsupportedError('Unsupported native asset target OS: $targetOs'),
  };
}

String _iosPrebuiltAssetPath({
  required String architecture,
  required String? sdkType,
}) {
  final sdk = sdkType ?? 'iphoneos';
  final slice = switch ((sdk, architecture)) {
    ('iphoneos', 'arm64') =>
      'iphoneos/libimage_native.dylib',
    ('iphonesimulator', 'arm64') =>
      'iphonesimulator-arm64/libimage_native.dylib',
    ('iphonesimulator', 'x64') =>
      'iphonesimulator-x86_64/libimage_native.dylib',
    _ => throw UnsupportedError(
        'Unsupported iOS XCFramework target: sdk=$sdk architecture=$architecture'),
  };
  return 'native/prebuilt/ios/$slice';
}

Future<Uri> _copyBundledAsset({
  required Uri sourceAsset,
  required Uri outputDir,
  required String targetOs,
  required String architecture,
  required String? iosSdkType,
}) async {
  final sourceFile = File.fromUri(sourceAsset);
  if (!await sourceFile.exists()) {
    throw StateError(
      'Missing prebuilt native asset at ${sourceFile.path}. '
      'Publish precompiled binaries with the package before release.',
    );
  }

  final assetName = sourceAsset.pathSegments.last;
  final variantDirName = [
    targetOs,
    architecture,
    if (iosSdkType != null) iosSdkType,
  ].join('-');
  final destinationDir = Directory.fromUri(outputDir.resolve('$variantDirName/'));
  await destinationDir.create(recursive: true);
  final destination = outputDir.resolve('$variantDirName/$assetName');
  await sourceFile.copy(destination.toFilePath());
  return destination;
}
