#!/usr/bin/env bash
# Builds ClaudeNotify.app. Usage: build.sh <output-dir> [icon-image]
# The icon image (png/jpg/icns) becomes the app icon shown on every notification.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
out="${1:?output dir}"; icon="${2:-}"
app="$out/ClaudeNotify.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
swiftc -O -o "$app/Contents/MacOS/ClaudeNotify" "$here/main.swift"
cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>dev.aguacatecontreras.claude-notify</string>
  <key>CFBundleName</key><string>ClaudeNotify</string>
  <key>CFBundleDisplayName</key><string>Claude Code</string>
  <key>CFBundleExecutable</key><string>ClaudeNotify</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSUIElement</key><true/>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
</dict></plist>
PLIST
if [[ -n "$icon" && -f "$icon" ]]; then
  if [[ "$icon" == *.icns ]]; then
    cp "$icon" "$app/Contents/Resources/AppIcon.icns"
  else
    set_dir="$(mktemp -d)/AppIcon.iconset"; mkdir -p "$set_dir"
    for s in 16 32 128 256 512; do
      sips -s format png -z $s $s "$icon" --out "$set_dir/icon_${s}x${s}.png" >/dev/null
      sips -s format png -z $((s*2)) $((s*2)) "$icon" --out "$set_dir/icon_${s}x${s}@2x.png" >/dev/null
    done
    iconutil -c icns "$set_dir" -o "$app/Contents/Resources/AppIcon.icns"
  fi
fi
# Bundle the system sounds so the notification itself can play them.
cp /System/Library/Sounds/*.aiff "$app/Contents/Resources/" 2>/dev/null || true
codesign --force --sign - "$app" >/dev/null 2>&1
# Make LaunchServices pick up the new icon/name.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app" >/dev/null 2>&1 || true
echo "$app"
