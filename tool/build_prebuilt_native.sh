#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUST_DIR="$ROOT_DIR/native/rust"
PREBUILT_DIR="$ROOT_DIR/native/prebuilt"
TARGET="${1:-all}"

run_cargo() {
  (
    cd "$RUST_DIR"
    cargo "$@"
  )
}

build_android() {
  local abi="$1"
  local out_dir="$PREBUILT_DIR/android"
  mkdir -p "$out_dir"
  run_cargo ndk -t "$abi" -o "$out_dir" build --release
}

build_ios() {
  local device_target="aarch64-apple-ios"
  local sim_target="aarch64-apple-ios-sim"
  local sim_x64_target="x86_64-apple-ios"
  local build_root="$PREBUILT_DIR/ios/build"
  local headers_dir="$build_root/Headers"
  local out_device_dir="$PREBUILT_DIR/ios/iphoneos"
  local out_sim_arm64_dir="$PREBUILT_DIR/ios/iphonesimulator-arm64"
  local out_sim_x64_dir="$PREBUILT_DIR/ios/iphonesimulator-x86_64"
  local device_lib="$build_root/iphoneos/libimage_native.dylib"
  local sim_arm64_lib="$build_root/iphonesimulator/libimage_native.arm64.dylib"
  local sim_x64_lib="$build_root/iphonesimulator/libimage_native.x86_64.dylib"

  run_cargo build --release --target "$device_target"
  run_cargo build --release --target "$sim_target"
  run_cargo build --release --target "$sim_x64_target"

  rm -rf "$build_root"
  rm -rf \
    "$PREBUILT_DIR/ios/ImageNative.xcframework" \
    "$PREBUILT_DIR/ios/iphonesimulator" \
    "$out_device_dir" \
    "$out_sim_arm64_dir" \
    "$out_sim_x64_dir"
  mkdir -p \
    "$headers_dir" \
    "$(dirname "$device_lib")" \
    "$(dirname "$sim_arm64_lib")" \
    "$out_device_dir" \
    "$out_sim_arm64_dir" \
    "$out_sim_x64_dir"

  cp "$ROOT_DIR/native/include/image_ffi.h" "$headers_dir/"
  cp "$RUST_DIR/target/$device_target/release/libimage_native.dylib" "$device_lib"
  cp "$RUST_DIR/target/$sim_target/release/libimage_native.dylib" "$sim_arm64_lib"
  cp "$RUST_DIR/target/$sim_x64_target/release/libimage_native.dylib" "$sim_x64_lib"

  install_name_tool -id "@rpath/libimage_native.dylib" "$device_lib"
  install_name_tool -id "@rpath/libimage_native.dylib" "$sim_arm64_lib"
  install_name_tool -id "@rpath/libimage_native.dylib" "$sim_x64_lib"
  cp "$device_lib" "$out_device_dir/libimage_native.dylib"
  cp "$sim_arm64_lib" "$out_sim_arm64_dir/libimage_native.dylib"
  cp "$sim_x64_lib" "$out_sim_x64_dir/libimage_native.dylib"
}

if [[ "$TARGET" == "android" || "$TARGET" == "all" ]]; then
  build_android arm64-v8a
  build_android armeabi-v7a
  build_android x86_64
fi

if [[ "$TARGET" == "ios" || "$TARGET" == "all" ]]; then
  build_ios
fi
