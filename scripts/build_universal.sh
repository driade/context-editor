#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${1:-$ROOT_DIR/build-universal}"
ARM64_DERIVED="$BUILD_DIR/derived-arm64"
X86_DERIVED="$BUILD_DIR/derived-x86_64"
OUTPUT_DIR="$BUILD_DIR/output"
APP_NAME="ContextEditor.app"
ARM64_PRODUCTS="$BUILD_DIR/products-arm64"
X86_PRODUCTS="$BUILD_DIR/products-x86_64"
ARM64_APP="$ARM64_PRODUCTS/$APP_NAME"
X86_APP="$X86_PRODUCTS/$APP_NAME"
UNIVERSAL_APP="$OUTPUT_DIR/$APP_NAME"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

xcodebuild \
  -project "$ROOT_DIR/ContextEditor.xcodeproj" \
  -scheme ContextEditor \
  -configuration Release \
  -derivedDataPath "$ARM64_DERIVED" \
  -destination "platform=macOS,arch=arm64" \
  CONFIGURATION_BUILD_DIR="$ARM64_PRODUCTS" \
  build

xcodebuild \
  -project "$ROOT_DIR/ContextEditor.xcodeproj" \
  -scheme ContextEditor \
  -configuration Release \
  -derivedDataPath "$X86_DERIVED" \
  -destination "platform=macOS,arch=x86_64" \
  CONFIGURATION_BUILD_DIR="$X86_PRODUCTS" \
  build

ditto "$ARM64_APP" "$UNIVERSAL_APP"

lipo -create \
  "$ARM64_APP/Contents/MacOS/ContextEditor" \
  "$X86_APP/Contents/MacOS/ContextEditor" \
  -output "$UNIVERSAL_APP/Contents/MacOS/ContextEditor"

codesign --force --sign - --deep --timestamp=none "$UNIVERSAL_APP"

echo "Universal app created at: $UNIVERSAL_APP"
