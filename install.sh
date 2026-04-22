#!/bin/bash
set -e

# VS Code Server клонирует этот репо в ~/dotfiles и запускает install.sh
# ДО того, как workspace откроется. Поэтому файлы .vscode/ успевают появиться,
# и Workspace Settings подхватываются корректно.

DOTFILES="$(dirname "$(realpath "$0")")"

# Ищем workspace-директорию (в Dev Container'е она всегда в /workspaces/)
for workspace in /workspaces/*/; do
    project_name=$(basename "$workspace")
    config_src="$DOTFILES/vscode-configs/$project_name"

    if [ -d "$config_src" ]; then
        echo "Applying .vscode config for $project_name"
        mkdir -p "$workspace.vscode"
        cp -r "$config_src"/* "$workspace.vscode/"
        # sh-скрипты делаем исполняемыми
        find "$workspace.vscode" -name '*.sh' -exec chmod +x {} \;
    fi
done
