
#!/bin/bash

# ==========================================
# 1. ЛОКАЛІЗАЦІЯ ТА НАЛАШТУВАННЯ
# ==========================================
if [[ "$LANG" == *"uk"* || "$LC_MESSAGES" == *"uk"* ]]; then
    MSG_HELP="Використання: $0 [-h|--help] [-n num] [file]\n  -h, --help  Виведення довідки\n  -n num      Максимальна кількість архівних файлів\n  file        Файл для запису результату"
    MSG_ERR_NUM="Помилка: параметр -n повинен бути цілим числом >= 1"
    MSG_ERR_DIR="Помилка: не вдалося створити каталог"
    MSG_ERR_PARAM="Помилка: невідомий параметр"
else
    MSG_HELP="Usage: $0 [-h|--help] [-n num] [file]\n  -h, --help  Show help\n  -n num      Maximum number of archive files\n  file        File to write the result"
    MSG_ERR_NUM="Error: parameter -n must be an integer >= 1"
    MSG_ERR_DIR="Error: failed to create directory"
    MSG_ERR_PARAM="Error: unknown parameter"
fi

NUM_KEEP=0
TARGET_FILE="$HOME/log/task2.out"

# ==========================================
# 2. ОБРОБКА ПАРАМЕТРІВ (CLI)
# ==========================================
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo -e "$MSG_HELP"
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
            echo "$MSG_ERR_PARAM: $1" >&2
            exit 1
            ;;
        *)
            TARGET_FILE="$1"
            ;;
    esac
    shift
done

# ==========================================
# 3. КЕРУВАННЯ КАТАЛОГАМИ ТА РОТАЦІЯ
# ==========================================
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

if [ "$NUM_KEEP" -gt 0 ]; then
    cd "$DIR_PATH" || exit 1
    BASE_NAME=$(basename "$TARGET_FILE")
    ls -t "$BASE_NAME"-* 2>/dev/null | tail -n +$((NUM_KEEP + 1)) | xargs -r rm -f
    cd - >/dev/null || exit 1
fi

# ==========================================
# 4. ФУНКЦІЯ ЗБОРУ ДАНИХ (ГЕНЕРАЦІЯ ЗВІТУ)
# ==========================================
generate_report() {
    # --- Час (один момент часу для обох значень) ---
    DATETIME=$(LC_ALL=C date "+%s|Date: %a, %d %b %Y %H:%M:%S %z")
    TS=$(echo "$DATETIME" | cut -d'|' -f1)
    D_STR=$(echo "$DATETIME" | cut -d'|' -f2)

    # --- Hardware ---
    CPU_INFO=$(grep -m 1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs)
    [ -z "$CPU_INFO" ] && CPU_INFO="Unknown"

    RAM_KB=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
    [ -n "$RAM_KB" ] && RAM_MB=$((RAM_KB / 1024)) || RAM_MB="Unknown"

    # Функція для безпечного читання dmidecode
    get_dmi() {
        local val=$(dmidecode -s "$1" 2>/dev/null | grep -v '^#' | head -n 1 | xargs)
        if [ -z "$val" ] && [ -f "$HOME/dmidecode.out" ]; then
            if [ "$1" == "baseboard-manufacturer" ]; then val=$(grep -i "Manufacturer:" "$HOME/dmidecode.out" | head -n 1 | cut -d: -f2 | xargs); fi
            if [ "$1" == "baseboard-product-name" ]; then val=$(grep -i "Product Name:" "$HOME/dmidecode.out" | head -n 1 | cut -d: -f2 | xargs); fi
            if [ "$1" == "system-serial-number" ]; then val=$(grep -i "Serial Number:" "$HOME/dmidecode.out" | head -n 1 | cut -d: -f2 | xargs); fi
        fi
        [ -z "$val" ] && echo "Unknown" || echo "$val"
    }

    MB_MANUF=$(get_dmi "baseboard-manufacturer")
    MB_PROD=$(get_dmi "baseboard-product-name")
    SYS_SERIAL=$(get_dmi "system-serial-number")

    # --- System ---
    OS_DIST=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
    [ -z "$OS_DIST" ] && OS_DIST="Unknown"

    KERNEL=$(uname -r 2>/dev/null || echo "Unknown")

    INSTALL_DATE=$(stat -c %w / 2>/dev/null)
    [ "$INSTALL_DATE" == "-" ] || [ -z "$INSTALL_DATE" ] && INSTALL_DATE=$(stat -c %y / 2>/dev/null | cut -d. -f1)
    [ -z "$INSTALL_DATE" ] && INSTALL_DATE="Unknown"

    H_NAME=$(hostname 2>/dev/null || echo "Unknown")
    
    UPTIME_VAL=$(uptime -p 2>/dev/null)
    [ -z "$UPTIME_VAL" ] && UPTIME_VAL=$(uptime 2>/dev/null | xargs)
    [ -z "$UPTIME_VAL" ] && UPTIME_VAL="Unknown"

    PROC_COUNT=$(ps -e --no-headers 2>/dev/null | wc -l)
    [ "$PROC_COUNT" -eq 0 ] && PROC_COUNT=$(ls -d /proc/[0-9]* 2>/dev/null | wc -l) # фолбек
    [ "$PROC_COUNT" -eq 0 ] && PROC_COUNT="Unknown"

    USER_COUNT=$(who 2>/dev/null | wc -l)

    # --- ВИВІД ---
    echo "$D_STR"
    echo "Unix Timestamp: $TS"
    echo "---- Hardware ----"
    echo "CPU: \"$CPU_INFO\""
    echo "RAM: $RAM_MB MB"
    echo "Motherboard: \"$MB_MANUF\", \"$MB_PROD\""
    echo "System Serial Number: $SYS_SERIAL"
    echo "---- System ----"
    echo "OS Distribution: \"$OS_DIST\""
    echo "Kernel version: $KERNEL"
    echo "Installation date: $INSTALL_DATE"
    echo "Hostname: $H_NAME"
    echo "Uptime: $UPTIME_VAL"
    echo "Processes running: $PROC_COUNT"
    echo "Users logged in: $USER_COUNT"
    echo "---- Network ----"

    if command -v ip >/dev/null 2>&1; then
        for iface in $(ip -o link show | awk -F': ' '{print $2}'); do
            ip_info=$(ip -o -4 addr show dev "$iface" 2>/dev/null | awk '{print $4}')
            if [ -z "$ip_info" ]; then
                echo "$iface: -/-"
            else
                echo "$iface: $ip_info"
            fi
        done
    else
        echo "Unknown: -/-"
    fi

    echo "----\"EOF\"----"
}

# ==========================================
# 5. ВИКОНАННЯ ТА ЗАПИС У ФАЙЛ (tee)
# ==========================================
generate_report | tee "$TARGET_FILE"

exit 0