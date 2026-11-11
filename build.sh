#!/bin/bash
# Builds Tuckbar.app into ./build. Pass "install" to also copy it to /Applications and launch it.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP=build/Tuckbar.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Tuckbar "$APP/Contents/MacOS/Tuckbar"
cp Resources/Info.plist "$APP/Contents/Info.plist"

if [ ! -f Resources/AppIcon.icns ]; then
    echo "Generating icon…"
    tmp=$(mktemp -d)
    swift Scripts/make_icon.swift "$tmp/icon.png"
    set_dir="$tmp/AppIcon.iconset"
    mkdir "$set_dir"
    for s in 16 32 128 256 512; do
        sips -z $s $s "$tmp/icon.png" --out "$set_dir/icon_${s}x${s}.png" >/dev/null
        sips -z $((s * 2)) $((s * 2)) "$tmp/icon.png" --out "$set_dir/icon_${s}x${s}@2x.png" >/dev/null
    done
    iconutil -c icns "$set_dir" -o Resources/AppIcon.icns
    rm -rf "$tmp"
fi
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# Tuckbar asks for no permissions, so an ad-hoc signature is enough.
codesign --force --sign - "$APP"
echo "Built $APP"

if [ "${1:-}" = "install" ]; then
    pkill -x Tuckbar 2>/dev/null || true
    rm -rf /Applications/Tuckbar.app
    cp -R "$APP" /Applications/
    open /Applications/Tuckbar.app
    echo "Installed to /Applications/Tuckbar.app"
fi
