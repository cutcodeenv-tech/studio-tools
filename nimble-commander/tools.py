#!/usr/bin/env python3
"""Apply studio settings to Nimble Commander Config.json."""
import json, sys, os, shutil, subprocess

def deep_merge(base, patch, prefix):
    for key, val in patch.items():
        if key == "tools_v1":
            base.setdefault(key, [])
            if isinstance(base[key], list) and isinstance(val, list):
                _merge_tools(base[key], val, prefix)
                continue
        if key not in base:
            base[key] = val
        elif isinstance(val, dict) and isinstance(base[key], dict):
            deep_merge(base[key], val, prefix)
        elif isinstance(val, list) and isinstance(base[key], list) and key == "themes_v1":
            _merge_themes(base[key], val)
        else:
            base[key] = val

def _merge_themes(existing, incoming):
    idx = {t["themeName"]: i for i, t in enumerate(existing)}
    for theme in incoming:
        name = theme["themeName"]
        if name in idx:
            existing[idx[name]] = theme
        else:
            existing.append(theme)

def brew_prefix():
    """Homebrew живёт в /opt/homebrew на Apple Silicon и в /usr/local на Intel.

    Раньше пути к mpv/dust были захардкожены под Apple Silicon, и на Intel
    инструменты Nimble Commander молча не запускались.
    """
    found = shutil.which("brew")
    if found:
        try:
            out = subprocess.run([found, "--prefix"], capture_output=True,
                                 text=True, timeout=10)
            if out.returncode == 0 and out.stdout.strip():
                return out.stdout.strip()
        except (OSError, subprocess.SubprocessError):
            pass
    return "/opt/homebrew" if os.path.isdir("/opt/homebrew") else "/usr/local"


def _resolve_path(path, prefix):
    return os.path.expanduser(path.replace("{brew}", prefix))


def _merge_tools(existing, incoming, prefix):
    by_uuid = {t.get("uuid"): i for i, t in enumerate(existing)}
    for tool in incoming:
        tool = dict(tool)
        tool["path"] = _resolve_path(tool["path"], prefix)
        idx = by_uuid.get(tool["uuid"])
        if idx is None:
            existing.append(tool)
        else:
            # Обновляем свои инструменты на месте, иначе исправленные пути
            # и горячие клавиши не доезжали до уже установленных копий.
            existing[idx] = tool

def main():
    here = os.path.dirname(os.path.abspath(__file__))
    settings_path = os.path.join(here, "nc-settings.json")
    config_path = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser(
        "~/Library/Application Support/Nimble Commander/Config/Config.json"
    )

    if not os.path.exists(config_path):
        print("NC config not found. Launch Nimble Commander once, then re-run setup.")
        sys.exit(1)

    with open(settings_path) as f:
        patch = json.load(f)
    with open(config_path) as f:
        config = json.load(f)

    prefix = brew_prefix()
    deep_merge(config, patch, prefix)

    # Пишем через временный файл и os.replace: обрыв на середине записи
    # оставил бы Nimble Commander с битым Config.json.
    shutil.copy2(config_path, config_path + ".studio-tools.bak")
    tmp_path = config_path + ".studio-tools.tmp"
    with open(tmp_path, "w") as f:
        json.dump(config, f, ensure_ascii=False, indent=4)
    os.replace(tmp_path, config_path)

    theme = patch.get("general", {}).get("theme", "")
    size_fmt = patch.get("filePanel", {}).get("general", {}).get("fileSizeFormat", "-")
    tools = patch.get("externalTools", {}).get("tools_v1", [])
    print(f"✓ theme: {theme}")
    print(f"✓ fileSizeFormat: {size_fmt}")
    print(f"✓ tools: {len(tools)} (brew prefix: {prefix})")

if __name__ == "__main__":
    main()
