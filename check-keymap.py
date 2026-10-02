#!/usr/bin/env python3
"""
Bandingkan baris comment (`// | ... |`) dengan baris `bindings` di keymap ZMK.

Pakai: python3 check-keymap.py [path]
Exit 0 = semua cocok, 1 = ada sel yang beda.
"""
import re
import sys

MAP = {
    "BSPC": "&kp BSPC", "TAB": "&kp TAB", "SHFT": "&kp LSHFT", "CTRL": "&kp LCTRL",
    "ALT": "&kp LALT", "OPT": "&kp LALT", "MENU": "&kp K_MENU", "GUI": "&kp LGUI", "ENT": "&kp RET", "RSE": "&mo 2",
    "LWR": "&mo 1", "&mo3": "&mo 3", "SPC/ENT": "&mt RET SPACE",
    "CAPS": "&kp CAPS", "DEL": "&kp DEL", "PRTSC": "&kp PRINTSCREEN",
    "BRUP": "&kp C_BRI_UP", "BRDN": "&kp C_BRI_DN",
    "VOLUP": "&kp K_VOL_UP", "VOLDN": "&kp K_VOL_DN",
    "UNLK": "&studio_unlock", "BTCLR": "&bt BT_CLR", "TOG3": "&tog 3",
    "PIPE": "&kp PIPE", "BSLH": "&kp BSLH",
    "LEFT": "&kp LEFT", "RIGHT": "&kp RIGHT", "UP": "&kp UP", "DOWN": "&kp DOWN",
    "LCLK": "&mkp LCLK", "RCLK": "&mkp RCLK",
    "MOVEU": "&mmv MOVE_UP", "MOVEL": "&mmv MOVE_LEFT",
    "MOVED": "&mmv MOVE_DOWN", "MOVER": "&mmv MOVE_RIGHT",
    "SCRLU": "&msc SCRL_UP", "SCRLD": "&msc SCRL_DOWN",
    "SCRLL": "&msc SCRL_LEFT", "SCRLR": "&msc SCRL_RIGHT",
}
MAP.update({f"BT{i}": f"&bt BT_SEL {i - 1}" for i in range(1, 6)})
MAP.update({f"MB{i}": f"&mkp MB{i}" for i in range(3, 6)})
MAP.update({c: f"&kp {c}" for c in "QWERTYUIOPASDFGHJKLZXCVBNM"})
MAP.update({str(n): f"&kp N{n}" for n in range(1, 10)})
MAP["0"] = "&kp N0"
MAP.update({
    "'": "&kp SQT", "'/SFT": "&mt LSHFT SQT", "ES/CTL": "&mt LCTRL ESC",
    ";": "&kp SEMI", ",": "&kp COMMA", ".": "&kp DOT", "/": "&kp FSLH",
    "!": "&kp EXCL", "@": "&kp AT", "#": "&kp HASH", "$": "&kp DLLR",
    "%": "&kp PRCNT", "^": "&kp CARET", "&": "&kp AMPS", "*": "&kp ASTRK",
    "(": "&kp LPAR", ")": "&kp RPAR", "-": "&kp MINUS", "=": "&kp EQUAL",
    "[": "&kp LBKT", "]": "&kp RBKT", "`": "&kp GRAVE", "_": "&kp UNDER",
    "+": "&kp PLUS", "{": "&kp LBRC", "}": "&kp RBRC", "~": "&kp TILDE",
})


def parse_bindings(line):
    """'&kp A &mt LSHFT SQT' -> ['&kp A', '&mt LSHFT SQT']"""
    out = []
    for tok in line.split():
        if tok.startswith("&"):
            out.append(tok)
        elif out:
            out[-1] += " " + tok
    return out


def main(path):
    src = open(path).read()
    bad = 0
    for name, body in re.findall(r"(\w+_layer)\s*\{(.*?)\n                \};", src, re.S):
        lines = body.splitlines()
        comments = [l for l in lines if l.strip().startswith("//")]
        binds = [parse_bindings(l) for l in lines if l.strip().startswith("&")]
        for i, (cline, brow) in enumerate(zip(comments, binds)):
            cells = cline.split("//", 1)[1].split("|")[1:-1]
            if len(cells) != len(brow):
                print(f"[{name}] baris {i}: comment {len(cells)} sel, binding {len(brow)} -> JUMLAH BEDA")
                bad += 1
                continue
            for col, (cell, have) in enumerate(zip(cells, brow), start=1):
                want = MAP.get(cell.strip(), "&trans")
                if want != have:
                    print(f"[{name}] baris {i} kolom {col}: comment "
                          f"'{cell.strip() or '-'}' -> harus {want}, di file {have}")
                    bad += 1
    print("SEMUA COCOK" if not bad else f"{bad} sel beda")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "config/corne_left.keymap"))