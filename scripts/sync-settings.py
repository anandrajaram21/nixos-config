"""Copy apps' current UI settings into their pinned Nix settings.

Usage: sync-settings.py [app ...]   (default: every app in APPS)

Apps are skipped unless this machine's hosts/<hostname>/default.nix imports
their modules/home/apps/<module> and the app is installed. For each app, reads its settings as the app saved them and rewrites the values
of keys already pinned in the module's settings attrset. Keys are never added
or removed; settings the app has that aren't pinned are only listed.
"""

import json
import os
import plistlib
import re
import subprocess
import sys
import tempfile
import time

HOME = os.path.expanduser("~")
REPO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
ENTRY = re.compile(r'^    ("(?:[^"\\]|\\.)*"|[A-Za-z_][A-Za-z0-9_\'-]*) = ')


def read_json(path):
    def read():
        with open(os.path.join(HOME, path)) as f:
            return json.load(f)

    return read


def vorssaint_export():
    with tempfile.TemporaryDirectory() as d:
        out = os.path.join(d, "export.plist")
        subprocess.run(["/Applications/Vorssaint.app/Contents/MacOS/Vorssaint", "--export-settings", out], check=True)
        with open(out, "rb") as f:
            return plistlib.load(f)["settings"]


# module: file under modules/home/apps; installed: path that exists only when
# the app is installed; quit: (process pattern, bundle id) to quit
# first so the app has flushed its settings; sources: (attrset name, reader);
# ignore: dotted keys that are app state, not preferences.
APPS = {
    "t3code": {
        "module": "t3code.nix",
        "installed": "~/.t3/userdata",
        "sources": [
            ("serverSettings", read_json(".t3/userdata/settings.json")),
            ("clientSettings", read_json(".t3/userdata/client-settings.json")),
        ],
    },
    "hex": {
        "module": "hex.nix",
        "installed": "/Applications/Hex.app",
        "quit": ("Hex.app/Contents/MacOS/", "anomaly.hex"),
        "sources": [("hexSettings", read_json("Library/Application Support/hex/settings.json"))],
        "ignore": {"migrations", "transcription_recents", "meetings.calendar.connected"},
    },
    "vorssaint": {
        "module": "vorssaint.nix",
        "installed": "/Applications/Vorssaint.app",
        "quit": ("Vorssaint.app/Contents/MacOS/Vorssaint$", "com.vorssaint.utils"),
        "sources": [("vorssaintSettings", vorssaint_export)],
    },
}


def host_imports():
    host = os.uname().nodename.split(".")[0]
    try:
        with open(os.path.join(REPO, "hosts", host, "default.nix")) as f:
            return host, f.read()
    except FileNotFoundError:
        sys.exit(f"no hosts/{host}/default.nix; is this machine's hostname a host in this repo?")


def quit_app(pattern, bundle_id):
    running = lambda: subprocess.run(["pgrep", "-f", pattern], capture_output=True).returncode == 0
    if not running():
        return
    subprocess.run(["osascript", "-e", f'tell application id "{bundle_id}" to quit'], check=True)
    for _ in range(20):
        if not running():
            return
        time.sleep(0.5)
    sys.exit(f"{bundle_id} didn't quit")


def nix_str(x):
    for a, b in (("\\", "\\\\"), ('"', '\\"'), ("${", "\\${"), ("\n", "\\n"), ("\t", "\\t")):
        x = x.replace(a, b)
    return f'"{x}"'


def nix_key(k):
    return k if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_'-]*", k) else nix_str(k)


def nix_value(x, ind):
    pad = "  " * ind
    if x is None:
        return "null"
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
        body = "".join(f"{pad}  {nix_key(k)} = {nix_value(v, ind + 1)};\n" for k, v in x.items())
        return "{\n" + body + pad + "}"
    sys.exit(f"unsupported settings type {type(x).__name__}")


def same(a, b):
    if a == b:
        return True
    # Some apps store JSON inside a string and re-serialise it with another key order.
    if isinstance(a, str) and isinstance(b, str):
        try:
            return json.loads(a) == json.loads(b)
        except ValueError:
            return False
    return False


def fit(pinned, new, path, ignore, unmanaged):
    """new, restricted to the keys pinned has; unpinned keys go to unmanaged."""
    if isinstance(pinned, dict) and isinstance(new, dict):
        for k in new:
            p = f"{path}.{k}" if path else k
            if k not in pinned and p not in ignore:
                unmanaged.append(p)
        return {k: fit(v, new[k], f"{path}.{k}" if path else k, ignore, unmanaged) if k in new else v for k, v in pinned.items()}
    return pinned if same(pinned, new) else new


def sync_attrset(lines, name, current, ignore):
    start = lines.index(f"  {name} = {{") + 1
    end = lines.index("  };", start)
    block = lines[start:end]
    pinned = json.loads(
        subprocess.run(
            ["nix-instantiate", "--eval", "--strict", "--json", "--expr", "{\n" + "\n".join(block) + "\n}"],
            capture_output=True, text=True, check=True,
        ).stdout
    )

    entries, entry = [], None
    for line in block:
        m = ENTRY.match(line)
        if m:
            key = m.group(1)
            entry = [json.loads(key) if key.startswith('"') else key, [line]]
            entries.append(entry)
        else:
            entry[1].append(line)

    unmanaged, changed, body = [], [], []
    for key in current:
        if key not in pinned and key not in ignore:
            unmanaged.append(key)
    for key, old in entries:
        if key not in current:
            body += old
            continue
        new = fit(pinned[key], current[key], key, ignore, unmanaged)
        if new == pinned[key] and type(new) is type(pinned[key]):
            body += old
        else:
            changed.append(key)
            body += f"    {nix_key(key)} = {nix_value(new, 2)};".split("\n")
    return lines[:start] + body + lines[end:], changed, unmanaged


def main():
    names = sys.argv[1:] or list(APPS)
    for n in names:
        if n not in APPS:
            sys.exit(f"unknown app {n}; known: {', '.join(APPS)}")
    host, imports = host_imports()
    for n in names:
        app = APPS[n]
        if f"modules/home/apps/{app['module']}" not in imports:
            print(f"{n}: skipped, {host} doesn't import modules/home/apps/{app['module']}")
            continue
        if not os.path.exists(os.path.expanduser(app["installed"])):
            print(f"{n}: skipped, not installed ({app['installed']} not found)")
            continue
        if "quit" in app:
            quit_app(*app["quit"])
        module = os.path.join(REPO, "modules", "home", "apps", app["module"])
        with open(module) as f:
            lines = f.read().split("\n")
        changed, unmanaged = [], []
        for attr, read in app["sources"]:
            try:
                current = read()
            except FileNotFoundError as e:
                print(f"{n}: skipped, {e.filename} not found")
                break
            lines, c, u = sync_attrset(lines, attr, current, app.get("ignore", set()))
            changed += c
            unmanaged += u
        with open(module, "w") as f:
            f.write("\n".join(lines))
        print(f"{n}: updated {len(changed)} setting(s){': ' + ', '.join(changed) if changed else ''}")
        if unmanaged:
            print(f"{n}: {len(unmanaged)} unpinned setting(s) in the app; add any you want by hand: {', '.join(unmanaged)}")


if __name__ == "__main__":
    main()
