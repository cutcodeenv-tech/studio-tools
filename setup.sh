#!/bin/zsh

echo "\n▶ Studio Tools — Setup\n"

# 1. Homebrew
if ! command -v brew &>/dev/null; then
    echo "✗ Homebrew не найден. Установи его: https://brew.sh"
    exit 1
fi
echo "✓ Homebrew"

# 2. fzf
if ! command -v fzf &>/dev/null; then
    echo "⬇ Устанавливаю fzf..."
    brew install fzf
else
    echo "✓ fzf"
fi

# 3. ~/bin
mkdir -p "$HOME/bin"
echo "✓ ~/bin"

# 4. Копируем команды
SCRIPT_DIR="${0:A:h}"
cp "${SCRIPT_DIR}/bin/proj" "$HOME/bin/proj"
chmod +x "$HOME/bin/proj"
echo "✓ proj → ~/bin/"

# 5. PATH в .zshrc
if ! grep -q 'PATH.*HOME/bin\|HOME/bin.*PATH' "$HOME/.zshrc" 2>/dev/null; then
    echo '\nexport PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"
    echo "✓ PATH добавлен в ~/.zshrc"
else
    echo "✓ PATH уже в ~/.zshrc"
fi

echo "\n✅ Готово! Перезапусти терминал или выполни:\n"
echo "   source ~/.zshrc\n"
echo "Команда: proj\n"
