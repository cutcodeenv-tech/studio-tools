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

# Деплоим локально
cp "${REPO_DIR}/bin/proj" "$HOME/bin/proj" && chmod +x "$HOME/bin/proj"
print -P "  %F{green}✓%f  ~/bin/proj"

cp "${REPO_DIR}/bin/sf" "$HOME/bin/sf" && chmod +x "$HOME/bin/sf"
print -P "  %F{green}✓%f  ~/bin/sf"

if [[ -f "${REPO_DIR}/nimble-commander/minfo.applescript" ]]; then
    osacompile -o "$HOME/bin/minfo.app" "${REPO_DIR}/nimble-commander/minfo.applescript" 2>/dev/null \
        && print -P "  %F{green}✓%f  minfo.app" \
        || print -P "  %F{yellow}⚠%f  minfo.app не скомпилирован"
fi

_NC_CONFIG="$HOME/Library/Application Support/Nimble Commander/Config/Config.json"
if [[ -f "$_NC_CONFIG" ]]; then
    python3 "${REPO_DIR}/nimble-commander/tools.py" "$_NC_CONFIG" \
        && print -P "  %F{green}✓%f  Nimble Commander (тема + настройки)" \
        || print -P "  %F{yellow}⚠%f  NC: закрой приложение и повтори"
fi

print -P "\n%F{green}%B✅ Загружено на GitHub.%f%b\n"
