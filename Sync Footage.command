#!/bin/zsh

# ── КОНФИГ ──────────────────────────────────────────────────────────────────
SSD_PROJECTS_ROOT="/Volumes/01_Extreme SSD/[001] Projects"
HDD_SOURCES_ROOT="/Volumes/HDD_1"
# ────────────────────────────────────────────────────────────────────────────

# Собираем список проектов из SSD_PROJECTS_ROOT
project_names=()
for d in "${SSD_PROJECTS_ROOT}"/*/; do
    [ -d "$d" ] && project_names+=("$(basename "$d")")
done

if [ ${#project_names[@]} -eq 0 ]; then
    osascript -e 'Tell application "System Events" to display dialog "Проекты не найдены в:\n'"${SSD_PROJECTS_ROOT//\"/\\\"}"'" buttons {"OK"} default button "OK" with title "Ошибка"'
    exit 1
fi

# Формируем AppleScript список через heredoc
as_items=""
for name in "${project_names[@]}"; do
    as_items+="\"${name}\", "
done
as_items="${as_items%, }"

chosen=$(osascript <<EOF
set chosenItem to choose from list {${as_items}} with title "Sync Footage" with prompt "Выберите проект для синхронизации:"
if chosenItem is false then return ""
return item 1 of chosenItem
EOF
)

if [ "$chosen" = "false" ] || [ -z "$chosen" ]; then
    exit 0
fi

SSD_PROJECT="${SSD_PROJECTS_ROOT}/${chosen}"
HDD_PROJECT="${HDD_SOURCES_ROOT}/${chosen}"

# Проверка HDD
if [ ! -d "$HDD_PROJECT" ]; then
    osascript -e 'Tell application "System Events" to display dialog "Папка проекта на HDD не найдена:\n'"${HDD_PROJECT//\"/\\\"}"'" buttons {"OK"} default button "OK" with title "Ошибка"'
    exit 1
fi

synced=0
echo "\n▶ Проект: ${chosen}\n"

for hdd_cam in "${HDD_PROJECT}/02_Sources/Video"/Cam_*/; do
    [ -d "$hdd_cam" ] || continue
    cam_name=$(basename "$hdd_cam")
    ssd_cam="${SSD_PROJECT}/02_Sources/Video/${cam_name}"

    mkdir -p "${ssd_cam}/Proxy"
    echo "📁 ${cam_name}"

    # Симлинки для исходников
    for hdd_file in "${hdd_cam}"*; do
        [ -f "$hdd_file" ] || continue
        filename=$(basename "$hdd_file")
        ssd_link="${ssd_cam}/${filename}"

        if [ ! -e "$ssd_link" ] && [ ! -L "$ssd_link" ]; then
            ln -s "$hdd_file" "$ssd_link"
            (( synced++ ))
            echo "  → symlink  ${filename}"
        fi
    done

    # Копируем прокси с HDD на SSD
    if [ -d "${hdd_cam}Proxy" ]; then
        for proxy_file in "${hdd_cam}Proxy/"*; do
            [ -f "$proxy_file" ] || continue
            filename=$(basename "$proxy_file")
            ssd_proxy="${ssd_cam}/Proxy/${filename}"

            if [ ! -e "$ssd_proxy" ]; then
                echo "  ⬇ copy     Proxy/${filename}"
                cp "$proxy_file" "$ssd_proxy"
                (( synced++ ))
                echo "  ✓ done     Proxy/${filename}"
            fi
        done
    fi
done

echo "\n✅ Готово: синхронизировано ${synced} файлов."
afplay /System/Library/Sounds/Glass.aiff 2>/dev/null || true
osascript -e 'Tell application "System Events" to display dialog "Синхронизировано: '"$synced"' новых файлов." buttons {"OK"} default button "OK" with title "Sync Footage"'
