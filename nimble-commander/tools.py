#!/usr/bin/env python3
"""Deploy Studio Tools into Nimble Commander Config.json."""
import json, sys, os

TOOLS = [
    {
        "title": "proj — меню",
        "path": os.path.expanduser("~/bin/proj"),
        "parameters": "menu",
        "shortcut": "\x00",
        "startup": 1,
        "uuid": "b1c2d3e4-f5a6-7890-abcd-ef1234567801",
    },
    {
        "title": "proj — новый проект",
        "path": os.path.expanduser("~/bin/proj"),
        "parameters": "new",
        "shortcut": "\x00",
        "startup": 1,
        "uuid": "b1c2d3e4-f5a6-7890-abcd-ef1234567802",
    },
    {
        "title": "proj — синхронизация",
        "path": os.path.expanduser("~/bin/proj"),
        "parameters": "sync",
        "shortcut": "\x00",
        "startup": 1,
        "uuid": "b1c2d3e4-f5a6-7890-abcd-ef1234567803",
    },
    {
        "title": "proj — статус",
        "path": os.path.expanduser("~/bin/proj"),
        "parameters": "status",
        "shortcut": "\x00",
        "startup": 1,
        "uuid": "b1c2d3e4-f5a6-7890-abcd-ef1234567804",
    },
    {
        "title": "proj — настройки",
        "path": os.path.expanduser("~/bin/proj"),
        "parameters": "settings",
        "shortcut": "\x00",
        "startup": 1,
        "uuid": "b1c2d3e4-f5a6-7890-abcd-ef1234567805",
    },
    {
        "title": "Воспроизвести (mpv)",
        "path": "/opt/homebrew/bin/mpv",
        "parameters": "--no-video --block %p",
        "shortcut": "\x00",
        "startup": 1,
        "uuid": "b1c2d3e4-f5a6-7890-abcd-ef1234567806",
    },
    {
        "title": "mediainfo — попап",
        "path": "/usr/bin/osascript",
        "parameters": os.path.expanduser("~/.studio-tools/nimble-commander/minfo.applescript") + " %p",
        "shortcut": "\x00",
        "startup": 0,
        "uuid": "b1c2d3e4-f5a6-7890-abcd-ef1234567807",
    },
    {
        "title": "dust — размер папки",
        "path": "/opt/homebrew/bin/dust",
        "parameters": "-d 2 %r",
        "shortcut": "\x00",
        "startup": 1,
        "uuid": "b1c2d3e4-f5a6-7890-abcd-ef1234567808",
    },
]


def main():
    config_path = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser(
        "~/Library/Application Support/Nimble Commander/Config/Config.json"
    )
    with open(config_path) as f:
        data = json.load(f)

    existing = data.setdefault("externalTools", {}).setdefault("tools_v1", [])
    existing_uuids = {t["uuid"] for t in existing}
    added = 0
    for tool in TOOLS:
        if tool["uuid"] not in existing_uuids:
            existing.append(tool)
            added += 1

    with open(config_path, "w") as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

    print(f"Added {added} tools, total: {len(existing)}")


if __name__ == "__main__":
    main()
