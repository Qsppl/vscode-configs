#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Перебираем типичные точки монтирования Dev Container'ов:
#   - /workspaces/*/ — image-based Dev Container (VS Code template'ы).
#   - /app, /workspace, /code, /src, /srv/app, /var/www/html — compose-based
#     Dev Container, где workspace указывается в workspaceFolder и часто бывает
#     одним из этих путей.
# Для каждой точки проверяем: это git-репо → получаем имя проекта
# через basename git-top-level. Если в dotfiles есть
# projects/<имя>/ — копируем оттуда .vscode/.
for candidate in /workspaces/*/ /app /workspace /code /src /srv/app /var/www/html; do
    [ -d "$candidate/.git" ] || continue
    workspace="${candidate%/}"
    project="$(basename "$(git -C "$workspace" rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || true)"
    [ -z "$project" ] && continue

    source="$DOTFILES/projects/$project"
    [ -d "$source" ] || continue

    echo "dotfiles: applying .vscode config for $project → $workspace/.vscode/"
    mkdir -p "$workspace/.vscode"
    cp -r "$source/." "$workspace/.vscode/"
    find "$workspace/.vscode" -name '*.sh' -exec chmod +x {} \;
done
