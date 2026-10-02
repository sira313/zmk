#!/usr/bin/env bash
#
# Build + flash Corne (nice!nano v2, UF2 mass storage), interaktif.
#
#   ./flash.sh                # build kedua half lalu flash kiri & kanan
#   ./flash.sh left           # hanya kiri
#   ./flash.sh --no-build     # pakai build terakhir, langsung flash
#
# Butuh: udev rule untuk RPI-RP2 (0483:df11) + user di grup uucp.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

# serial USB tiap half (dari lsusb saat device dalam mode app)
LEFT_SERIAL="7F5CD247CF72BAF0"
RIGHT_SERIAL="7336F183FB24A382"

target="all"
do_build=1
WAIT_TIMEOUT="${WAIT_TIMEOUT:-180}"
for arg in "$@"; do
    case "$arg" in
        left|right|all) target="$arg" ;;
        --no-build) do_build=0 ;;
        -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
        *) echo "argumen tidak dikenal: $arg"; exit 1 ;;
    esac
done
halves=(left right)
[ "$target" != all ] && halves=("$target")

serial_of() { [ "$1" = left ] && echo "$LEFT_SERIAL" || echo "$RIGHT_SERIAL"; }
uf2_of()    { echo "$ROOT/app/app/build/$1/zephyr/zmk.uf2"; }
volume_of() { lsblk -ndo NAME,LABEL,SERIAL | awk -v s="$1" '$2=="NICENANO" && $3==s {print "/dev/"$1}'; }
wait_gone() { sleep 3; udevadm settle; [ -z "$(volume_of "$1")" ]; }

wait_half() { # $1 = half
    local want other got timeout=0
    if [ "$1" = left ]; then want="$LEFT_SERIAL"; other="$RIGHT_SERIAL"; else want="$RIGHT_SERIAL"; other="$LEFT_SERIAL"; fi
    printf '  menunggu half %s (serial %s) masuk bootloader' "$1" "$want"
    while (( timeout < WAIT_TIMEOUT )); do
        got="$(volume_of "$want")"
        [ -n "$got" ] && { echo " OK"; return 0; }
        [ -n "$(volume_of "$other")" ] && { echo " X"; echo "  bootloader yang terdeteksi = half LAIN"; return 1; }
        printf '.'; sleep 2; ((timeout += 2))
    done
    echo " X"; echo "  timeout: half $1 tidak pernah muncul"; return 1
}

if (( do_build )); then
    echo "== build $( [ "$target" = all ] && echo 'kedua half' || echo "$target" )"
    "$ROOT/build.sh" "$target" | grep -E '^-> |error|Error' || true
fi

for half in "${halves[@]}"; do
    echo "== flash half $half"
    read -r -p "   masukkan half $half ke bootloader (double-tap reset, atau tahan reset + colok). Enter untuk lanjut... " _ || true
    wait_half "$half" || { echo "gagal menunggu $half"; exit 1; }

    dev="$(volume_of "$(serial_of "$half")")"
    mnt="$(udisksctl mount -b "$dev" | sed -n 's/.* at \(.*\)/\1/p')"
    cp "$(uf2_of "$half")" "$mnt/" && echo "   $half: $(basename "$(uf2_of "$half")") ditulis ke $mnt"

    for _ in $(seq 30); do wait_gone "$(serial_of "$half")" && break; sleep 1; done
    udevadm settle
    echo "   $half selesai, device reboot ke mode app"
done

echo "== selesai"