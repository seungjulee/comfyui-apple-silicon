#!/usr/bin/env bash
# =============================================================================
# Reproduce this exact ComfyUI + custom-node stack from scratch.
#
# Everything is pinned via git submodules (see `git submodule status`), so
# this script only needs to: create a venv, install deps, and fetch models.
# It does NOT touch anything outside this directory.
#
#   git clone --recurse-submodules https://github.com/seungjulee/comfyui-apple-silicon.git
#   cd comfyui-apple-silicon
#   ./bootstrap.sh
#
# If you cloned without --recurse-submodules:
#   git submodule update --init --recursive
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"

step(){ printf "\n\033[1;36m==> %s\033[0m\n" "$1"; }
ok(){   printf "    \033[32m%s\033[0m\n" "$1"; }
die(){  printf "\n\033[31mERROR: %s\033[0m\n" "$1" >&2; exit 1; }

[[ "$(uname -m)" == "arm64" ]] || die "Apple Silicon only."
command -v brew >/dev/null 2>&1 || die "Homebrew required: https://brew.sh"

step "Submodules"
git submodule update --init --recursive
ok "ComfyUI + 3 custom nodes checked out at pinned commits"

step "Prerequisites (python@3.12, ffmpeg)"
for pkg in python@3.12 ffmpeg; do
  brew list --versions "$pkg" >/dev/null 2>&1 || brew install "$pkg"
done
PY312="$(brew --prefix python@3.12)/libexec/bin/python3"

step "Python environment"
[[ -d ComfyUI/venv ]] || "$PY312" -m venv ComfyUI/venv
# shellcheck disable=SC1091
source ComfyUI/venv/bin/activate
pip install --quiet --upgrade pip
pip install --quiet torch torchvision torchaudio
python -c "import torch,sys; sys.exit(0 if torch.backends.mps.is_available() else 1)" \
  || die "MPS unavailable in this torch build"
pip install --quiet -r ComfyUI/requirements.txt
pip install --quiet -r custom_nodes/ComfyUI-AppleSilicon-FP8/requirements.txt
pip install --quiet huggingface_hub
ok "environment ready"

step "Models"
echo "    Not fetched automatically -- see models/MANIFEST.md for exact files"
echo "    and download commands per model family (H3 / Music3 / LTX-2.5)."

step "Done"
cat <<EOF

Start it with:
  cd $(pwd)/ComfyUI && source venv/bin/activate
  python main.py --listen 127.0.0.1 --port 8188

Verify the AppleSilicon-FP8 node loaded (needed for INT8 checkpoints on MPS):
  grep "AppleSilicon-FP8. capabilities" <your comfyui log>
EOF
