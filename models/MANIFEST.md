# Model manifest

Weights are never committed here (licensed, and far too large for git). This
lists exactly what's in use and where it comes from, so the working set is
reproducible without guessing.

## MiniMax H3 (video)

Source: [`Comfy-Org/MiniMax-H3`](https://huggingface.co/Comfy-Org/MiniMax-H3)

```
diffusion_models/minimax_h3_fl2va_pruned_int8_convrot.safetensors   19.5 GB
text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors          14.6 GB
vae/minimax_h3_video_vae_fp16.safetensors                            5.2 GB
vae/minimax_h3_audio_vae_fp32.safetensors                            0.6 GB
loras/minimax_h3_turbo_v4_step600_ema.safetensors                    0.7 GB
```

```bash
hf download Comfy-Org/MiniMax-H3 \
  diffusion_models/minimax_h3_fl2va_pruned_int8_convrot.safetensors \
  text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors \
  vae/minimax_h3_video_vae_fp16.safetensors \
  vae/minimax_h3_audio_vae_fp32.safetensors \
  --local-dir ComfyUI/models
hf download larryvrh/MiniMax-H3-Turbo-Lora minimax_h3_turbo_v4_step600_ema.safetensors \
  --local-dir ComfyUI/models/loras
```

INT8 needs `ComfyUI-AppleSilicon-FP8` loaded (pinned submodule) — without it,
`torch._int_mm` is unimplemented on MPS and this fails in ~5s. See
[Comfy-Org/comfy-kitchen#107](https://github.com/Comfy-Org/comfy-kitchen/pull/107)
for the upstream fix in progress (verified working on M1 Max + M5 Max, still
unmerged as of writing — see the sibling `minimax-h3-apple-silicon` repo).

LoRA: apply the fix in this repo's pinned `ComfyUI-MiniMax-H3-Turbo` submodule
(branch `apple-silicon-m5-verified`) — the LoRA produces NaN/black frames on
MPS otherwise. Full writeup:
[Larryvrh/ComfyUI-MiniMax-H3-Turbo#26](https://github.com/Larryvrh/ComfyUI-MiniMax-H3-Turbo/pull/26).

## MiniMax Music3 (music)

Source: [`Comfy-Org/MiniMax-Music-3`](https://huggingface.co/Comfy-Org/MiniMax-Music-3)

```
diffusion_models/minimax_music3_dit_fp16.safetensors           4.9 GB
text_encoders/minimax_music3_text_encoder_bf16.safetensors    18.5 GB
vae/minimax_music3_dav.safetensors                              0.2 GB
```

```bash
hf download Comfy-Org/MiniMax-Music-3 \
  diffusion_models/minimax_music3_dit_fp16.safetensors \
  text_encoders/minimax_music3_text_encoder_bf16.safetensors \
  vae/minimax_music3_dav.safetensors \
  --local-dir ComfyUI/models
```

**Deliberately fp16/bf16, not the `int8_convrot` variants** the official
template defaults to. Same reasoning as H3 — quantized paths are exactly
where MPS bugs concentrate, and there's no memory pressure on 128GB to
justify the risk. See `scripts/music3/` in the `minimax-h3-apple-silicon`
repo for working render scripts; note `SaveAudioAdvanced` needs
`format.quality` as a nested key, not a flat `quality` field.

Measured (M5 Max, 30s audio, 30 steps): 185–235s per track.

## LTX-2.5 (video + audio)

Source: [`Lightricks/LTX-2.5`](https://huggingface.co/Lightricks/LTX-2.5)
— **gated**, requires accepting the license on the HF page before `hf
download` will work (`ltx-2-community-license-agreement`).

Recommended for this stack (int8, not fp8 — LTX-2.5 has no fp8 build, and
int8 is the variant least likely to hit MPS dtype walls; needs
`ComfyUI-AppleSilicon-FP8` same as H3's int8):

```
diffusion_models/ltx-2.5-22b-distilled-transformer-comfy-int8-convrot.safetensors   21.5 GB
text_encoders/gemma4-12b-with-proj-ltx-2.5-comfy-int8-convrot.safetensors           15.4 GB
vae/ltx-2.5-video-vae-bf16.safetensors                                               1.5 GB
vae/ltx-2.5-audio-vae-bf16.safetensors                                              0.37 GB
latent_upscale_models/ltx-2.5-latent-spatial-upscaler-x2-bf16-1.0.safetensors        1.0 GB  # 2nd sampling stage
```

Deliberately **not** listing `gemma4_e2b_it_int8_convrot.safetensors` (the
bundled template's prompt-rewriter text encoder) here — see below, it has no
resolvable source and isn't needed.

```bash
hf download Lightricks/LTX-2.5 \
  diffusion_models/ltx-2.5-22b-distilled-transformer-comfy-int8-convrot.safetensors \
  text_encoders/gemma4-12b-with-proj-ltx-2.5-comfy-int8-convrot.safetensors \
  vae/ltx-2.5-video-vae-bf16.safetensors \
  vae/ltx-2.5-audio-vae-bf16.safetensors \
  latent_upscale_models/ltx-2.5-latent-spatial-upscaler-x2-bf16-1.0.safetensors \
  --local-dir ComfyUI/models
```

**`gemma4_e2b_it_int8_convrot.safetensors` has no resolvable source anywhere**:
not in `Lightricks/LTX-2.5`, no `Comfy-Org/ltx-2.5` repo exists, not findable
via HF search, not in ComfyUI-Manager's own `model-list.json` registry, and
ComfyUI's own "Download" button for it silently no-ops without a Comfy.org
login. It's the model behind the bundled template's `prompt_enhance` toggle
(auto-expands short prompts) — skippable, not load-bearing. Two working
fixes, matching the two template generations currently in circulation:

- **Official template** (`workflow-templates` ≥ 0.11.44 ships this as a
  single packed `Text to Video (LTX-2.5)` node): load
  [`workflows/video_ltx2_5_t2v.fixed.json`](../workflows/video_ltx2_5_t2v.fixed.json)
  instead of the stock template — `prompt_enhance` toggled off,
  `prompt_enhance_model` pointed at the real 12B Gemma encoder (inert, just
  satisfies the combo widget's required-selection validation). See
  [`workflows/README.md`](../workflows/README.md) for how that fix was
  found.
- **Hand-built graph** (older, exploded-node template shape —
  `LTXVDualCFGGuider` + `ManualSigmas` for the base pass,
  `LTXVLatentUpsampler` + a second sampling pass for the upscale, separate
  video/audio latents joined via `LTXVConcatAVLatent`/`LTXVSeparateAVLatent`):
  `minimax-h3-apple-silicon/scripts/ltx25/ltx25.py` wires the prompt
  directly into `CLIPTextEncode`, bypassing the rewriter node cluster
  entirely. **Confirmed working, M5 Max: 512x256/2s render in 90s, first
  attempt.**

Either way, ComfyUI's "Missing Models" panel (Workflow Overview → Errors) is
the reliable way to catch a template's actual model requirements — more
reliable than hand-reading the template JSON, and what caught this in the
first place.

**Requires ComfyUI core commit `bd34f338`** ("Fix float64 device in ltx
diffusion decoder", merged 2026-08-12) or the VAE decoder crashes on MPS —
confirmed reported specifically on M5 hardware
([HF discussion](https://huggingface.co/Lightricks/LTX-2.5/discussions/10)).
Already included in this repo's pinned `v0.33.3` ComfyUI submodule; verify
with `git -C ComfyUI merge-base --is-ancestor bd34f338 HEAD` before assuming
a future re-pin still has it.

**Use the local Gemma text encoder node, not `GemmaAPITextEncode`** — the API
path is broken for all LTX-2.5 checkpoints as of
[issue #549](https://github.com/Lightricks/ComfyUI-LTXVideo/issues/549)
(missing metadata key upstream models no longer carry).

No official Comfy-Org repack exists yet (unlike H3/Music3) — weights come
straight from Lightricks' gated repo.
