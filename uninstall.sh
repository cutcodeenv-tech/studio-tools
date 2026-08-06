#!/usr/bin/env zsh

print -P "\n%B▶ Studio Tools — Uninstall%b\n"

# Настройки Nimble Commander чистим ДО удаления ~/.studio-tools:
# оттуда берётся список того, что мы когда-то добавили.
_NC_CFG="$HOME/Library/Application Support/Nimble Commander/Config/Config.json"
_NC_SETTINGS="$HOME/.studio-tools/nimble-commander/nc-settings.json"
if [[ -f "$_NC_CFG" && -f "$_NC_SETTINGS" ]]; then
    # Config.json целиком не трогаем — там настройки пользователя.
    # Убираем только свои инструменты и тему, по uuid и имени.
    if python3 - "$_NC_CFG" "$_NC_SETTINGS" <<'PY'
import json, os, sys

cfg_path, patch_path = sys.argv[1], sys.argv[2]
with open(patch_path) as f:
    patch = json.load(f)
with open(cfg_path) as f:
    cfg = json.load(f)

ours = {t["uuid"] for t in patch.get("externalTools", {}).get("tools_v1", [])}
tools = cfg.get("externalTools", {}).get("tools_v1")
if isinstance(tools, list):
    cfg["externalTools"]["tools_v1"] = [t for t in tools if t.get("uuid") not in ours]

our_themes = {t["themeName"] for t in patch.get("themes", {}).get("themes_v1", [])}
themes = cfg.get("themes", {}).get("themes_v1")
if isinstance(themes, list):
    cfg["themes"]["themes_v1"] = [t for t in themes if t.get("themeName") not in our_themes]

if cfg.get("general", {}).get("theme") in our_themes:
    cfg["general"].pop("theme", None)

tmp = cfg_path + ".studio-tools.tmp"
with open(tmp, "w") as f:
    json.dump(cfg, f, ensure_ascii=False, indent=4)
os.replace(tmp, cfg_path)
PY
    then
        print -P "  %F{green}✓%f  Nimble Commander: тема и инструменты убраны"
    else
        print -P "  %F{yellow}⚠%f  Не удалось почистить настройки NC"
    fi
fi
rm -f "${_NC_CFG}.studio-tools.bak"

# ~/bin/proj может быть симлинком (новые установки) или обычным файлом (старые)
rm -f "$HOME/bin/proj"
print -P "  %F{green}✓%f  ~/bin/proj удалён"

# Хвосты прошлых версий: sf был дублем `proj sync`, minfo.app — попап для NC
for _leftover in "$HOME/bin/sf" "$HOME/bin/minfo"; do
    if [[ -e "$_leftover" ]]; then
        rm -f "$_leftover"
        print -P "  %F{green}✓%f  ~/bin/${_leftover:t} удалён"
    fi
done
if [[ -d "$HOME/bin/minfo.app" ]]; then
    rm -rf "$HOME/bin/minfo.app"
    print -P "  %F{green}✓%f  ~/bin/minfo.app удалён"
fi

rm -rf "$HOME/.studio-tools"
print -P "  %F{green}✓%f  ~/.studio-tools удалён"

# Строка PATH могла попасть в любой из этих файлов — setup.sh пишет
# в .zshrc на macOS и в .bashrc/.bash_profile на остальных системах
for _rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
    [[ -f "$_rc" ]] || continue
    grep -qF 'export PATH="$HOME/bin:$PATH"' "$_rc" || continue
    _tmp=$(mktemp) || continue
    # Без `|| true` здесь ломается всё: если наша строка была в файле
    # единственной, grep -v не выводит ничего и возвращает 1, и строка
    # оставалась на месте — при этом отчёт рапортовал об успехе.
    grep -vF 'export PATH="$HOME/bin:$PATH"' "$_rc" > "$_tmp" || true
    if mv "$_tmp" "$_rc"; then
        print -P "  %F{green}✓%f  PATH убран из ${_rc:t}"
    else
        rm -f "$_tmp"
        print -P "  %F{yellow}⚠%f  Не удалось изменить ${_rc:t}"
    fi
done

print -P "\n%F{green}%B✅ Готово. Перезапусти терминал и Nimble Commander.%f%b\n"
