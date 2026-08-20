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

## What's pinned

| Component | Source | Pin |
|---|---|---|
| ComfyUI core | `comfyanonymous/ComfyUI` | `v0.33.3` |
| `ComfyUI-MiniMax-H3-Turbo` | **fork**: `seungjulee/ComfyUI-MiniMax-H3-Turbo` | branch `apple-silicon-m5-verified` — MPS NaN fix applied on top of upstream |
| `ComfyUI-AppleSilicon-FP8` | `pawel-mazurkiewicz/ComfyUI-AppleSilicon-FP8` | `911294c` (unmodified) |
| `ComfyUI-SolAttn-MPS` | `yshenaw/ComfyUI-SolAttn-MPS` | `886f4b9` (unmodified) — opt-in attention accelerator, not wired into any workflow by default |

`git submodule status` is the source of truth if this table goes stale.

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
