#!/bin/bash

# Прогоняет Psalm по всему проекту и выводит диагностику в формате,
# который парсит problemMatcher из .vscode/tasks.json.
# Формат строки: file|line|col|endLine|endCol|severity|type|message

set -e

report="$(mktemp -d)/psalm-report.json"
log="$(dirname "$report")/psalm.log"
trap 'rm -rf "$(dirname "$report")"' EXIT

config="$PWD/psalm.xml"

# Psalm возвращает exit=2 при найденных ошибках - это штатно, не фейлим скрипт.
# XDEBUG_MODE=off — без этого xdebug пробует коннектится к отсутствующему клиенту
# и заваливает терминал с ошибкой "Could not connect to debugging client".
# Вывод копим в $log: при поломке конфига Psalm пишет причину туда, а не в отчёт.
XDEBUG_MODE=off composer psalm -- --report="$report" >"$log" 2>&1 || true

# Пустой отчёт = Psalm не дошёл до анализа. Чаще всего это поломка psalm.xml:
# <file name> указывает на несуществующий путь (например, после переезда файла),
# Psalm падает на парсинге конфига ДО анализа и не пишет отчёт. Тогда в Problems
# пусто и поломка остаётся незаметной — сами выводим диагностику на psalm.xml.
if [ ! -s "$report" ]; then
    if grep -q "Problem parsing" "$log"; then
        missing="$(grep -oE "Could not resolve config path to .+" "$log" | head -1 \
            | sed 's/Could not resolve config path to //' | tr -d '\r' || true)"
        line=1
        col=1
        msg="Psalm не смог распарсить psalm.xml — статический анализ не выполнен"
        if [ -n "$missing" ]; then
            rel="${missing#"$PWD"/}"
            found="$(grep -nF "$rel" "$config" | head -1 | cut -d: -f1 || true)"
            [ -n "$found" ] && line="$found"
            msg="Psalm: путь в psalm.xml не существует: $rel — статический анализ не выполнен"
        fi
        # Подсветка: если знаем битый путь — выделяем сам путь внутри строки,
        # иначе всю строку (col..конец). Колонки 1-based, endCol эксклюзивный.
        linetext="$(sed -n "${line}p" "$config")"
        if [ -n "$missing" ] && [ "${linetext#*"$rel"}" != "$linetext" ]; then
            prefix="${linetext%%"$rel"*}"
            col=$(( ${#prefix} + 1 ))
            endcol=$(( col + ${#rel} ))
        else
            endcol=$(( ${#linetext} + 1 ))
        fi
        printf "%s|%d|%d|%d|%d|%s|%s|%s\n" "$config" "$line" "$col" "$line" "$endcol" "error" "ConfigError" "$msg"
    fi
    exit 0
fi

XDEBUG_MODE=off php -r '
$data = json_decode(file_get_contents($argv[1]), true);

if (!is_array($data)) {
	exit(0);
}

foreach ($data as $i) {
    $msg = str_replace(["|", "\n", "\r"], " ", $i["message"] ?? "");
    printf("%s|%d|%d|%d|%d|%s|%s|%s\n",
        $i["file_path"] ?? "",
        $i["line_from"] ?? 0,
        $i["column_from"] ?? 0,
        $i["line_to"] ?? 0,
        $i["column_to"] ?? 0,
        $i["severity"] ?? "error",
        $i["type"] ?? "",
        $msg
    );
}
' "$report"
