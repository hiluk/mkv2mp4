#!/bin/sh
# Собирает статический ffmpeg (LGPL, только системные зависимости macOS) в vendor/bin/ffmpeg.
set -e
VERSION=9.0.2
cd "$(dirname "$0")"
mkdir -p src bin
if [ ! -d "src/ffmpeg-$VERSION" ]; then
  curl -fL -o src/ffmpeg.tar.xz "https://ffmpeg.org/releases/ffmpeg-$VERSION.tar.xz"
  tar xf src/ffmpeg.tar.xz -C src
fi
cd "src/ffmpeg-$VERSION"
./configure \
  --disable-autodetect --disable-network --disable-doc --disable-ffplay --disable-ffprobe \
  --disable-shared --enable-static --disable-debug \
  --enable-videotoolbox --enable-audiotoolbox --enable-zlib --enable-bzlib --enable-iconv \
  --extra-cflags="-mmacosx-version-min=12.0" --extra-ldflags="-mmacosx-version-min=12.0" \
  --extra-libs="-liconv"
make -j"$(sysctl -n hw.ncpu)"
cp ffmpeg ../../bin/ffmpeg
echo "Готово: $(cd ../../bin && pwd)/ffmpeg"
