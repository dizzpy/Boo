#!/bin/bash
# Builds Boo.app from the Swift package.
set -e

APP="Boo.app"
BIN="Boo"

echo "Building release binary…"
swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

cp ".build/release/$BIN" "$APP/Contents/MacOS/$BIN"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>            <string>Boo</string>
  <key>CFBundleDisplayName</key>     <string>Boo</string>
  <key>CFBundleIdentifier</key>      <string>co.dizzpy.boo</string>
  <key>CFBundleVersion</key>         <string>1.0</string>
  <key>CFBundleShortVersionString</key> <string>1.0</string>
  <key>CFBundlePackageType</key>     <string>APPL</string>
  <key>CFBundleExecutable</key>      <string>Boo</string>
  <key>LSMinimumSystemVersion</key>  <string>13.0</string>
  <key>LSUIElement</key>             <true/>
</dict>
</plist>
EOF

echo "Done: $APP"
echo "Move it to /Applications and add to Login Items to auto-start."
