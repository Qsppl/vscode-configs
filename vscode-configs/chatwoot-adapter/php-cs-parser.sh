#!/bin/bash

# Оборачивает `make cs-check`: из unified-diff PHP CS Fixer вытаскивает
# строки с нарушениями и, где это возможно, показывает ожидаемое содержимое
# (новую строку из diff'а). Формат:
#   CS file:line:endCol: Should be: <new content>
# Парсится problem matcher'ом в .vscode/tasks.json.

make cs-check 2>&1 | awk '
    function flush(    i, new_content) {
        for (i = 1; i <= m_n; i++) {
            new_content = (i <= p_n) ? p_c[i] : ""
            # Обрезаем ведущие пробелы для удобочитаемости.
            sub(/^[[:space:]]+/, "", new_content)
            if (new_content == "") {
                printf "CS %s:%d:9999: Remove this line (run: make cs-fix)\n", file, m_l[i]
            } else {
                printf "CS %s:%d:9999: Should be: %s (run: make cs-fix)\n", file, m_l[i], new_content
            }
        }
        m_n = 0
        p_n = 0
    }

    /^\+\+\+ \/app\// { flush(); file = substr($0, 10); line = 0; next }
    /^@@ -/ {
        flush()
        hunk = $0
        sub(/^@@ -/, "", hunk)
        split(hunk, p, ",")
        line = p[1] + 0
        next
    }
    file == "" || line == 0 { next }
    /^---/ { next }
    /^\+\+\+/ { next }
    /^-/ {
        m_n++
        m_l[m_n] = line
        m_c[m_n] = substr($0, 2)
        line++
        next
    }
    /^\+/ {
        p_n++
        p_c[p_n] = substr($0, 2)
        next
    }
    /^ / { flush(); line++ }
    END { flush() }
'
