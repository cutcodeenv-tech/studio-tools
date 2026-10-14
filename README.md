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

Открывается главное меню. Навигация от проекта: выбираешь проект один раз и делаешь с ним что нужно.

```
Studio Tools
▸ Проекты  ──────────►  Проекты · поиск
  Новый проект          ▸ Clients/2026-10-14_Film  ──►  Проекты › Clients/2026-10-14_Film
  Настройки               Personal/2026-10-01_Old       ▸ Статус
  Шаблон папок                                            Синхронизировать footage
  Обновить Studio Tools                                   Media Log (CSV)
  Выход                                                   Открыть папку
                                                          Архивировать
                                                          ← Назад
```

- **↑↓** — выбор, **Enter** — открыть
- **Esc** — на уровень выше (в списке проектов с поиском — Esc дважды)
- **Ctrl+C** — выход из приложения
- В списке проектов можно сразу печатать — поиск по названию

Каждую команду можно вызвать и напрямую:

| Команда         | Что делает                                              |
|-----------------|---------------------------------------------------------|
| `proj new`      | Создать проект на SSD и папки камер на HDD              |
| `proj open`     | Открыть папку проекта в Finder                          |
| `proj sync`     | Симлинки на footage с HDD + копирование прокси на SSD   |
| `proj status`   | Сколько исходников, симлинков и прокси по каждой камере |
| `proj archive`  | Перенести проект с SSD на HDD (со сверкой) и освободить SSD |
| `proj meta`     | `00_Admin/media_log.csv` с датой съёмки, кодеком, fps   |
| `proj settings` | Пути к SSD, HDD, шаблону Premiere                       |
| `proj template` | Открыть шаблон папок в Finder                           |
| `proj update`   | Обновиться с GitHub                                     |

### Новый проект

Создаёт структуру из `template/` на SSD и папки камер на HDD:

```
SSD/[001] Projects/2026-05-19_Project_Name/
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

HDD/2026-05-19_Project_Name/
└── 02_Sources/Video/Cam_a/  ← оригиналы footage
```

### Синхронизировать footage

После того как footage скопирован на HDD — создаёт симлинки в SSD-папке проекта.
Файлы из `Proxy/` копируются на SSD; недокачанные докачиваются при следующем запуске.

### Архивировать проект

Переносит папку проекта с SSD на HDD. Перед переносом проверяет, что на HDD нет других файлов с теми же путями; после — сверяет каждый файл. SSD очищается только если всё сошлось, иначе папка и симлинки остаются на месте.

## Конфиг

Пути хранятся в `~/.studio-tools/config` и меняются через `proj settings`:

```zsh
PROJECTS_PARENT_ROOT=""   # если задан — проекты лежат в подпапках-категориях
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
