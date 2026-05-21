#!/usr/bin/env bash
# Запускай из папки куда клонирован репо:
#   git clone https://github.com/cutcodeenv-tech/studio-tools.git ~/.studio-tools
#   cd ~/.studio-tools && bash setup.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STUDIO_DIR="$HOME/.studio-tools"

# ── Detect OS ─────────────────────────────────────────────────────────────────
case "$OSTYPE" in
    darwin*)       _OS="macos" ;;
    msys*|cygwin*) _OS="windows" ;;
    linux*)        _OS="linux" ;;
    *)             _OS="unknown" ;;
esac

printf "\n▶ Studio Tools — Setup ($_OS)\n\n"

# ── Если репо не в ~/.studio-tools — копируем ─────────────────────────────────
if [[ "$SCRIPT_DIR" != "$STUDIO_DIR" ]]; then
    printf "→ Копирую в ~/.studio-tools...\n"
    mkdir -p "$STUDIO_DIR"
    cp -r "$SCRIPT_DIR/." "$STUDIO_DIR/"
    printf "✓ ~/.studio-tools\n"
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

# ── mpv (воспроизведение аудио/видео) ────────────────────────────────────────
if ! command -v mpv &>/dev/null; then
    printf "→ Устанавливаю mpv...\n"
    case "$_OS" in
        macos)   brew install mpv ;;
        windows) scoop install mpv ;;
        linux)   sudo apt-get install -y mpv 2>/dev/null || sudo dnf install -y mpv 2>/dev/null || printf "  Установи mpv вручную\n" ;;
    esac
else
    printf "✓ mpv\n"
fi

# ── Nerd Font ─────────────────────────────────────────────────────────────────
_font_ok=false
case "$_OS" in
    macos)
        { ls ~/Library/Fonts 2>/dev/null || ls /Library/Fonts 2>/dev/null; } | grep -qi "JetBrainsMono.*Nerd" && _font_ok=true
        ;;
    windows)
        ls "$USERPROFILE/AppData/Local/Microsoft/Windows/Fonts" 2>/dev/null | grep -qi "JetBrainsMono" && _font_ok=true
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

# ── ~/bin/proj + sf ───────────────────────────────────────────────────────────
mkdir -p "$HOME/bin"
cp "$STUDIO_DIR/bin/proj" "$HOME/bin/proj"
chmod +x "$HOME/bin/proj"
printf "✓ proj → ~/bin/\n"

if [[ -f "$STUDIO_DIR/bin/sf" ]]; then
    cp "$STUDIO_DIR/bin/sf" "$HOME/bin/sf"
    chmod +x "$HOME/bin/sf"
    printf "✓ sf → ~/bin/\n"
fi

# ── Nimble Commander tools ────────────────────────────────────────────────────
if [[ "$_OS" == "macos" ]]; then
    _NC_CONFIG="$HOME/Library/Application Support/Nimble Commander/Config/Config.json"
    _NC_TOOLS_SRC="$STUDIO_DIR/nimble-commander/tools.py"
    if [[ -f "$_NC_CONFIG" && -f "$_NC_TOOLS_SRC" ]]; then
        python3 "$_NC_TOOLS_SRC" "$_NC_CONFIG" && printf "✓ Nimble Commander tools\n" \
            || printf "⚠  Закрой Nimble Commander и повтори setup\n"
    fi
fi

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
