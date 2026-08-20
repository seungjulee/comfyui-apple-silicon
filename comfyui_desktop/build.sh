#!/bin/bash
# Builds and installs ComfyUI.app — a native macOS shell around the ComfyUI
# install at ~/ComfyUI. Launching it starts the server in a real window;
# quitting it (Cmd+Q, red-dot close, or Force Quit) terminates the server
# process and unloads all model memory.
set -euo pipefail
cd "$(dirname "$0")"

APP=/Applications/ComfyUI.app
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

echo "Compiling main.swift..."
swiftc -O main.swift -o "$BUILD_DIR/ComfyUI" -framework Cocoa -framework WebKit

echo "Assembling app bundle at $APP..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BUILD_DIR/ComfyUI" "$APP/Contents/MacOS/ComfyUI"
cp Info.plist "$APP/Contents/Info.plist"
cp appIcon.icns "$APP/Contents/Resources/appIcon.icns"
chmod +x "$APP/Contents/MacOS/ComfyUI"

echo "Ad-hoc codesigning..."
codesign --force --deep --sign - "$APP"

echo "Done. Verify:"
echo "  file $APP/Contents/MacOS/ComfyUI   # should say Mach-O, not a script"
echo "  open $APP"
