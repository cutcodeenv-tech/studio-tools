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

# ── yazi ─────────────────────────────────────────────────────────────────────
if ! command -v yazi &>/dev/null; then
    printf "→ Устанавливаю yazi...\n"
    case "$_OS" in
        macos)   brew install yazi ;;
        windows) scoop install yazi ;;
        linux)   brew install yazi 2>/dev/null || printf "  Установи yazi вручную: https://github.com/sxyazi/yazi\n" ;;
    esac
else
    printf "✓ yazi\n"
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

# ── yazi config (keymap + settings) ──────────────────────────────────────────
case "$_OS" in
    macos|linux) _YAZI_CFG="$HOME/.config/yazi" ;;
    windows)     _YAZI_CFG="${APPDATA}/yazi/config" ;;
esac

if [[ -d "$STUDIO_DIR/yazi" ]]; then
    mkdir -p "$_YAZI_CFG/plugins/proj.yazi"
    cp "$STUDIO_DIR/yazi/keymap.toml"  "$_YAZI_CFG/keymap.toml"
    cp "$STUDIO_DIR/yazi/yazi.toml"    "$_YAZI_CFG/yazi.toml"
    cp "$STUDIO_DIR/yazi/theme.toml"   "$_YAZI_CFG/theme.toml"
    cp "$STUDIO_DIR/yazi/package.toml" "$_YAZI_CFG/package.toml"
    cp "$STUDIO_DIR/yazi/plugins/proj.yazi/main.lua" "$_YAZI_CFG/plugins/proj.yazi/main.lua"
    ya pkg install 2>/dev/null && printf "✓ yazi config + proj plugin + catppuccin тема\n" || printf "✓ yazi config + proj plugin\n"
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
