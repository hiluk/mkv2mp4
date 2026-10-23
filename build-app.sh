#!/bin/sh
# Собирает MKV2MP4.app и dist/MKV2MP4.dmg. Нужны: Xcode, Flutter (fvm 3.38.6), rustup, cmake.
set -e
cd "$(dirname "$0")"
export PATH="/opt/homebrew/opt/rustup/bin:$HOME/.cargo/bin:$PATH"
FLUTTER="${FLUTTER:-$HOME/fvm/versions/3.38.6/bin/flutter}"

[ -f vendor/bin/ffmpeg ] || vendor/build-ffmpeg.sh
[ -f vendor/bin/whisper-cli ] || vendor/build-whisper-cli.sh

cd app
"$FLUTTER" pub get
flutter_rust_bridge_codegen generate
"$FLUTTER" pub run build_runner build -d
"$FLUTTER" build macos --release
cd ..

APP=app/build/macos/Build/Products/Release/MKV2MP4.app
STAGE=$(mktemp -d)
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
mkdir -p dist
rm -f dist/MKV2MP4.dmg
hdiutil create -volname "MKV2MP4" -srcfolder "$STAGE" -ov -format UDZO dist/MKV2MP4.dmg >/dev/null
rm -rf "$STAGE"
echo "Готово: $(pwd)/dist/MKV2MP4.dmg"
