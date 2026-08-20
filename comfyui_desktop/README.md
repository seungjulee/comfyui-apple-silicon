# ComfyUI.app

A small native macOS shell (Swift/AppKit + WKWebView) around the ComfyUI
install at `~/ComfyUI`. It uses that install's existing venv, custom nodes,
and models as-is — this is a launcher, not a bundled/self-contained
ComfyUI Desktop.

- **Launch**: starts `~/ComfyUI`'s server (or reuses one already running)
  and shows it in a real window — no browser tab needed.
- **Quit** (Cmd+Q, red-dot close, or Force Quit): terminates the server
  process (SIGTERM, 5s grace, then SIGKILL) and unloads all model memory.

## Build / install

```bash
./build.sh
```

Compiles `main.swift`, assembles the bundle, and installs it to
`/Applications/ComfyUI.app`, overwriting any existing copy there.

Requires Xcode Command Line Tools (`swiftc`, `codesign`) — already present
on any Mac that's built anything with `clang`/`swift`.

## Files

- `main.swift` — the app. Server lifecycle, WKWebView window, and a menu
  bar with shortcuts to the log, models folder, output folder, and
  reload/zoom.
- `Info.plist` — bundle metadata (`local.comfyui.launcher`).
- `appIcon.icns` — app icon.

## Why this exists instead of just using a browser tab

Mainly for clean start/stop: quitting a browser tab doesn't kill the
ComfyUI server process behind it, so the ~30-40GB of resident model
weights stay loaded until you go find and kill the process by hand. This
wraps that lifecycle into a normal "quit the app" gesture.

## Known gotcha

An earlier version of this bundle shipped with a bash-script placeholder
as `Contents/MacOS/ComfyUI` instead of the compiled binary (the script
started the server fine but had no real GUI process, so quitting the app
didn't stop it). If `/Applications/ComfyUI.app` predates this repo's
`comfyui_desktop/` directory, rebuild it with `./build.sh` — `file
/Applications/ComfyUI.app/Contents/MacOS/ComfyUI` should say `Mach-O`, not
`Bourne-Again shell script`.
