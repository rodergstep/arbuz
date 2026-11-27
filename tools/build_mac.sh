#!/bin/bash
# Builds the macOS app into one fixed place, replacing the last build:
#   build/macos/Tygrytsa's Journey.app   (double-click to play)
#   build/macos/arbuz.zip                 (the same app zipped, e.g. for the Intel MacBook)
# Anything else in build/macos (older builds) goes to the Trash.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
OUT=build/macos
mkdir -p "$OUT"
"$GODOT" --headless --path . --import --quit >/dev/null 2>&1 || true
NEXT=build/macos_next
mkdir -p "$NEXT"
"$GODOT" --headless --path . --export-release "macOS" "$NEXT/arbuz.zip" >/dev/null 2>&1
STAMP=$(date +%Y%m%d-%H%M%S)
TRASH="$HOME/.Trash/arbuz-build-$STAMP"
for old in "$OUT"/*; do
	[ -e "$old" ] || continue
	mkdir -p "$TRASH"
	mv "$old" "$TRASH/"
done
mv "$NEXT/arbuz.zip" "$OUT/arbuz.zip"
rmdir "$NEXT"
unzip -q -o "$OUT/arbuz.zip" -d "$OUT"
echo "Built: $OUT/Tygrytsa's Journey.app"
