#!/bin/bash
# Builds Boo.app from the Swift package, then a simple Boo.dmg for distribution.
set -euo pipefail

APP="Boo.app"
DMG="Boo.dmg"
BIN="Boo"
ENTITLEMENTS="Boo.entitlements"

# Version: $BOO_VERSION (CI passes the git tag), else the latest local tag.
VERSION="${BOO_VERSION:-$(git describe --tags --abbrev=0 2>/dev/null || echo 0.0.0)}"
VERSION="${VERSION#v}"

echo "Building release binary (v$VERSION)…"
swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp ".build/release/$BIN" "$APP/Contents/MacOS/$BIN"

# Ship the avatar art at a predictable path the app looks up at runtime.
cp -R "Sources/Boo/Resources/Avatars" "$APP/Contents/Resources/Avatars"

# Build the app icon (rounded) from Icon/icon.png, if present.
ICON_SRC="Icon/icon.png"
if [ -f "$ICON_SRC" ]; then
  echo "Generating app icon…"
  ICONSET="$(mktemp -d)/AppIcon.iconset"
  swift Scripts/make-icon.swift "$ICON_SRC" "$ICONSET"
  iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
fi

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>            <string>Boo</string>
  <key>CFBundleDisplayName</key>     <string>Boo</string>
  <key>CFBundleIdentifier</key>      <string>co.dizzpy.boo</string>
  <key>CFBundleVersion</key>         <string>$VERSION</string>
  <key>CFBundleShortVersionString</key> <string>$VERSION</string>
  <key>CFBundlePackageType</key>     <string>APPL</string>
  <key>CFBundleExecutable</key>      <string>Boo</string>
  <key>CFBundleIconFile</key>        <string>AppIcon</string>
  <key>LSMinimumSystemVersion</key>  <string>13.0</string>
  <key>LSUIElement</key>             <true/>
</dict>
</plist>
EOF

# Ad-hoc sign with sandbox entitlements + hardened runtime. Not a Developer ID
# signature, so users still clear Gatekeeper once — see README.
codesign --force --options runtime --entitlements "$ENTITLEMENTS" --sign - "$APP"

echo "Done: $APP"

# --- Disk image: styled drag-to-install DMG (stock hdiutil + Finder only). ---
# Cream background with an arrow, Boo on the left, Applications on the right.
echo "Building $DMG…"
VOL="Boo"

# Cream background art with the arrow (see Scripts/make-dmg-bg.swift for layout).
BG="$(mktemp -d)/background.png"
swift Scripts/make-dmg-bg.swift "$BG"

# Detach a leftover image volume; hdiutil info lists only disk images,
# so a real disk named "Boo" is never touched.
if [ -d "/Volumes/$VOL" ] && hdiutil info | grep -q "/Volumes/$VOL"; then
  hdiutil detach "/Volumes/$VOL" >/dev/null 2>&1 || true
fi

# Writable image, sized to the app plus slack, then populate it.
SIZE_MB=$(( $(du -sm "$APP" | cut -f1) + 30 ))
RW="$(mktemp -d)/boo-rw.dmg"
hdiutil create -volname "$VOL" -size "${SIZE_MB}m" -fs HFS+ -ov "$RW" >/dev/null
MP="$(hdiutil attach "$RW" -nobrowse -noverify -noautoopen | grep -o '/Volumes/.*' | tail -1)"

cp -R "$APP" "$MP/"
ln -s /Applications "$MP/Applications"
mkdir "$MP/.background"
cp "$BG" "$MP/.background/background.png"

# Style the window; best effort — without Automation permission the DMG
# still works, just unstyled.
osascript <<OSA >/dev/null 2>&1 || echo "  (window styling skipped — DMG still works)"
tell application "Finder"
  tell disk "$VOL"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {300, 140, 960, 560}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 128
    set text size of viewOptions to 13
    set background picture of viewOptions to file ".background:background.png"
    set position of item "Boo.app" of container window to {175, 195}
    set position of item "Applications" of container window to {485, 195}
    update without registering applications
    delay 1
    close
  end tell
end tell
OSA

sync
hdiutil detach "$MP" >/dev/null 2>&1 || true

# Compress to the final read-only image.
rm -f "$DMG"
hdiutil convert "$RW" -format UDZO -imagekey zlib-level=9 -o "$DMG" >/dev/null
rm -f "$RW"

echo "Done: $DMG (v$VERSION)"
echo "Open the DMG and drag Boo into Applications."
