# Saved workflows

## `video_ltx2_5_t2v.fixed.json`

The official bundled "Text to Video (LTX-2.5)" template
(`video_ltx2_5_t2v`), with the `prompt_enhance_model` fixed so it loads
without a missing-model error.

**Problem:** the template's `prompt_enhance` toggle defaults on and points
`prompt_enhance_model` at `gemma4_e2b_it_int8_convrot.safetensors`, a small
Gemma variant meant for auto-expanding short prompts. That file has no
resolvable source anywhere — confirmed via direct HF repo listing
(`Lightricks/LTX-2.5`), broad HF search, and ComfyUI-Manager's own
`model-list.json` registry (only two Gemma4 entries exist for LTX-2.5, both
already the 12B main text encoder, neither this one). It doesn't even
appear as a selectable option in the node's own dropdown — only real files
present on disk do.

**Fix applied here:**
- `prompt_enhance` toggled **off**.
- `prompt_enhance_model` pointed at the real 12B Gemma text encoder
  (`gemma4-12b-with-proj-ltx-2.5-comfy-int8-convrot.safetensors`, the same
  file already used for `clip_name`) purely to satisfy the combo widget's
  required-selection validation — inert at runtime since the toggle is off.

Clears both the "Missing Models" panel error and the accompanying "Invalid
input — clip_name_1" error, and the workflow runs end-to-end. Load this
file directly in ComfyUI (drag onto the canvas, or Workflows > Open) instead
of the stock template to skip re-doing this fix each time.

See the main README's LTX-2.5 section and
[`minimax-h3-apple-silicon`](https://github.com/seungjulee/minimax-h3-apple-silicon)
for the earlier investigation that first confirmed this file's absence
(that investigation used a hand-built API graph skipping the prompt-rewriter
cluster entirely; this fixed template takes the simpler route of just
disabling the toggle in the newer all-in-one node).
