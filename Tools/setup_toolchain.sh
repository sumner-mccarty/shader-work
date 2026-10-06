#!/usr/bin/env bash
# slrender toolchain for Linux (cloud workers, CI) and macOS. Idempotent: a re-run with everything
# in place does nothing but the final self-check, so it is safe as a session-start hook.
#
#   Tools/setup_toolchain.sh            # install what's missing, then `slrender doctor --software`
#   Tools/setup_toolchain.sh --check    # only the self-check
#
# Installs into <repo>/.toolchain (gitignored):
#   dxc          Microsoft's release build (pinned + sha256-verified, Tools/toolchain.json)
#   spirv-cross  built from the pinned Khronos tag (needs cmake + a C++ compiler), else PATH
# and, where it can (root or passwordless sudo, apt), the OS pieces for headless GL:
#   Mesa llvmpipe + EGL (libegl1 libgl1 libegl-mesa0 libgl1-mesa-dri), cmake, g++.
set -euo pipefail
case "$(uname -s)" in
  Linux|Darwin) ;;
  *) echo "[slrender-setup] not Linux/macOS — on Windows use: powershell -ExecutionPolicy Bypass -File Tools/setup_toolchain.ps1"; exit 0 ;;
esac

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TC="$REPO/.toolchain"
MANIFEST="$REPO/Tools/toolchain.json"
PY="${PYTHON:-python3}"
mkdir -p "$TC/bin"

j() { "$PY" -c "import json,sys; d=json.load(open('$MANIFEST')); print(eval('d' + sys.argv[1]))" "$1"; }
log() { printf '[slrender-setup] %s\n' "$*"; }

if [[ "${1:-}" != "--check" ]]; then
  # ── OS packages ───────────────────────────────────────────────────────────
  if command -v apt-get >/dev/null 2>&1; then
    SUDO=""
    if [[ $(id -u) -ne 0 ]]; then
      if sudo -n true 2>/dev/null; then SUDO="sudo -n"; else SUDO="__none__"; fi
    fi
    need=()
    for pkg in libegl1 libgl1 libegl-mesa0 libgl1-mesa-dri cmake g++ git curl; do
      dpkg -s "$pkg" >/dev/null 2>&1 || need+=("$pkg")
    done
    if [[ ${#need[@]} -gt 0 ]]; then
      if [[ "$SUDO" == "__none__" ]]; then
        log "missing OS packages (no root/sudo, install them yourself): ${need[*]}"
      else
        log "apt-get install ${need[*]}"
        $SUDO apt-get update -qq || true
        DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq --no-install-recommends "${need[@]}" >/dev/null
      fi
    fi
  fi

  # ── dxc ───────────────────────────────────────────────────────────────────
  if [[ ! -x "$TC/dxc/bin/dxc" ]] && [[ "$(uname -s)" == "Linux" ]]; then
    tag=$(j "['dxc']['tag']"); asset=$(j "['dxc']['linux']['asset']"); sum=$(j "['dxc']['linux']['sha256']")
    log "dxc $tag"
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/dxc.tgz" "https://github.com/microsoft/DirectXShaderCompiler/releases/download/$tag/$asset"
    echo "$sum  $tmp/dxc.tgz" | sha256sum -c - >/dev/null || { log "dxc checksum mismatch"; exit 1; }
    rm -rf "$TC/dxc" && mkdir -p "$TC/dxc"
    tar -xzf "$tmp/dxc.tgz" -C "$TC/dxc"
    chmod +x "$TC/dxc/bin/dxc"
    rm -rf "$tmp"
  fi
  if [[ ! -x "$TC/dxc/bin/dxc" ]] && ! command -v dxc >/dev/null 2>&1; then
    log "no dxc for $(uname -s): install DirectXShaderCompiler (e.g. from the Vulkan SDK) or set SLRENDER_DXC"
  fi

  # ── spirv-cross ───────────────────────────────────────────────────────────
  if [[ ! -x "$TC/bin/spirv-cross" ]]; then
    tag=$(j "['spirv_cross']['tag']"); repo=$(j "['spirv_cross']['repo']")
    if command -v cmake >/dev/null 2>&1 && command -v c++ >/dev/null 2>&1; then
      log "building spirv-cross $tag"
      src="$TC/spirv-cross-src"
      [[ -d "$src/.git" ]] || git clone -q --depth 1 --branch "$tag" "$repo" "$src"
      cmake -S "$src" -B "$src/build" -DCMAKE_BUILD_TYPE=Release -DSPIRV_CROSS_ENABLE_TESTS=OFF \
            -DSPIRV_CROSS_SHARED=OFF -DSPIRV_CROSS_STATIC=ON -DSPIRV_CROSS_CLI=ON >/dev/null
      cmake --build "$src/build" --target spirv-cross -j "$(nproc 2>/dev/null || echo 4)" >/dev/null
      cp "$src/build/spirv-cross" "$TC/bin/spirv-cross"
    elif command -v spirv-cross >/dev/null 2>&1; then
      log "using system spirv-cross ($(command -v spirv-cross)) — not the pinned build"
    else
      log "spirv-cross missing and cannot be built (need cmake + c++)"
    fi
  fi

  # ── python ────────────────────────────────────────────────────────────────
  if ! "$PY" -c "import moderngl, numpy, PIL" 2>/dev/null; then
    log "pip install moderngl numpy pillow"
    "$PY" -m pip install -q $("$PY" -c "import json; print(' '.join(json.load(open('$MANIFEST'))['python']))") \
      || "$PY" -m pip install -q --break-system-packages \
           $("$PY" -c "import json; print(' '.join(json.load(open('$MANIFEST'))['python']))")
  fi
fi

# ── self-check: compile + render through Mesa llvmpipe ───────────────────────
cd "$REPO"
"$PY" -m slrender --software doctor
