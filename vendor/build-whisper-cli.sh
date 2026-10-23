#!/bin/sh
# Собирает статический whisper-cli (whisper.cpp, MIT, Metal) в vendor/bin/whisper-cli. Нужен cmake.
set -e
VERSION=1.9.4
cd "$(dirname "$0")"
mkdir -p src bin
if [ ! -d "src/whisper.cpp-$VERSION" ]; then
  curl -fL -o src/whisper.tar.gz "https://github.com/ggml-org/whisper.cpp/archive/refs/tags/v$VERSION.tar.gz"
  tar xf src/whisper.tar.gz -C src
fi
cd "src/whisper.cpp-$VERSION"
cmake -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
  -DGGML_METAL=ON -DGGML_METAL_EMBED_LIBRARY=ON -DGGML_NATIVE=OFF \
  -DWHISPER_BUILD_TESTS=OFF -DWHISPER_SDL2=OFF -DWHISPER_CURL=OFF \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0
cmake --build build -j"$(sysctl -n hw.ncpu)" --target whisper-cli
cp build/bin/whisper-cli ../../bin/whisper-cli
echo "Готово: $(cd ../../bin && pwd)/whisper-cli"
