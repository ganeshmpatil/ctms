#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <API_BASE_URL>" >&2
  echo "example: $0 https://names-api.fly.dev" >&2
  exit 1
fi

API_BASE="$1"
ROOT="$(cd "$(dirname "$0")" && pwd)"

cd "$ROOT/flutter_app"
flutter pub get
flutter build apk --release --dart-define=API_BASE="$API_BASE"

mkdir -p "$ROOT/dist"
cp build/app/outputs/flutter-apk/app-release.apk "$ROOT/dist/app-release.apk"
echo "APK ready: $ROOT/dist/app-release.apk"
