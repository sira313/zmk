#!/usr/bin/env bash
# Build ZMK for both Corne halves (nice!nano v2)
# usage: ./build.sh [left|right|all]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
VENV="$ROOT/.venv"
export PATH="$VENV/bin:$PATH"   # cmake 3 (Zephyr FindZephyr-sdk breaks on cmake 4)
if [ -z "${ZEPHYR_SDK_INSTALL_DIR:-}" ]; then
  for d in "$ROOT/sdk" "$ROOT"/sdk/zephyr-sdk-*; do
    [ -f "$d/cmake/Zephyr-sdkConfig.cmake" ] && { ZEPHYR_SDK_INSTALL_DIR="$d"; break; }
  done
fi
export ZEPHYR_SDK_INSTALL_DIR
cd "$ROOT/app/app"

build() {
  local half=$1
  # ZMK Studio only on central/left half (zmk.dev/docs/features/studio)
  local extra=()
  local studio=""
  if [ "$half" = left ]; then
    extra=(-S studio-rpc-usb-uart)
    studio="-DCONFIG_ZMK_STUDIO=y"
  fi
  west build -p -d "build/$half" -b nice_nano//zmk "${extra[@]}" -- \
    $studio -DSHIELD="corne_$half" -DZMK_CONFIG="$ROOT/config"
  echo "-> $ROOT/app/app/build/$half/zephyr/zmk.uf2"
}

case "${1:-all}" in
  left)  build left ;;
  right) build right ;;
  all)   build left; build right ;;
  *)     echo "usage: $0 [left|right|all]"; exit 1 ;;
esac