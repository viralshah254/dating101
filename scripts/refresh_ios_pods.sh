#!/usr/bin/env bash
# Run CocoaPods from the correct Flutter project root so .dart_tool/package_config.json exists.
# Usage: from anywhere —  ./scripts/refresh_ios_pods.sh
#   or:   bash scripts/refresh_ios_pods.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f pubspec.yaml ]]; then
  echo "Error: pubspec.yaml not found in $ROOT" >&2
  exit 1
fi

echo "==> $(pwd) — flutter pub get"
flutter pub get

if [[ ! -f .dart_tool/package_config.json ]]; then
  echo "Error: .dart_tool/package_config.json is still missing after flutter pub get." >&2
  echo "Fix: from this directory, run: rm -rf .dart_tool && flutter pub get" >&2
  echo "     Ensure you are in the same folder as pubspec.yaml (not only ios/)." >&2
  exit 1
fi

echo "==> pod install (ios/)"
cd ios
pod install --repo-update

echo "Done. Open ios/Runner.xcworkspace in Xcode (not the .xcodeproj)."
