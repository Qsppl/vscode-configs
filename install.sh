#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Перебираем типичные точки монтирования Dev Container'ов:
#   - /workspaces/*/ — image-based Dev Container (VS Code template'ы).
#   - /app, /workspace, /code, /src, /srv/app, /var/www/html — compose-based
#     Dev Container, где workspace указывается в workspaceFolder и часто
#     совпадает с одним из этих путей.
# Имя проекта берём из URL origin remote (а не из basename workspace) —
# путь монтирования в dev-контейнере произвольный и не связан с именем репо.
# Если в dotfiles есть vscode-configs/<имя>/ — копируем оттуда в .vscode/.
shopt -s nullglob

for candidate in /workspaces/*/ /app /workspace /code /src /srv/app /var/www/html; do
    [ -d "$candidate/.git" ] || continue
    workspace="${candidate%/}"

    remote_url="$(git -C "$workspace" config --get remote.origin.url 2>/dev/null || true)"
    [ -z "$remote_url" ] && continue
    project="$(basename -s .git "$remote_url")"
    [ -z "$project" ] && continue

    source="$DOTFILES/vscode-configs/$project"
    [ -d "$source" ] || continue

    echo "dotfiles: applying .vscode config for $project → $workspace/.vscode/"
    mkdir -p "$workspace/.vscode"
    cp -r "$source/." "$workspace/.vscode/"
    find "$workspace/.vscode" -name '*.sh' -exec chmod +x {} \;
done
