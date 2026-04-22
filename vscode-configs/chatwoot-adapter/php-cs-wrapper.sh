#!/bin/bash

# Обёртка для vendor/bin/php-cs-fixer, которая меняет cwd на корень проекта
# перед запуском. Нужна потому, что расширение junstyle.php-cs-fixer не
# позволяет настроить cwd, а запускается из папки форматируемого файла.
# PHP CS Fixer же читает composer.json ТОЛЬКО из текущего cwd (без walk-up),
# из-за чего в extension-output сыпался warning
# "Unable to determine minimum PHP version supported by your project from composer.json".

cd "$(dirname "$0")/.." && exec vendor/bin/php-cs-fixer "$@"
