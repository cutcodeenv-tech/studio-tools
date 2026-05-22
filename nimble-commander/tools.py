#!/usr/bin/env python3
"""Apply studio settings to Nimble Commander Config.json."""
import json, sys, os

def deep_merge(base, patch):
    for key, val in patch.items():
        if key not in base:
            base[key] = val
        elif isinstance(val, dict) and isinstance(base[key], dict):
            deep_merge(base[key], val)
        elif isinstance(val, list) and isinstance(base[key], list) and key == "themes_v1":
            _merge_themes(base[key], val)
        elif isinstance(val, list) and isinstance(base[key], list) and key == "tools_v1":
            _merge_tools(base[key], val)
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

def _merge_tools(existing, incoming):
    existing_uuids = {t["uuid"] for t in existing}
    for tool in incoming:
        if tool["uuid"] not in existing_uuids:
            tool = dict(tool)
            tool["path"] = os.path.expanduser(tool["path"])
            existing.append(tool)

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

    deep_merge(config, patch)

    with open(config_path, "w") as f:
        json.dump(config, f, ensure_ascii=False, indent=4)

    theme = patch.get("general", {}).get("theme", "")
    size_fmt = patch.get("filePanel", {}).get("general", {}).get("fileSizeFormat", "-")
    tools = patch.get("externalTools", {}).get("tools_v1", [])
    print(f"✓ theme: {theme}")
    print(f"✓ fileSizeFormat: {size_fmt}")
    print(f"✓ tools: {len(tools)} checked")

if __name__ == "__main__":
    main()
