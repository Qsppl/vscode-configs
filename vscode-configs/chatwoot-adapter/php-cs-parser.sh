#!/bin/bash

# Запускает php-cs-fixer в dry-run режиме через composer, забирает его unified-diff
# и печатает по строке на нарушение в формате, который парсит problem matcher
# из .vscode/tasks.json:
#   CS file:line:endCol: Should be: <new content>
#
# Прямой вызов composer, без make: так парсер получает только вывод fixer'а,
# а не смесь с phpcs (объединение fixer+phpcs живёт в Makefile/CI).

cd "$(dirname "$0")/.." || exit 1

# PHP CS Fixer v3.95+ в разных shell-окружениях отдаёт то JSON, то обычный
# unified diff (эвристика @auto + параллельный режим). Буферизуем вывод в
# переменную и, если он начинается с `{` — вытягиваем diff-поля из JSON;
# иначе отдаём awk как есть.
raw="$(XDEBUG_MODE=off composer cs-check 2>/dev/null)"

case "$raw" in
    '{'*)
        raw="$(printf '%s' "$raw" | php -r '
            $data = json_decode(stream_get_contents(STDIN), true);
            if (!is_array($data) || empty($data["files"])) exit(0);
            foreach ($data["files"] as $f) {
                if (!empty($f["diff"])) echo $f["diff"], "\n";
            }
        ')"
        ;;
esac

printf '%s\n' "$raw" | awk '
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
