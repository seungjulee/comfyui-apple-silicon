# comfyui-apple-silicon

My working ComfyUI stack for Apple Silicon — pinned via git submodules so it's
a real, forkable environment rather than a pile of instructions that drift out
of date. Currently running H3 (video), Music3 (music), and setting up LTX-2.5.

Bug reports, PR writeups, and one-off verification scripts live in the sibling
[`minimax-h3-apple-silicon`](https://github.com/seungjulee/minimax-h3-apple-silicon)
repo — this repo is the environment itself, not the investigation history.

## Quick start

```bash
git clone --recurse-submodules https://github.com/seungjulee/comfyui-apple-silicon.git
cd comfyui-apple-silicon
./bootstrap.sh
```

Then fetch whatever models you need — see [`models/MANIFEST.md`](models/MANIFEST.md).

Optionally build [`ComfyUI.app`](comfyui_desktop/) — a native launcher so
you can start/stop the server (and free its model memory) by opening and
quitting a normal macOS app instead of managing the process by hand:

```bash
cd comfyui_desktop && ./build.sh
```

## What's pinned

| Component | Source | Pin |
|---|---|---|
| ComfyUI core | `comfyanonymous/ComfyUI` | `v0.33.3` |
| `ComfyUI-MiniMax-H3-Turbo` | **fork**: `seungjulee/ComfyUI-MiniMax-H3-Turbo` | branch `apple-silicon-m5-verified` — MPS NaN fix applied on top of upstream |
| `ComfyUI-AppleSilicon-FP8` | `pawel-mazurkiewicz/ComfyUI-AppleSilicon-FP8` | `911294c` (unmodified) |
| `ComfyUI-SolAttn-MPS` | `yshenaw/ComfyUI-SolAttn-MPS` | `886f4b9` (unmodified) — opt-in attention accelerator, not wired into any workflow by default |
| `ComfyUI-Manager` | `Comfy-Org/ComfyUI-Manager` | `f39cbd56` (V3.41, unmodified) — see below |

### ComfyUI-Manager

The standard tool for this. Adds a UI (gear icon in the top bar, or `Manager`
in the node-graph right-click menu) for:

- **Custom nodes**: browse/install/update/disable from a curated registry,
  without hand-cloning + pinning like the rest of this repo does. Also flags
  nodes with known security issues (it already runs a "security hold"
  process — see its own commit history for examples).
- **Models**: a curated `model-list.json` registry mapping friendly names to
  their real download URLs and target folders — this is what confirmed the
  LTX-2.5 prompt-rewriter file has no real source anywhere (see
  `models/MANIFEST.md`): Manager's own registry doesn't list it either, only
  the two 12B text encoder variants we already use.
- **Snapshots**: save/restore the exact set of installed custom nodes + their
  versions as a JSON file — a lighter-weight alternative to this repo's
  submodule pinning, scoped to custom nodes only (doesn't cover ComfyUI core
  or models).
- **Missing-model resolution** from a loaded workflow, similar to ComfyUI
  core's own "Missing Models" panel but backed by Manager's registry instead
  of requiring a Comfy.org login.

Not currently used for anything beyond being installed — the four other nodes
here are managed manually via submodules, which is more precise for a pinned,
reproducible environment. Reach for Manager's UI for one-off exploration
(“what nodes exist for X”, “is there a known download URL for Y model”)
rather than as the source of truth for what's actually pinned in this repo.

`git submodule status` is the source of truth if this table goes stale.

### Non-submodule pins (pip)

| Package | Pinned by core (`requirements.txt`) | Actually installed |
|---|---|---|
| `comfyui-frontend-package` | `1.49.6` | `1.50.6` |
| `comfyui-workflow-templates` | `0.11.44` | `0.11.44` |
| `comfy-kitchen` | `0.2.31` | `0.2.31` |

The frontend package is intentionally run ahead of core's own pin — core
doesn't enforce the version at runtime (it just reports a mismatch in
`/system_stats`), and there's no reason to sit on an older UI build.
`pip install --upgrade comfyui-frontend-package` in the venv to match this.

## Why a fork for the Turbo node

The Turbo LoRA produces NaN/black frames on MPS with a pruned base — root
cause and fix are in
[Larryvrh/ComfyUI-MiniMax-H3-Turbo#26](https://github.com/Larryvrh/ComfyUI-MiniMax-H3-Turbo/pull/26)
(unmerged as of writing, verified on M1 Max + M5 Max). The `#26` PR branch
predates a since-merged upstream fix for an unrelated bug (row-count
mismatch, PR #16), so this repo's `apple-silicon-m5-verified` branch carries
**both** fixes rebased onto current upstream — that's the one to build from,
not `#26` directly, until `#26` merges.

## Known-good vs. known-bad on Apple Silicon

- **INT8 checkpoints** (H3, LTX-2.5) need `ComfyUI-AppleSilicon-FP8` loaded —
  `aten::_int_mm` has no MPS kernel in stock PyTorch. Upstream fix in
  progress: [comfy-kitchen#107](https://github.com/Comfy-Org/comfy-kitchen/pull/107).
- **Turbo LoRA**: fixed by this repo's fork, see above.
- **LTX-2.5 VAE decode**: needs ComfyUI core ≥ `bd34f338` (already in the
  pinned `v0.33.3`) or it crashes with a float64/MPS TypeError — confirmed on
  M5 hardware. Also avoid the `GemmaAPITextEncode` node (broken for all
  LTX-2.5 checkpoints as of [#549](https://github.com/Lightricks/ComfyUI-LTXVideo/issues/549));
  use the local Gemma text encoder instead.
- **Render hangs indefinitely instead of failing**: check `sysctl
  vm.swapusage` before assuming a code regression. A render can sit at 0% CPU
  for 10+ minutes if something else on the machine (another local LLM server,
  browsers) has pushed swap near full — it's resource starvation, not a hang
  in ComfyUI itself. Killing the contending process and restarting usually
  fixes it immediately.

## Updating a pin

```bash
cd custom_nodes/ComfyUI-SolAttn-MPS   # or whichever
git fetch && git checkout <new-commit>
cd ../..
git add custom_nodes/ComfyUI-SolAttn-MPS
git commit -m "Bump ComfyUI-SolAttn-MPS to <short-sha>"
```

## Update log

### 2026-08-20 — Full update pass, native launcher fixed, LTX-2.5 template fix saved

- **Checked everything for updates**: ComfyUI core (`v0.33.3`, already latest
  tag), all four pinned custom nodes (all already at their remotes' latest
  commit on their pinned branch), `comfyui-workflow-templates` (`0.11.44`,
  latest), `comfy-kitchen` (`0.2.31`, latest). Both our upstream PRs
  ([H3-Turbo#26](https://github.com/Larryvrh/ComfyUI-MiniMax-H3-Turbo/pull/26),
  [comfy-kitchen#107](https://github.com/Comfy-Org/comfy-kitchen/pull/107))
  are still open/unmerged, so the fork and `ComfyUI-AppleSilicon-FP8` both
  stay necessary.
- **Bumped `comfyui-frontend-package`**: `1.49.6` → `1.50.6` (only actual
  update available). Verified with a clean boot — all four custom nodes
  loaded with no import errors, `/system_stats` and `/object_info` responded
  correctly, and the graph editor rendered and loaded the LTX-2.5 workflow
  correctly. No full render replay needed since this package only serves the
  UI/JS layer, not the Python execution backend.
- **`comfyui_desktop/` launcher was silently a no-op shell**: `/Applications/ComfyUI.app`
  had a bash-script placeholder as its executable instead of the compiled
  Swift binary (`main.swift` was never actually compiled into the bundle).
  It could start the server but had no real GUI process, so quitting the app
  (or `osascript quit`) didn't kill the server — confirmed by testing: the
  server process survived a quit and kept the port open. Compiled
  `main.swift` with `swiftc -O` and installed the real binary + ad-hoc
  codesigned the bundle. Verified both directions: launch → server up in
  ~6s in a real WKWebView window; quit → server process and port both
  confirmed gone (models fully unloaded from memory).
- **LTX-2.5 official template fixed and saved**: the bundled `Text to Video
  (LTX-2.5)` node's `prompt_enhance` toggle points at the same unresolvable
  `gemma4_e2b_it_int8_convrot.safetensors` file documented in the LTX-2.5
  section above — confirmed again it's not even a selectable option in the
  node's own dropdown (only files actually on disk are). Fix: toggle
  `prompt_enhance` off, point `prompt_enhance_model` at the real 12B Gemma
  encoder already used for `clip_name` (inert since the toggle is off, just
  satisfies the required-selection validation). Saved as
  [`workflows/video_ltx2_5_t2v.fixed.json`](workflows/video_ltx2_5_t2v.fixed.json) —
  load this instead of the stock template to skip re-doing the fix.
