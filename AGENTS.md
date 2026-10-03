# AGENTS.md

Local-build ZMK firmware repo for a Corne (nice!nano v2 / nRF52840). This is **not** the
ZMK source — it holds the keymap/config plus scripts that drive a west workspace.

## Layout

- `config/corne.conf` — Kconfig (pointing, sleep, OLED)
- `config/corne_left.keymap` — **single source of truth**; `config/corne_right.keymap` is a symlink to it
- `build.sh`, `flash.sh`, `check-keymap.py` — the only real code
- `app/`, `sdk/`, `.venv/`, `build/` are **gitignored**; re-create them via README setup
- west workspace topdir is `app/`, ZMK source is `app/app/`, Zephyr at `app/zephyr/`

## Commands

```bash
./build.sh all|left|right    # -> app/app/build/<half>/zephyr/zmk.uf2
./flash.sh [left|right|all] [--no-build]   # interactive, serial-matched UF2 flash
python3 check-keymap.py [path]             # default config/corne_left.keymap
```

After any keymap edit, run `python3 check-keymap.py` — it is the only verification step
(no tests/lint). Exit 0 prints `SEMUA COCOK`.

## Non-obvious build constraints

- Zephyr's `FindZephyr-sdk.cmake` breaks on cmake 4. `build.sh` prepends `.venv/bin`
  (cmake 3) to `PATH`; never invoke system `cmake` directly.
- `ZEPHYR_SDK_INSTALL_DIR` is auto-detected from `./sdk` (or `sdk/zephyr-sdk-*`).
  The SDK has absolute paths baked in at install time — **never `mv` it**, reinstall.
- `.venv/bin/wget` is a curl shim; `.venv/bin/west` is the required west.
- Builds use `-p` (pristine); config/snippet changes won't stick otherwise.
- Board id is `nice_nano//zmk` even though the hardware is a nice!nano v2; don't "fix" it
  to `nice_nano_v2`.
- Studio snippet (`studio-rpc-usb-uart` + `CONFIG_ZMK_STUDIO=y`) is added **only for the
  left/central half** by `build.sh`.

## Keymap rules

- 4 layers, 42 keys each, rows are 12/12/12/6 cells: `0` default, `1` lower, `2` raise,
  `3` mouse. Keymap executes on the central/left half; both halves are still built.
- `check-keymap.py` matches the `// | ... |` comment diagram cell-for-cell against the
  `bindings` rows using a hardcoded `MAP`. A **new cell label needs a new `MAP` entry**,
  otherwise it defaults to `&trans` and mismatches.
- Mouse bindings need `CONFIG_ZMK_POINTING=y` (already set): `&mkp` click, `&mmv` move,
  `&msc` scroll. Define `ZMK_POINTING_DEFAULT_MOVE_VAL` **before** including `pointing.h`.

## Hardware / flashing

- `flash.sh` tells halves apart by USB serial constants (`LEFT_SERIAL`, `RIGHT_SERIAL`)
  and the bootloader volume label `NICENANO`. Update the constants for a different board.
- Bootloader: double-tap reset, or hold reset while plugging USB.
- Needs udev rule for `0483:df11` (UF2 write) and `uucp` group (ZMK Studio serial).

## Gotcha

ZMK Studio stores the keymap in device NVS. After Studio is used, edits to
`config/*.keymap` are invisible until **Restore Stock Settings** in Studio; flashing a UF2
does not clear settings.
