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

# ── superfile ─────────────────────────────────────────────────────────────────
if ! command -v spf &>/dev/null; then
    printf "→ Устанавливаю superfile...\n"
    case "$_OS" in
        macos)   brew install superfile ;;
        windows) scoop bucket add extras 2>/dev/null; scoop install superfile ;;
        linux)   brew install superfile 2>/dev/null || printf "  Установи superfile вручную: https://github.com/yorukot/superfile\n" ;;
    esac
else
    printf "✓ superfile\n"
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

# ── superfile config (hotkeys + config) ──────────────────────────────────────
case "$_OS" in
    macos)   _SPF_CFG="$HOME/Library/Application Support/superfile" ;;
    windows) _SPF_CFG="$APPDATA/superfile" ;;
    linux)   _SPF_CFG="$HOME/.config/superfile" ;;
esac

if [[ -d "$STUDIO_DIR/spf/superfile" ]]; then
    mkdir -p "$_SPF_CFG"
    cp "$STUDIO_DIR/spf/superfile/hotkeys.toml" "$_SPF_CFG/hotkeys.toml"
    cp "$STUDIO_DIR/spf/superfile/config.toml"  "$_SPF_CFG/config.toml"
    printf "✓ superfile config (hotkeys + theme)\n"
fi

# ── ~/bin/proj ────────────────────────────────────────────────────────────────
mkdir -p "$HOME/bin"
cp "$STUDIO_DIR/bin/proj" "$HOME/bin/proj"
chmod +x "$HOME/bin/proj"
printf "✓ proj → ~/bin/\n"

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
