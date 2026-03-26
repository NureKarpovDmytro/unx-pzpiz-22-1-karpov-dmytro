#!/bin/bash

if [[ "$LANG" == uk_UA* || "$LC_MESSAGES" == uk_UA* ]]; then
    MSG_HELP="Використання: $0 [-h|--help] [-n num] [file]"
    MSG_ERR_NUM="Помилка: -n повинно бути цілим числом >= 1"
    MSG_ERR_DIR="Помилка: не вдалося створити каталог"
    MSG_ERR_WRITE="Помилка: немає прав на запис у файл"
else
    MSG_HELP="Usage: $0 [-h|--help] [-n num] [file]"
    MSG_ERR_NUM="Error: -n must be an integer >= 1"
    MSG_ERR_DIR="Error: failed to create directory"
    MSG_ERR_WRITE="Error: no write permission for file"
fi

NUM_KEEP=0
TARGET_FILE="$HOME/log/task2.out"

show_help() {
    echo "$MSG_HELP"
    echo "  -h, --help    Show help info"
    echo "  -n num        Number of archive files to keep"
    echo "  file          Path to output file"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -n)
            shift
            if [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 1 ]; then
                NUM_KEEP=$1
            else
                echo "$MSG_ERR_NUM" >&2
                exit 1
            fi
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            TARGET_FILE="$1"
            ;;
    esac
    shift
done

DIR_PATH=$(dirname "$TARGET_FILE")
if [ ! -d "$DIR_PATH" ]; then
    mkdir -p "$DIR_PATH" || { echo "$MSG_ERR_DIR" >&2; exit 1; }
fi

if [ -f "$TARGET_FILE" ]; then
    CURRENT_DATE=$(date "+%Y%m%d")
    LAST_IDX=$(ls "$DIR_PATH" 2>/dev/null | grep -E "$(basename "$TARGET_FILE")-$CURRENT_DATE-[0-9]{4}" | wc -l)
    NEXT_IDX=$(printf "%04d" "$LAST_IDX")
    mv "$TARGET_FILE" "$TARGET_FILE-$CURRENT_DATE-$NEXT_IDX"
fi

LC_ALL=C date "+Date: %a, %d %b %Y %H:%M:%S %z" > "$TARGET_FILE" || { echo "$MSG_ERR_WRITE" >&2; exit 1; }

if [ "$NUM_KEEP" -gt 0 ]; then
    cd "$DIR_PATH" || exit 1
    BASE_NAME=$(basename "$TARGET_FILE")
    ls -t "$BASE_NAME"-* 2>/dev/null | tail -n +$((NUM_KEEP + 1)) | xargs -r rm -f
fi

exit 0