#!/usr/bin/env bash
# Установка одной командой:
#   bash <(curl -fsSL https://raw.githubusercontent.com/cutcodeenv-tech/studio-tools/main/setup.sh)

STUDIO_DIR="$HOME/.studio-tools"
REPO_URL="https://github.com/cutcodeenv-tech/studio-tools.git"

# ── Detect OS ─────────────────────────────────────────────────────────────────
case "$OSTYPE" in
    darwin*)       _OS="macos" ;;
    msys*|cygwin*) _OS="windows" ;;
    linux*)        _OS="linux" ;;
    *)             _OS="unknown" ;;
esac

printf "\n▶ Studio Tools — Setup ($_OS)\n\n"

# ── Клонируем или обновляем репо ──────────────────────────────────────────────
if [[ -d "$STUDIO_DIR/.git" ]]; then
    printf "→ Обновляю ~/.studio-tools...\n"
    git -C "$STUDIO_DIR" pull --ff-only && printf "✓ ~/.studio-tools\n"
else
    # Папка может существовать без .git (старая версия) — сохраняем config
    if [[ -d "$STUDIO_DIR" ]]; then
        printf "→ ~/.studio-tools существует без git — переклонирую (config сохранится)...\n"
        [[ -f "$STUDIO_DIR/config" ]] && cp "$STUDIO_DIR/config" /tmp/_studio_config_backup
        rm -rf "$STUDIO_DIR"
    fi
    printf "→ Клонирую в ~/.studio-tools...\n"
    git clone "$REPO_URL" "$STUDIO_DIR" && printf "✓ ~/.studio-tools\n"
    # Восстанавливаем config если был
    if [[ -f /tmp/_studio_config_backup ]]; then
        cp /tmp/_studio_config_backup "$STUDIO_DIR/config"
        rm /tmp/_studio_config_backup
        printf "✓ config восстановлен\n"
    fi
fi

# ── Package manager ───────────────────────────────────────────────────────────
case "$_OS" in
    macos)
        if ! command -v brew &>/dev/null; then
            printf "✗ Homebrew не найден: https://brew.sh\n"; exit 1
        fi
        printf "✓ Homebrew\n"
        ;;
    windows)
        if ! command -v scoop &>/dev/null; then
            printf "→ Устанавливаю Scoop...\n"
            powershell -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; irm get.scoop.sh | iex"
            export PATH="$HOME/scoop/shims:$PATH"
        fi
        printf "✓ Scoop\n"
        if ! command -v zsh &>/dev/null; then
            printf "→ Устанавливаю zsh...\n"
            scoop install zsh
        fi
        printf "✓ zsh\n"
        ;;
esac

# ── fzf ───────────────────────────────────────────────────────────────────────
if ! command -v fzf &>/dev/null; then
    printf "→ Устанавливаю fzf...\n"
    case "$_OS" in
        macos)   brew install fzf ;;
        windows) scoop install fzf ;;
        linux)   sudo apt-get install -y fzf 2>/dev/null || sudo dnf install -y fzf 2>/dev/null || printf "  Установи fzf вручную\n" ;;
    esac
else
    printf "✓ fzf\n"
fi

# ── Nimble Commander ─────────────────────────────────────────────────────────
if [[ "$_OS" == "macos" ]]; then
    if ! osascript -e 'id of app "Nimble Commander"' &>/dev/null 2>&1 && \
       ! ls /Applications/Nimble\ Commander.app &>/dev/null 2>&1; then
        printf "→ Устанавливаю Nimble Commander...\n"
        brew install --cask nimble-commander
    else
        printf "✓ Nimble Commander\n"
    fi
fi

# ── mpv + mediainfo + dust ────────────────────────────────────────────────────
_brew_install() {
    local pkg="$1"
    if ! command -v "$pkg" &>/dev/null; then
        printf "→ Устанавливаю %s...\n" "$pkg"
        case "$_OS" in
            macos)   brew install "$pkg" ;;
            windows) scoop install "$pkg" ;;
            linux)   sudo apt-get install -y "$pkg" 2>/dev/null || sudo dnf install -y "$pkg" 2>/dev/null || printf "  Установи %s вручную\n" "$pkg" ;;
        esac
    else
        printf "✓ %s\n" "$pkg"
    fi
}

_brew_install mpv
_brew_install mediainfo
_brew_install dust

# ── Nerd Font ─────────────────────────────────────────────────────────────────
# Шрифт ищем глобом, а не `ls | grep`: имена файлов шрифтов содержат
# пробелы и дефисы, на которых разбор вывода ls ненадёжен
_font_installed() {
    local dir pattern
    for dir in "$@"; do
        [[ -d "$dir" ]] || continue
        for pattern in "$dir"/JetBrainsMono*Nerd* "$dir"/JetBrainsMono-NF*; do
            [[ -e "$pattern" ]] && return 0
        done
    done
    return 1
}

_font_ok=false
case "$_OS" in
    macos)
        _font_installed "$HOME/Library/Fonts" "/Library/Fonts" && _font_ok=true
        ;;
    windows)
        _font_installed "$USERPROFILE/AppData/Local/Microsoft/Windows/Fonts" \
                        "$HOME/AppData/Local/Microsoft/Windows/Fonts" && _font_ok=true
        ;;
    linux)
        fc-list 2>/dev/null | grep -qi "JetBrains.*Nerd" && _font_ok=true
        ;;
esac

if [[ "$_font_ok" == false ]]; then
    printf "→ Устанавливаю JetBrains Mono Nerd Font...\n"
    case "$_OS" in
        macos)   brew install --cask font-jetbrains-mono-nerd-font ;;
        windows) scoop bucket add nerd-fonts 2>/dev/null; scoop install JetBrainsMono-NF ;;
        linux)   brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null || printf "  Установи шрифт вручную\n" ;;
    esac
    printf "  ⚠  Выбери 'JetBrainsMono Nerd Font' в настройках терминала\n"
else
    printf "✓ JetBrains Mono Nerd Font\n"
fi

# ── Раскладка файлов ──────────────────────────────────────────────────────────
# Вся логика деплоя живёт в bin/deploy — здесь её не дублируем.
chmod +x "$STUDIO_DIR/bin/proj" "$STUDIO_DIR/bin/deploy"
zsh "$STUDIO_DIR/bin/deploy" || printf "⚠  Деплой завершился с ошибками\n"

# ── PATH ──────────────────────────────────────────────────────────────────────
_add_path() {
    local rc="$1"
    [[ -f "$rc" ]] || return
    grep -q 'HOME/bin' "$rc" && return
    printf '\nexport PATH="$HOME/bin:$PATH"\n' >> "$rc"
    printf "✓ PATH → %s\n" "$rc"
}

case "$_OS" in
    macos)   _add_path "$HOME/.zshrc" ;;
    windows|linux) _add_path "$HOME/.bashrc"; _add_path "$HOME/.bash_profile" ;;
esac

printf "\n✅ Готово!\n\n"
printf "  Перезапусти терминал или: source ~/.zshrc\n"
printf "  Затем введи: proj\n\n"
