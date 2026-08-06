#!/usr/bin/env zsh
#
# Тесты на регрессии. Каждый кейс воспроизводит конкретный баг, который
# был в коде — если правка откатится, тест покраснеет.
#
#   zsh tests/run.zsh

REPO_DIR="${0:A:h:h}"

typeset -g PASS=0 FAIL=0

# return 0 обязателен: (( PASS++ )) отдаёт значение ДО инкремента, то есть
# на первом вызове возвращает 0 → «ложь», и ветка || срабатывала следом
ok()   { print -P "  %F{green}✓%f  $1"; (( PASS++ )); return 0 }
bad()  { print -P "  %F{red}✗%f  $1"; (( FAIL++ )); return 0 }
check() { [[ "$2" == "$3" ]] && ok "$1" || bad "$1 — ожидалось '$3', получено '$2'" }

# Песочница: настоящая установка не трогается
SANDBOX=$(mktemp -d)
trap 'rm -rf "$SANDBOX"' EXIT

export STUDIO_TOOLS_HOME="${SANDBOX}/.studio-tools"
export PROJ_SOURCE_ONLY=1
mkdir -p "$STUDIO_TOOLS_HOME"

# Скобки в имени — как в реальном пути по умолчанию "[001] Projects".
# Именно они ломали срезание префикса через sed.
SSD="${SANDBOX}/[001] Projects"
HDD="${SANDBOX}/HDD_1"
mkdir -p "$SSD" "$HDD"

cat > "${STUDIO_TOOLS_HOME}/config" <<EOF
PROJECTS_PARENT_ROOT=
SSD_PROJECTS_ROOT=${SSD}
HDD_SOURCES_ROOT=${HDD}
PREMIERE_TEMPLATE=
EOF

source "${REPO_DIR}/bin/proj"

print -P "\n%B%F{cyan}Studio Tools — тесты%f%b\n"

# ── конфиг ───────────────────────────────────────────────────────────────────
print -P "%Bконфиг%b"
check "SSD_PROJECTS_ROOT читается" "$SSD_PROJECTS_ROOT" "$SSD"
check "HDD_SOURCES_ROOT читается"  "$HDD_SOURCES_ROOT"  "$HDD"

# Конфиг больше не исполняется как код: подстановка команды должна
# остаться текстом, а не выполниться при загрузке.
print -r -- 'SSD_PROJECTS_ROOT=/tmp/$(touch "'"${SANDBOX}"'/pwned")' >> "${STUDIO_TOOLS_HOME}/config"
_config_load
[[ -e "${SANDBOX}/pwned" ]] && bad "конфиг исполняет \$(...)" || ok "конфиг не исполняет \$(...)"

# Неизвестные ключи игнорируются
print -r -- 'EVIL_KEY=boom' >> "${STUDIO_TOOLS_HOME}/config"
_config_load
check "неизвестный ключ не попадает в окружение" "${EVIL_KEY:-<unset>}" "<unset>"

# Восстанавливаем нормальный конфиг
cat > "${STUDIO_TOOLS_HOME}/config" <<EOF
PROJECTS_PARENT_ROOT=
SSD_PROJECTS_ROOT=${SSD}
HDD_SOURCES_ROOT=${HDD}
PREMIERE_TEMPLATE=
EOF
_config_load

# ── _config_set сохраняет спецсимволы ────────────────────────────────────────
_config_set PREMIERE_TEMPLATE '/tmp/a b/[001] "x".prproj'
_config_load
check "_config_set сохраняет скобки и кавычки" \
    "$PREMIERE_TEMPLATE" '/tmp/a b/[001] "x".prproj'

# ── выбор проекта: путь со скобками ──────────────────────────────────────────
print -P "\n%Bвыбор проекта%b"
mkdir -p "${SSD}/2026-01-01_Alpha" "${SSD}/2026-02-02_Beta"
list=$(_pick_project_list 2>/dev/null)
check "плоский список проектов" "$(print -r -- "$list" | sort | tr '\n' ' ')" "2026-01-01_Alpha 2026-02-02_Beta "

# С родительской папкой проекты лежат на глубине 2
PARENT="${SANDBOX}/[002] Parent"
mkdir -p "${PARENT}/Клиент А/2026-03-03_Gamma"
PROJECTS_PARENT_ROOT="$PARENT"
list=$(_pick_project_list 2>/dev/null)
check "вложенный список не теряет категорию" "$list" "Клиент А/2026-03-03_Gamma"
PROJECTS_PARENT_ROOT=""

# ── прогресс-бар: нулевой размер ─────────────────────────────────────────────
print -P "\n%Bкопирование%b"
: > "${SANDBOX}/zero.bin"
if copy_with_progress "${SANDBOX}/zero.bin" "${SANDBOX}/zero.out" "zero" >/dev/null 2>&1; then
    ok "0-байтный файл не роняет делением на ноль"
else
    bad "0-байтный файл не скопировался"
fi
check "0-байтная копия существует" "$([[ -f ${SANDBOX}/zero.out ]] && echo yes)" "yes"

# Обычный файл
dd if=/dev/urandom of="${SANDBOX}/src.bin" bs=1024 count=64 2>/dev/null
copy_with_progress "${SANDBOX}/src.bin" "${SANDBOX}/dst.bin" "src" >/dev/null 2>&1
check "копия совпадает с исходником" \
    "$(_stat_size "${SANDBOX}/dst.bin")" "$(_stat_size "${SANDBOX}/src.bin")"

# Огрызок докачивается, а не остаётся обрезанным
head -c 1024 "${SANDBOX}/src.bin" > "${SANDBOX}/partial.bin"
copy_with_progress "${SANDBOX}/src.bin" "${SANDBOX}/partial.bin" "partial" >/dev/null 2>&1
check "недокачанный файл дозаписывается" \
    "$(_stat_size "${SANDBOX}/partial.bin")" "$(_stat_size "${SANDBOX}/src.bin")"
if cmp -s "${SANDBOX}/src.bin" "${SANDBOX}/partial.bin"; then
    ok "содержимое после докачки совпадает"
else
    bad "содержимое после докачки не совпадает"
fi

# Файл длиннее исходника не должен быть принят за валидный префикс
cat "${SANDBOX}/src.bin" "${SANDBOX}/src.bin" > "${SANDBOX}/toolong.bin"
copy_with_progress "${SANDBOX}/src.bin" "${SANDBOX}/toolong.bin" "toolong" >/dev/null 2>&1
if cmp -s "${SANDBOX}/src.bin" "${SANDBOX}/toolong.bin"; then
    ok "слишком длинный dst перезаписывается"
else
    bad "слишком длинный dst остался битым"
fi

# ── _stat_size ───────────────────────────────────────────────────────────────
print -P "\n%Bstat%b"
check "размер несуществующего файла = 0" "$(_stat_size "${SANDBOX}/нет-такого")" "0"
check "размер пустого файла = 0"          "$(_stat_size "${SANDBOX}/zero.bin")"   "0"
check "размер 64K файла"                  "$(_stat_size "${SANDBOX}/src.bin")"    "65536"

# ── CSV ──────────────────────────────────────────────────────────────────────
print -P "\n%BCSV%b"
check "запятая в поле экранируется"  "$(_csv_field 'a,b')"   '"a,b"'
check "кавычка удваивается"          "$(_csv_field 'a"b')"   '"a""b"'
check "пустое поле остаётся полем"   "$(_csv_field '')"      '""'

# ── статус на проекте без камер ──────────────────────────────────────────────
# Раньше глоб Cam_*/ без квалификатора (N) обрывал весь скрипт
print -P "\n%Bстатус%b"
mkdir -p "${SSD}/2026-04-04_NoCams/02_Sources/Video"
out=$(cmd_status_for "${SSD}/2026-04-04_NoCams" "${HDD}/2026-04-04_NoCams" 2>&1)
rc=$?
check "проект без камер не роняет status" "$rc" "0"
if [[ "$out" == *"камер нет"* ]]; then
    ok "status сообщает об отсутствии камер"
else
    bad "status не сообщил об отсутствии камер: $out"
fi

# Проект с камерами и симлинками
P_SSD="${SSD}/2026-05-05_Real"
P_HDD="${HDD}/2026-05-05_Real"
mkdir -p "${P_SSD}/02_Sources/Video/Cam_a/Proxy" "${P_HDD}/02_Sources/Video/Cam_a/Proxy"
: > "${P_HDD}/02_Sources/Video/Cam_a/clip1.mov"
: > "${P_HDD}/02_Sources/Video/Cam_a/clip2.mov"
: > "${P_HDD}/02_Sources/Video/Cam_a/Proxy/clip1.mp4"
ln -s "${P_HDD}/02_Sources/Video/Cam_a/clip1.mov" "${P_SSD}/02_Sources/Video/Cam_a/clip1.mov"
out=$(cmd_status_for "$P_SSD" "$P_HDD" 2>&1)
check "status выполняется на реальном проекте" "$?" "0"
if [[ "$out" == *"HDD: 2"*"симлинки: 1"* ]]; then
    ok "status считает исходники и симлинки"
else
    bad "status посчитал неверно: $out"
fi

# ── синхронизация ────────────────────────────────────────────────────────────
print -P "\n%Bсинхронизация%b"
out=$(cmd_sync_for "$P_SSD" "$P_HDD" 2>&1)
check "sync завершается успешно" "$?" "0"
check "симлинк создан для второго клипа" \
    "$([[ -L ${P_SSD}/02_Sources/Video/Cam_a/clip2.mov ]] && echo yes)" "yes"
check "прокси скопирован как файл" \
    "$([[ -f ${P_SSD}/02_Sources/Video/Cam_a/Proxy/clip1.mp4 && ! -L ${P_SSD}/02_Sources/Video/Cam_a/Proxy/clip1.mp4 ]] && echo yes)" "yes"

# Повторный запуск ничего не дублирует
out=$(cmd_sync_for "$P_SSD" "$P_HDD" 2>&1)
if [[ "$out" == *"0 новых"* ]]; then
    ok "повторный sync идемпотентен"
else
    bad "повторный sync не идемпотентен: $out"
fi

# ── media log ────────────────────────────────────────────────────────────────
print -P "\n%BMedia Log%b"
# Подставной mediainfo: отдаёт поле с запятой, чтобы проверить экранирование
MOCKBIN="${SANDBOX}/mockbin"
mkdir -p "$MOCKBIN"
cat > "${MOCKBIN}/mediainfo" <<'MOCK'
#!/bin/sh
case "$1" in
  *General*) printf 'UTC 2026-01-02 03:04:05|||10485760|00:00:12.500\n' ;;
  *Video*)   printf 'ProRes 422, HQ|1920|1080|25.000\n' ;;
esac
MOCK
chmod +x "${MOCKBIN}/mediainfo"
PATH="${MOCKBIN}:$PATH"

M_SSD="${SSD}/2026-06-06_Meta"
mkdir -p "${M_SSD}/02_Sources/Video/Cam_a" "${M_SSD}/00_Admin"
: > "${M_SSD}/02_Sources/Video/Cam_a/take,one.mov"
: > "${M_SSD}/02_Sources/Video/Cam_a/take2.MOV"
: > "${M_SSD}/02_Sources/Video/Cam_a/notes.txt"

cmd_meta_for "$M_SSD" "Meta" >/dev/null 2>&1
check "meta завершается успешно" "$?" "0"

CSV="${M_SSD}/00_Admin/media_log.csv"
check "CSV создан" "$([[ -f $CSV ]] && echo yes)" "yes"
check "строк = заголовок + 2 видео (txt пропущен)" "$(wc -l < "$CSV" | tr -d ' ')" "3"
check "верхний регистр расширения распознан" \
    "$(grep -c 'take2.MOV' "$CSV")" "1"
if grep -q '"take,one.mov"' "$CSV"; then
    ok "имя с запятой закавычено"
else
    bad "имя с запятой не закавычено: $(grep take "$CSV")"
fi
if grep -q '"ProRes 422, HQ"' "$CSV"; then
    ok "кодек с запятой закавычен"
else
    bad "кодек с запятой не закавычен"
fi
# Все строки должны иметь одинаковое число полей — иначе колонки съехали
cols=$(awk -F'","' 'NR>1{print NF}' "$CSV" | sort -u | tr '\n' ' ')
check "во всех строках одинаковое число колонок" "$cols" "8 "

# ── архивация ────────────────────────────────────────────────────────────────
print -P "\n%Bархивация%b"
# Симлинк наружу должен пережить архивацию, симлинки на HDD — исчезнуть
EXTERNAL="${SANDBOX}/external.mov"
: > "$EXTERNAL"
ln -s "$EXTERNAL" "${P_SSD}/02_Sources/Video/Cam_a/external.mov"
print -r -- "заметки" > "${P_SSD}/00_Admin_notes.txt"

out=$(cmd_archive_for "$P_SSD" "$P_HDD" 2>&1)
check "archive завершается успешно" "$?" "0"
check "папка на SSD удалена" "$([[ -d $P_SSD ]] && echo yes || echo no)" "no"
check "файл проекта перенесён на HDD" \
    "$([[ -f ${P_HDD}/00_Admin_notes.txt ]] && echo yes)" "yes"
check "прокси перенесён на HDD" \
    "$([[ -f ${P_HDD}/02_Sources/Video/Cam_a/Proxy/clip1.mp4 ]] && echo yes)" "yes"
check "оригиналы на HDD не пострадали" \
    "$([[ -f ${P_HDD}/02_Sources/Video/Cam_a/clip1.mov ]] && echo yes)" "yes"
if [[ "$out" == *"Сохранено 1 симлинков за пределы"* ]]; then
    ok "симлинк наружу не удалён молча"
else
    bad "не предупредили о симлинке наружу: $out"
fi

# ── uninstall ────────────────────────────────────────────────────────────────
# Скрипт разрушительный, поэтому гоняем его целиком в отдельном HOME
print -P "\n%Buninstall%b"
U="${SANDBOX}/uninstall-home"
mkdir -p "$U/.studio-tools" "$U/bin" "$U/Library/Application Support/Nimble Commander/Config"
cp -R "${REPO_DIR}/nimble-commander" "$U/.studio-tools/"
NCC="$U/Library/Application Support/Nimble Commander/Config/Config.json"
print -r -- '{"general":{"userSetting":true},"externalTools":{"tools_v1":[{"title":"мой","path":"/bin/ls","uuid":"user-1"}]},"themes":{"themes_v1":[{"themeName":"Мой тёмный"}]}}' > "$NCC"
python3 "${REPO_DIR}/nimble-commander/tools.py" "$NCC" >/dev/null 2>&1
: > "$U/bin/sf"; : > "$U/bin/proj"
print -r -- 'export PATH="$HOME/bin:$PATH"' > "$U/.zshrc"

HOME="$U" zsh "${REPO_DIR}/uninstall.sh" >/dev/null 2>&1
check "uninstall завершается успешно" "$?" "0"
check "~/bin/proj удалён"      "$([[ -e $U/bin/proj ]] && echo yes || echo no)" "no"
check "~/bin/sf удалён"        "$([[ -e $U/bin/sf ]] && echo yes || echo no)"   "no"
check "~/.studio-tools удалён" "$([[ -d $U/.studio-tools ]] && echo yes || echo no)" "no"
# Единственная строка в rc-файле: grep -v возвращает 1, и раньше строка выживала
check "строка PATH убрана из .zshrc" "$(grep -c 'HOME/bin' "$U/.zshrc" | tr -d ' ')" "0"

python3 - "$NCC" <<'PY' > "${SANDBOX}/nc_check"
import json, sys
d = json.load(open(sys.argv[1]))
t = d["externalTools"]["tools_v1"]
print(len(t), d["general"].get("userSetting"), "theme" in d["general"],
      len(d["themes"]["themes_v1"]))
PY
read -r n_tools user_ok theme_left n_themes < "${SANDBOX}/nc_check"
check "инструменты пользователя целы, наши убраны" "$n_tools" "1"
check "настройка пользователя не тронута"          "$user_ok" "True"
check "наша тема снята"                            "$theme_left" "False"
check "тема пользователя цела"                     "$n_themes" "1"

# ── итог ─────────────────────────────────────────────────────────────────────
print ""
if (( FAIL == 0 )); then
    print -P "%F{green}%B✅ Все тесты пройдены: ${PASS}%f%b\n"
    exit 0
fi
print -P "%F{red}%B✗ Провалено: ${FAIL}, пройдено: ${PASS}%f%b\n"
exit 1
