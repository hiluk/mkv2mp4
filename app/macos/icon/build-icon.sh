#!/bin/sh
# Рендерит app_icon.svg в PNG всех размеров для AppIcon.appiconset (через AppKit, без сторонних утилит).
set -e
cd "$(dirname "$0")"
OUT=../Runner/Assets.xcassets/AppIcon.appiconset
TMP=$(mktemp -d)
swiftc -O raster.swift -o "$TMP/raster"
for size in 16 32 64 128 256 512 1024; do
  "$TMP/raster" app_icon.svg "$size" "$OUT/app_icon_$size.png"
done
rm -rf "$TMP"
echo "Готово: $OUT"
