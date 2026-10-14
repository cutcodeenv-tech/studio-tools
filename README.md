# Studio Tools

Терминальное приложение для управления видеопроектами: структура папок, синхронизация footage с HDD, архивирование, media log.

## Установка

Одна команда — клонирует в `~/.studio-tools` и настраивает всё автоматически:

**macOS / Linux:**
```zsh
git clone https://github.com/cutcodeenv-tech/studio-tools.git ~/.studio-tools && bash ~/.studio-tools/setup.sh && source ~/.zshrc
```

**Windows (Git Bash):**
```bash
git clone https://github.com/cutcodeenv-tech/studio-tools.git ~/.studio-tools && bash ~/.studio-tools/setup.sh
```

`setup.sh` определяет систему и ставит зависимости:
- macOS: Homebrew → [gum](https://github.com/charmbracelet/gum) (меню), mediainfo
- Windows: Scoop → zsh, gum, mediainfo

## Использование

```zsh
proj
```

Структура: **проект** — просто папка с названием (Nike), внутри него **серии** — папки с датой и шаблонной структурой (2026-10-14_Main_Spot).

```
Studio Tools                    Проекты (3)  · Esc Esc — назад
▸ Проекты              ──►      › Поиск…
  Новый проект                  ▸ 1  14 окт 2026   Nike          3 серии
  Настройки                       2  02 окт 2026   Adidas        1 серия
  Шаблон папок                    3  01 дек 2025   Old Wedding   серия без проекта
  Обновить Studio Tools
  Выход                                   │ Enter
                                          ▼
Проекты › Nike  (3 серии)               Проекты › Nike › Main Spot
▸ ＋ Новая серия                         ▸ Статус
  1  14 окт 2026   Cutdowns      ──►      Синхронизировать footage
  2  12 окт 2026   Main Spot              Media Log (CSV)
  3  01 окт 2026   Teaser                 Открыть папку
  Открыть папку проекта                   Архивировать
  ← Назад                                 ← Назад
```

- Проекты и серии пронумерованы и отсортированы по дате создания папки — сверху последняя.
- **«Новый проект»** создаёт папку проекта и сразу открывает её; серии создаются внутри через **«＋ Новая серия»**.
- **↑↓** — выбор, **Enter** — открыть, **Esc** — на уровень выше (в списке проектов с поиском — Esc дважды), **Ctrl+C** — выход.
- Серии, лежащие прямо в корне без проекта (старая раскладка), тоже видны в списке.

Каждую команду можно вызвать и напрямую:

| Команда            | Что делает                                                   |
|--------------------|--------------------------------------------------------------|
| `proj new-project` | Создать проект (папку для серий)                             |
| `proj new`         | Создать серию в проекте                                      |
| `proj open`        | Открыть папку серии в Finder                                 |
| `proj sync`        | Симлинки на footage с HDD + копирование прокси на SSD        |
| `proj status`      | Сколько исходников, симлинков и прокси по каждой камере      |
| `proj archive`     | Перенести серию с SSD на HDD (со сверкой) и освободить SSD   |
| `proj meta`        | `00_Admin/media_log.csv` с датой съёмки, кодеком, fps        |
| `proj settings`    | Пути к папке проектов, HDD, шаблону Premiere                 |
| `proj template`    | Открыть шаблон папок в Finder                                |
| `proj update`      | Обновиться с GitHub                                          |

### Новая серия

Создаёт структуру из `template/` на SSD и папки камер на HDD — HDD повторяет SSD:

```
SSD/[001] Projects/Nike/2026-10-14_Main_Spot/
├── 00_Admin/
├── 01_Project_Files/        (Premiere, DaVinci, AE, PS, AI, Audition)
├── 02_Sources/
│   ├── Audio/               (Music, SFX, VoiceOver)
│   ├── Graphics/            (Images, Vectors)
│   └── Video/
│       └── Cam_a/
│           └── Proxy/       ← реальная папка на SSD
├── 03_Exports/              (Drafts, Handoff, Master, Socials)
└── 99_Archive/

HDD/Nike/2026-10-14_Main_Spot/
└── 02_Sources/Video/Cam_a/  ← оригиналы footage
```

Серии, созданные раньше и лежащие на HDD плоско (`HDD/2026-…_Name`), находятся автоматически.

### Синхронизировать footage

После того как footage скопирован на HDD — создаёт симлинки в SSD-папке серии.
Файлы из `Proxy/` копируются на SSD; недокачанные докачиваются при следующем запуске.

### Архивировать

Переносит папку серии с SSD на HDD. Перед переносом проверяет, что на HDD нет других файлов с теми же путями; после — сверяет каждый файл. SSD очищается только если всё сошлось, иначе папка и симлинки остаются на месте.

## Конфиг

Пути хранятся в `~/.studio-tools/config` и меняются через `proj settings`:

```zsh
PROJECTS_PARENT_ROOT=""   # папка с проектами; если пусто — SSD_PROJECTS_ROOT
SSD_PROJECTS_ROOT="/Volumes/01_Extreme SSD/[001] Projects"
HDD_SOURCES_ROOT="/Volumes/HDD_1"
PREMIERE_TEMPLATE="/Volumes/01_Extreme SSD/[003] Resurces/00_TEMPLATE1.prproj"
```

## Удаление

```zsh
~/.studio-tools/uninstall.sh
```

Удаляет `~/bin/proj`, `~/bin/sf`, `~/.studio-tools` и убирает PATH из `~/.zshrc`.

## Разработка

```zsh
./push.sh
```

Коммитит изменения, пушит на GitHub и обновляет локальную команду `proj`.
