#!/bin/bash

# Перевірка наявності команди logger
if ! command -v logger &> /dev/null; then
    logger() { return 0; }
fi

LOG_DIR="$HOME/log"
LOG_FILE="$LOG_DIR/unx-pzpiz-22-1-karpov-dmytro-lab1.sh"

# Локалізація
if [[ "$LANG" == *"uk"* || "$LANG" == *"UA"* ]]; then
    ERR_PARAM="Помилка: Некоректний параметр"
    HELP_MSG="Використання: $0 [-h|--help]\n  -h, --help  Показати цю довідку"
    MSG_START="Запуск батьківського процесу"
    MSG_CHILD_START="Дочірній процес запущено з PID:"
    MSG_PROMPT="Оберіть дію (1: SIGUSR1, 2: SIGUSR2, 3: SIGTERM(вбити), 4: Статус, q: Вихід): "
else
    ERR_PARAM="Error: Invalid parameter"
    HELP_MSG="Usage: $0 [-h|--help]\n  -h, --help  Show this help"
    MSG_START="Parent process started"
    MSG_CHILD_START="Child process started with PID:"
    MSG_PROMPT="Choose action (1: SIGUSR1, 2: SIGUSR2, 3: SIGTERM(kill), 4: Status, q: Quit): "
fi

# Обробка параметрів
case "$1" in
    -h|--help)
        echo -e "$HELP_MSG"
        exit 0
        ;;
    ""|"child")

        ;;
    *)
        echo "$ERR_PARAM: $1" >&2
        logger -t "lab1-karpov" "Error: Invalid parameter $1"
        exit 1
        ;;
esac

mkdir -p "$LOG_DIR"

# Функція запису в лог
write_log() {
    local sig_num=$1
    local sig_name=$2
    local desc=$3
    
    local date_str=$(LC_ALL=C date -R)
    local timestamp=$(date +%s)
    local pid=$$
    
    echo "${date_str}; ${timestamp}; ${pid}; ${sig_num}; ${sig_name}; ${desc}" >> "$LOG_FILE"
}

# ==========================================
# ДОЧІРНІЙ ПРОЦЕС (якщо скрипт запущено з аргументом "child")
# ==========================================
if [ "$1" == "child" ]; then
    PARENT_PID=$2
    
    # Ігноруємо SIGHUP (щоб жити після смерті батька)
    trap '' SIGHUP
    
    # Обробка сигналів від батька
trap 'write_log "10" "SIGUSR1" "Child received SIGUSR1"; [ -d "/proc/$PARENT_PID" ] && kill -SIGUSR1 $PARENT_PID' SIGUSR1
    trap 'write_log "12" "SIGUSR2" "Child received SIGUSR2"; [ -d "/proc/$PARENT_PID" ] && kill -SIGUSR2 $PARENT_PID' SIGUSR2
    trap 'write_log "15" "SIGTERM" "Child received SIGTERM. Terminating."; logger -t "lab1-karpov" "Child $$ terminated by SIGTERM"; exit 0' SIGTERM
    
    write_log "0" "NONE" "Child process started"
    logger -t "lab1-karpov" "Child process created with PID $$"
    
    # Безкінечний цикл дочірнього процесу
    while true; do
        sleep 2
    done
    exit 0
fi

# ==========================================
# БАТЬКІВСЬКИЙ ПРОЦЕС (основна логіка)
# ==========================================

write_log "0" "NONE" "$MSG_START"
logger -t "lab1-karpov" "Script started. Parent PID: $$"

# Запускаємо САМ СЕБЕ як дочірній процес у фоні
"$0" child $$ &
CHILD_PID=$!

# Перехоплюємо підтвердження від доньки
trap 'echo -e "\n[!] Батько отримав підтвердження (ACK) від дочірнього процесу на SIGUSR1"; write_log "10" "SIGUSR1" "Parent received ACK for SIGUSR1"' SIGUSR1
trap 'echo -e "\n[!] Батько отримав підтвердження (ACK) від дочірнього процесу на SIGUSR2"; write_log "12" "SIGUSR2" "Parent received ACK for SIGUSR2"' SIGUSR2

echo "$MSG_CHILD_START $CHILD_PID"

# Інтерактивне меню батька
while true; do
    echo -n "$MSG_PROMPT"
    read action
    
    # Перевірка чи жива донька (kill -0)
    if ! kill -0 $CHILD_PID 2>/dev/null && [[ "$action" != "q" ]]; then
        echo "Дочірній процес ($CHILD_PID) вже завершив роботу."
        logger -t "lab1-karpov" "Parent detected child $CHILD_PID is dead."
        continue
    fi

    case "$action" in
        1)
            echo "Надсилаємо SIGUSR1 дочірньому процесу..."
            write_log "10" "SIGUSR1" "Parent sending SIGUSR1 to child"
            kill -SIGUSR1 $CHILD_PID
            sleep 1 # Чекаємо на відповідь
            ;;
        2)
            echo "Надсилаємо SIGUSR2 дочірньому процесу..."
            write_log "12" "SIGUSR2" "Parent sending SIGUSR2 to child"
            kill -SIGUSR2 $CHILD_PID
            sleep 1
            ;;
        3)
            echo "Надсилаємо SIGTERM (вбивство) дочірньому процесу..."
            write_log "15" "SIGTERM" "Parent sending SIGTERM to child"
            kill -SIGTERM $CHILD_PID
            sleep 1
            ;;
        4)
            echo "Статус дочірнього процесу ($CHILD_PID): ПРАЦЮЄ"
            ;;
        q)
            echo "Вихід із батьківського процесу. Дочірній процес залишиться працювати у фоні."
            write_log "0" "NONE" "Parent exiting"
            logger -t "lab1-karpov" "Parent $$ exiting."
            exit 0
            ;;
        *)
            echo "Невідома команда."
            ;;
    esac
done