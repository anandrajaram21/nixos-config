"""Copy Vorssaint's current UI settings into modules/home/apps/vorssaint.nix.

Quits Vorssaint, exports its settings, and rewrites the value of every key
already in `vorssaintSettings`. Keys are never added or removed; new keys in
the export are only listed.
"""

import json
import os
import plistlib
import re
import subprocess
import sys
import time

APP = "/Applications/Vorssaint.app/Contents/MacOS/Vorssaint"
EXPORT = "/tmp/vorssaint-export.plist"
MODULE = os.path.join(os.path.dirname(__file__), "..", "modules", "home", "apps", "vorssaint.nix")
ENTRY = re.compile(r'^    ("(?:[^"\\]|\\.)*"|[A-Za-z_][A-Za-z0-9_\'-]*) = ')


def nix_str(x):
    for a, b in (("\\", "\\\\"), ('"', '\\"'), ("${", "\\${"), ("\n", "\\n"), ("\t", "\\t")):
        x = x.replace(a, b)
    return f'"{x}"'


def nix_key(k):
    return k if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_'-]*", k) else nix_str(k)


def nix_value(x, ind):
    pad = "  " * ind
    if isinstance(x, bool):
        return "true" if x else "false"
    if isinstance(x, int):
        return str(x)
    if isinstance(x, float):
        r = repr(x)
        if not re.fullmatch(r"-?\d+\.\d+", r):
            sys.exit(f"can't write float {r} as a Nix literal")
        return r
    if isinstance(x, str):
        return nix_str(x)
    if isinstance(x, list):
        if not x:
            return "[ ]"
        return "[\n" + "".join(f"{pad}  {nix_value(i, ind + 1)}\n" for i in x) + pad + "]"
    if isinstance(x, dict):
        if not x:
            return "{ }"
        body = "".join(f"{pad}  {nix_key(k)} = {nix_value(v, ind + 1)};\n" for k, v in sorted(x.items()))
        return "{\n" + body + pad + "}"
    sys.exit(f"unsupported plist type {type(x).__name__}")


def same_json(old_lines, new):
    # Vorssaint re-serialises JSON-in-string settings with random key order.
    m = re.search(r'= "((?:[^"\\]|\\.)*)";$', old_lines[0]) if len(old_lines) == 1 else None
    if not m or not isinstance(new, str):
        return False
    old = re.sub(r"\\(.)", lambda c: {"n": "\n", "t": "\t"}.get(c.group(1), c.group(1)), m.group(1))
    try:
        return json.loads(old) == json.loads(new)
    except ValueError:
        return False


def export_settings():
    running = subprocess.run(["pgrep", "-f", "Vorssaint.app/Contents/MacOS/Vorssaint$"], capture_output=True).returncode == 0
    if running:
        subprocess.run(["osascript", "-e", 'tell application id "com.vorssaint.utils" to quit'], check=True)
        for _ in range(20):
            if subprocess.run(["pgrep", "-f", "Vorssaint.app/Contents/MacOS/Vorssaint$"], capture_output=True).returncode:
                break
            time.sleep(0.5)
        else:
            sys.exit("Vorssaint didn't quit")
    subprocess.run([APP, "--export-settings", EXPORT], check=True)
    with open(EXPORT, "rb") as f:
        return plistlib.load(f)["settings"]


def main():
    exported = export_settings()
    with open(MODULE) as f:
        lines = f.read().split("\n")

    start = lines.index("  vorssaintSettings = {") + 1
    end = lines.index("  };", start)
    entries, current = [], None
    for line in lines[start:end]:
        m = ENTRY.match(line)
        if m:
            key = m.group(1)
            current = [key[1:-1].encode().decode("unicode_escape") if key.startswith('"') else key, [line]]
            entries.append(current)
        else:
            current[1].append(line)

    body, changed, missing = [], [], []
    for key, old in entries:
        if key in exported and same_json(old, exported[key]):
            body += old
        elif key in exported:
            new = f"    {nix_key(key)} = {nix_value(exported[key], 2)};".split("\n")
            if new != old:
                changed.append(key)
            body += new
        else:
            missing.append(key)
            body += old

    with open(MODULE, "w") as f:
        f.write("\n".join(lines[:start] + body + lines[end:]))

    managed = {k for k, _ in entries}
    print(f"updated {len(changed)} setting(s): {', '.join(changed) or 'none'}")
    if missing:
        print(f"kept (not in export): {', '.join(missing)}")
    new_keys = sorted(set(exported) - managed)
    print(f"{len(new_keys)} unmanaged key(s) in the export; add any you want to the module by hand")


if __name__ == "__main__":
    main()
