#!/bin/bash

# Оборачивает phpcs --report=emacs (file:line:col: severity - message) и
# превращает единственный column в пару startCol:endCol, чтобы problem matcher
# в .vscode/tasks.json подсвечивал диапазон, а не один символ.
#
# Для правила Generic.Files.LineLength phpcs выдаёт col = общей длине строки.
# Ставим startCol = 1 (подсветить всю строку — она целиком «длинная»).
# Для других правил (если появятся) тоже выдаём диапазон 1..col — безопасный
# дефолт: подсветится от начала строки до места нарушения, а не один символ.

cd "$(dirname "$0")/.." || exit 1
XDEBUG_MODE=off composer cs-line-length -- --report=emacs 2>/dev/null \
    | sed -E 's#^(/[^:]+):([0-9]+):([0-9]+): (error|warning) - #\1:\2:1:\3: \4 - #'
