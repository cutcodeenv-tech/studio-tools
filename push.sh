#!/bin/zsh

REPO_DIR="${0:A:h}"
cd "$REPO_DIR"

print -P "\n%B%F{cyan}Studio Tools — Git Push%f%b\n"

# Показываем изменения
git status --short

if [[ -z "$(git status --porcelain)" ]]; then
    print -P "\n%F{yellow}Нет изменений для коммита.%f\n"
    exit 0
fi

print -P "\n%B%F{cyan}│%f%b Сообщение коммита: \c"
read COMMIT_MSG

if [[ -z "$COMMIT_MSG" ]]; then
    print -P "%F{red}Отменено.%f\n"
    exit 0
fi

git add -A
git commit -m "$COMMIT_MSG"
git push

# Обновляем локальную команду и конфиги
cp "${REPO_DIR}/bin/proj" "$HOME/bin/proj"
chmod +x "$HOME/bin/proj"
print -P "  %F{green}✓%f  ~/bin/proj обновлён"

mkdir -p "$HOME/.config/yazi/plugins/proj.yazi"
cp "${REPO_DIR}/yazi/keymap.toml" "$HOME/.config/yazi/keymap.toml"
cp "${REPO_DIR}/yazi/yazi.toml"   "$HOME/.config/yazi/yazi.toml"
cp "${REPO_DIR}/yazi/plugins/proj.yazi/main.lua" "$HOME/.config/yazi/plugins/proj.yazi/main.lua"
print -P "  %F{green}✓%f  ~/.config/yazi обновлён"

print -P "\n%F{green}%B✅ Загружено на GitHub.%f%b\n"
