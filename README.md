# Studio Tools

Терминальные инструменты для управления видеопроектами: создание структуры папок, синхронизация footage с HDD.

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

`setup.sh` автоматически определяет систему и устанавливает все зависимости:
- macOS: Homebrew → fzf, superfile, JetBrains Mono Nerd Font
- Windows: Scoop → zsh, fzf, superfile, JetBrainsMono-NF

После установки выбери **JetBrainsMono Nerd Font** в настройках терминала для отображения иконок.

## Использование

```zsh
proj
```

При запуске открывается меню:

```
╭─ proj ────────────────────────╮
│ ▶ Новый проект                │
│   Синхронизировать footage    │
╰───────────────────────────────╯
```

### Новый проект

Создаёт структуру папок на SSD и HDD:

```
SSD/[001] Projects/2026-05-19_Project_Name/
├── 00_Admin/
├── 01_Project_Files/         (Premiere, DaVinci, AE, PS, AI, Audition)
├── 02_Sources/
│   └── Video/
│       └── Cam_a/
│           └── Proxy/        ← реальная папка на SSD
├── 03_Proxies/
├── 04_Exports/
└── 99_Archive/

HDD/Project_Name/
└── 02_Sources/Video/Cam_a/   ← оригиналы footage
```

### Синхронизировать footage

После того как footage скопирован на HDD — создаёт симлинки в SSD-папке проекта.
Файлы в `Proxy/` копируются на SSD как оригиналы.

## Конфиг

Пути настраиваются в начале `bin/proj`:

```zsh
SSD_PROJECTS_ROOT="/Volumes/01_Extreme SSD/[001] Projects"
HDD_SOURCES_ROOT="/Volumes/HDD_1"
PREMIERE_TEMPLATE="/Volumes/01_Extreme SSD/[003] Resurces/00_TEMPLATE1.prproj"
```

## Удаление

```zsh
~/.studio-tools/uninstall.sh
```

Удаляет `~/bin/proj`, `~/.studio-tools` и убирает PATH из `~/.zshrc`.

## Обновление

```zsh
./push.sh
```

Коммитит изменения, пушит на GitHub и обновляет локальную команду `proj`.
