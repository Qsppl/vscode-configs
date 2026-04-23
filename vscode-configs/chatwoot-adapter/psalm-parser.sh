#!/bin/bash

# Прогоняет Psalm по всему проекту и выводит диагностику в формате,
# который парсит problemMatcher из .vscode/tasks.json.
# Формат строки: file\tline\tcol\tendLine\tendCol\tseverity\ttype\tmessage

set -e

report="$(mktemp -d)/psalm-report.json"
trap 'rm -rf "$(dirname "$report")"' EXIT

# Psalm возвращает exit=2 при найденных ошибках - это штатно, не фейлим скрипт.
# XDEBUG_MODE=off — без этого xdebug пробует коннектится к отсутствующему клиенту
# и заваливает терминал с ошибкой "Could not connect to debugging client".
XDEBUG_MODE=off composer psalm -- --report="$report" >/dev/null 2>&1 || true

[ -s "$report" ] || exit 0

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
