#!/bin/zsh

# ── КОНФИГ ──────────────────────────────────────────────────────────────────
SSD_PROJECTS_ROOT="/Volumes/01_Extreme SSD/[001] Projects"
HDD_SOURCES_ROOT="/Volumes/HDD_1"
PREMIERE_TEMPLATE="/Volumes/01_Extreme SSD/[003] Resurces/00_TEMPLATE1.prproj"
# ────────────────────────────────────────────────────────────────────────────

# 1. Целевая директория (аргумент от Forklift или дефолт из конфига)
TARGET_DIR="${1:-$SSD_PROJECTS_ROOT}"

# 2. Диалоговое окно для имени проекта
PROJECT_NAME=$(osascript -e 'Tell application "System Events" to display dialog "Введите название проекта:" default answer "" with title "Создание структуры проекта"' -e 'text returned of result' 2>/dev/null)

if [ -z "$PROJECT_NAME" ]; then
    exit 1
fi

# 3. Диалоговое окно для количества камер
CAM_COUNT=$(osascript -e 'Tell application "System Events" to display dialog "Сколько камер создать? (1-10)" default answer "2" with title "Количество камер"' -e 'text returned of result' 2>/dev/null)

# Если ввели не число, пустоту, или вне диапазона 1-10 — по дефолту 2
if ! [[ "$CAM_COUNT" =~ ^[0-9]+$ ]] || (( CAM_COUNT < 1 || CAM_COUNT > 10 )); then
    CAM_COUNT=2
fi

DATE=$(date +%Y-%m-%d)

# Проверка: папка проекта уже существует?
SSD_ROOT_CHECK="${TARGET_DIR}/${DATE}_${PROJECT_NAME// /_}"
if [ -d "$SSD_ROOT_CHECK" ]; then
    osascript -e 'Tell application "System Events" to display dialog "Папка проекта уже существует:\n'"${SSD_ROOT_CHECK//\"/\\\"}"'" buttons {"OK"} default button "OK" with title "Ошибка"'
    exit 1
fi

# Имя для папки (с датой) и безопасные имена (без пробелов)
SAFE_NAME="${PROJECT_NAME// /_}"                 # для файлов/папок
PROJECT_FOLDER_NAME="${DATE}_${SAFE_NAME}"       # папка проекта с датой

# Имя пр-проекта Premiere (без даты)
PREMIERE_PROJECT_NAME="${SAFE_NAME}.prproj"

# 4. Пути SSD и HDD
SSD_ROOT="${TARGET_DIR}/${PROJECT_FOLDER_NAME}"
HDD_ROOT="${HDD_SOURCES_ROOT}/${PROJECT_FOLDER_NAME}"

# 5. Создаем структуру на SSD (Основной каркас)
mkdir -p "${SSD_ROOT}/00_Admin"
mkdir -p "${SSD_ROOT}/01_Project_Files"/{Premiere,DaVinci,AfterEffects,Photoshop,Illustrator,Audition}
mkdir -p "${SSD_ROOT}/02_Sources"/{Video/{Screen_Cap,Stock_Archival},Audio/{Music,SFX,VoiceOver},Graphics/{Images,Vectors}}
mkdir -p "${SSD_ROOT}/03_Proxies"
mkdir -p "${SSD_ROOT}/04_Exports"/{01_Drafts,02_Handoff/{For_Color,For_Sound,For_CGI},03_Master,04_Socials}
mkdir -p "${SSD_ROOT}/99_Archive"

# 5.1 Копируем темплейт Premiere в папку проекта и переименовываем (без даты)
if [ -f "${PREMIERE_TEMPLATE}" ]; then
    cp "${PREMIERE_TEMPLATE}" "${SSD_ROOT}/01_Project_Files/Premiere/${PREMIERE_PROJECT_NAME}"
else
    osascript -e 'Tell application "System Events" to display dialog "Не найден шаблон Premiere:\n'"${PREMIERE_TEMPLATE//\"/\\\"}"'" buttons {"OK"} default button "OK" with title "Ошибка шаблона"'
fi

# 6. Проверка HDD перед циклом камер
HDD_VOLUME=$(dirname "${HDD_ROOT}")
if [ ! -d "$HDD_VOLUME" ]; then
    osascript -e 'Tell application "System Events" to display dialog "HDD не смонтирован:\n'"${HDD_VOLUME//\"/\\\"}"'\n\nПапки камер не созданы." buttons {"OK"} default button "OK" with title "HDD недоступен"'
    CAM_COUNT=0
fi

# 6. Цикл создания камер (Симлинки)
# Алфавит для имен папок (a, b, c...)
ALPHABET=( {a..z} )

for (( i=1; i<=CAM_COUNT; i++ )); do
    CAM_LETTER=${ALPHABET[$i]}
    CAM_FOLDER_NAME="Cam_${CAM_LETTER}"

    # 6.1 Реальная папка на SSD с подпапкой Proxy
    mkdir -p "${SSD_ROOT}/02_Sources/Video/${CAM_FOLDER_NAME}/Proxy"

    # 6.2 Папка оригиналов на HDD
    mkdir -p "${HDD_ROOT}/02_Sources/Video/${CAM_FOLDER_NAME}"
done

# 7. Фидбек
afplay /System/Library/Sounds/Glass.aiff 2>/dev/null || true
osascript -e 'Tell application "System Events" to display dialog "Проект создан:\n'"${SSD_ROOT//\"/\\\"}"'" buttons {"OK"} default button "OK" with title "Готово"'