#!/bin/zsh

echo "\n▶ Studio Tools — Uninstall\n"

rm -f "$HOME/bin/proj" "$HOME/bin/sf"
rm -rf "$HOME/bin/minfo.app"
echo "✓ ~/bin/proj, ~/bin/sf удалены"

rm -rf "$HOME/.studio-tools"
echo "✓ ~/.studio-tools удалён"

if [[ -f "$HOME/.zshrc" ]]; then
    sed -i '' '/export PATH="\$HOME\/bin:\$PATH"/d' "$HOME/.zshrc"
    echo "✓ PATH удалён из ~/.zshrc"
fi

echo "\n✅ Готово. Перезапусти терминал.\n"
