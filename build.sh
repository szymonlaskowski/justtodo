#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP="JustTodo.app"

(cd web && bun install --silent && bun run build)

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp -R web/dist "$APP/Contents/Resources/site"

ICONSET=$(mktemp -d)/JustTodo.iconset
mkdir -p "$ICONSET"
for size in 16 32 64 128 256 512; do
  sips -Z $size icon.png --out "$ICONSET/icon_${size}x${size}.png" > /dev/null
  sips -Z $((size * 2)) icon.png --out "$ICONSET/icon_${size}x${size}@2x.png" > /dev/null
done
iconutil --convert icns "$ICONSET" --output "$APP/Contents/Resources/JustTodo.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>JustTodo</string>
  <key>CFBundleExecutable</key><string>JustTodo</string>
  <key>CFBundleIdentifier</key><string>dev.szymon.justtodo</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleIconFile</key><string>JustTodo</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

swiftc -O -target arm64-apple-macos14.0 main.swift -o "$APP/Contents/MacOS/JustTodo"
codesign --force --deep --sign - "$APP"
echo "built $APP"

if [ "${1:-}" = "--install" ]; then
  pkill -f "/Applications/$APP/Contents/MacOS/JustTodo" || true
  while pgrep -f "/Applications/$APP/Contents/MacOS/JustTodo" > /dev/null; do sleep 0.1; done
  rm -rf "/Applications/$APP"
  cp -R "$APP" /Applications/
  open "/Applications/$APP"
  echo "installed /Applications/$APP"
fi
