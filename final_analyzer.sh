#!/bin/bash

#
# Security Analyzer
#
# Этот скрипт выполняет автоматический аудит безопасности системы,
# отправляет собранные данные на анализ в OpenAI и уведомляет
# пользователя о результатах через Telegram.
#
# Версия: 1.1
#

# --- БЕЗОПАСНОСТЬ: ПРОВЕРКА ПРАВ ---
# Скрипт должен выполняться с правами суперпользователя (root),
# так как многие команды требуют повышенных привилегий для сбора данных.
if [ "$(id -u)" -ne 0 ]; then
  echo "Ошибка: Этот скрипт необходимо запускать с правами sudo." >&2
  exit 1
fi

# --- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ И НАСТРОЙКИ ---

# Временный файл для хранения сырого отчета
REPORT_FILE="/tmp/security_report_$(date +%s).txt"
# Путь к системному логу аутентификации
LOG_AUTH="/var/log/auth.log"
# Директория для сохранения финальных отчетов
ANALYSIS_REPORTS_DIR="analysis_reports"
# Создаем директорию, если она не существует
mkdir -p "${ANALYSIS_REPORTS_DIR}"

# --- НАСТРОЙКИ API ---

# Конфигурация OpenAI
OPENAI_CONF="Security-Analyzer-Project/openai.conf" # Путь к файлу с API-ключом
MODEL="gpt-4o-mini"                               # Модель для анализа
OPENAI_API_URL="https://api.openai.com/v1/chat/completions"

# Конфигурация Telegram
TELEGRAM_CONF="Security-Analyzer-Project/telegram.conf" # Путь к файлу с токеном и ID чата

# --- ЗАГРУЗКА И ПРОВЕРКА КОНФИГУРАЦИЙ ---

# Проверяем и загружаем конфигурацию OpenAI
if [ ! -f "${OPENAI_CONF}" ]; then
    echo "-----------------------------------------------------"
    echo "ОШИБКА: Файл конфигурации ${OPENAI_CONF} не найден."
    echo "Пожалуйста, создайте его по примеру openai.conf.example."
    echo "-----------------------------------------------------"
    exit 1
fi
source "${OPENAI_CONF}" # Загружаем переменные из файла
if [ -z "${OPENAI_API_KEY}" ]; then
    echo "-----------------------------------------------------"
    echo "ОШИБКА: Переменная OPENAI_API_KEY не найдена в файле ${OPENAI_CONF}."
    echo "-----------------------------------------------------"
    exit 1
fi

# Проверяем и загружаем конфигурацию Telegram
if [ ! -f "${TELEGRAM_CONF}" ]; then
    echo "-----------------------------------------------------"
    echo "ОШИБКА: Файл конфигурации ${TELEGRAM_CONF} не найден."
    echo "Пожалуйста, создайте его по примеру telegram.conf.example."
    echo "-----------------------------------------------------"
    exit 1
fi
source "${TELEGRAM_CONF}" # Загружаем переменные из файла
if [ -z "${BOT_TOKEN}" ] || [ -z "${CHAT_ID}" ]; then
    echo "-----------------------------------------------------"
    echo "ОШИБКА: BOT_TOKEN или CHAT_ID не найдены в файле ${TELEGRAM_CONF}."
    echo "-----------------------------------------------------"
    exit 1
fi

# --- ФУНКЦИИ ---

#
# Отправляет текстовое сообщение в Telegram.
#
# $1 - Текст сообщения для отправки.
#
send_telegram_notification() {
    local message="$1"
    local url="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"

    # Используем curl для отправки POST-запроса к API Telegram
    curl -s -X POST "$url" --data-urlencode "chat_id=${CHAT_ID}" --data-urlencode "text=${message}" > /dev/null
    echo "Уведомление отправлено в Telegram."
}


# --- ОСНОВНАЯ ЛОГИКА: СБОР ДАННЫХ ---

echo "Начинаю сбор данных для отчета..."

# Весь вывод команд внутри блока {} будет перенаправлен в $REPORT_FILE
{
    echo "--- ОТЧЕТ БЕЗОПАСНОСТИ СЕРВЕРА ---"
    echo "Дата генерации: $(date)"
    echo "Имя хоста: $(hostname)"
    echo ""

    # 1. Проверка на руткиты
    echo "--- 1. Результат chkrootkit ---"
    chkrootkit
    echo ""

    # 2. Статус сервиса Fail2Ban для защиты SSH
    echo "--- 2. Статус Fail2Ban (sshd) ---"
    fail2ban-client status sshd
    echo ""

    # 3. Список пакетов, доступных для обновления
    echo "--- 3. Список пакетов для обновления ---"
    apt list --upgradable
    echo ""

    # 4. Текущие правила межсетевого экрана
    echo "--- 4. Правила файрвола (iptables) ---"
    iptables -L -v -n
    echo ""

    # 5. Открытые TCP и UDP порты
    echo "--- 5. Открытые порты (netstat) ---"
    netstat -tuln
    echo ""

    # 6. История последних входов в систему
    echo "--- 6. Последние 20 входов в систему (last) ---"
    last -n 20
    echo ""

    # 7. Поиск неудачных попыток входа по паролю
    echo "--- 7. Неудачные попытки входа (auth.log) ---"
    if [ -f "${LOG_AUTH}" ]; then
      grep "Failed password" "${LOG_AUTH}" | tail -n 20
    else
      echo "Файл лога ${LOG_AUTH} не найден."
    fi
    echo ""

    # 8. Список пользователей с правами sudo
    echo "--- 8. Пользователи с доступом sudo ---"
    getent group sudo | cut -d: -f4
    echo ""

    # 9. Полный список локальных пользователей
    echo "--- 9. Список локальных пользователей (/etc/passwd) ---"
    getent passwd
    echo ""

    # 10. Дерево всех запущенных процессов
    echo "--- 10. Дерево процессов ---"
    ps aux --forest
    echo ""

    # 11. Список активных сервисов (юнитов) systemd
    echo "--- 11. Активные службы systemd ---"
    systemctl list-units --type=service --state=running
    echo ""

    # 12. Сетевые соединения, открытые процессами
    echo "--- 12. Сетевые соединения процессов (lsof) ---"
    lsof -i -n -P
    echo ""

    # 13. Системные логи с высоким приоритетом (ошибки, крит.)
    echo "--- 13. Критические системные логи (journalctl) ---"
    journalctl -p 0..3 -n 50 --no-pager
    echo ""

    # 14. История неудачных попыток входа
    echo "--- 14. Неудачные попытки входа (lastb) ---"
    lastb -n 20
    echo ""

    # 15. Содержимое временных директорий
    echo "--- 15. Содержимое временных директорий ---"
    ls -la /tmp /var/tmp
    echo ""

    # 16. Список запланированных задач
    echo "--- 16. Задания Cron ---"
    echo "--- /etc/crontab ---"
    cat /etc/crontab
    echo "--- /etc/cron.d/ ---"
    ls -l /etc/cron.d/
    echo "--- /etc/cron.daily/ ---"
    ls -l /etc/cron.daily/
    echo "--- /etc/cron.hourly/ ---"
    ls -l /etc/cron.hourly/
    echo "--- /etc/cron.weekly/ ---"
    ls -l /etc/cron.weekly/
    echo "--- /etc/cron.monthly/ ---"
    ls -l /etc/cron.monthly/
    echo ""

    # 17. Конфигурация сервиса SSH
    echo "--- 17. Конфигурация SSHD ---"
    cat /etc/ssh/sshd_config
    echo ""

} &> "${REPORT_FILE}"

echo "Сырой отчет сгенерирован. Отправляю на анализ в OpenAI..."

# --- АНАЛИЗ ЧЕРЕЗ OPENAI ---

# Читаем содержимое сырого отчета в переменную
REPORT_CONTENT=$(cat "${REPORT_FILE}")
# Экранируем спецсимволы в отчете для корректной вставки в JSON
JSON_REPORT_CONTENT=$(echo "${REPORT_CONTENT}" | jq -Rsa .)

# Формируем тело JSON-запроса к API OpenAI
JSON_PAYLOAD=$(cat <<EOF
{
  "model": "${MODEL}",
  "messages": [
    {
      "role": "system",
      "content": "Ты — эксперт по кибербезопасности. Проанализируй следующий отчет безопасности сервера. Выдели основные уязвимости, подозрительную активность и дай четкие рекомендации по улучшению безопасности на русском языке."
    },
    {
      "role": "user",
      "content": ${JSON_REPORT_CONTENT}
    }
  ],
  "max_tokens": 2048
}
EOF
)

# Выполняем запрос к API и извлекаем только текстовое содержимое ответа
ANALYSIS_RESPONSE=$(curl -s \
    -X POST "${OPENAI_API_URL}" \
    -H "Authorization: Bearer ${OPENAI_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "${JSON_PAYLOAD}" | jq -r '.choices[0].message.content'
)


# --- СОХРАНЕНИЕ РЕЗУЛЬТАТОВ И УВЕДОМЛЕНИЕ ---

echo ""
echo "--- РЕЗУЛЬТАТ АНАЛИЗА ---"
echo "${ANALYSIS_RESPONSE}"
echo ""

# Создаем уникальную временную метку для имени файла
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
# Формируем имя файла для полного отчета
FULL_REPORT_FILE="${ANALYSIS_REPORTS_DIR}/${TIMESTAMP}_analysis_report.txt"

# Сохраняем и запрос, и ответ в один файл для истории
{
    echo "--- OPENAI REQUEST PAYLOAD (ЗАПРОС) ---"
    echo "${JSON_PAYLOAD}"
    echo ""
    echo "--- OPENAI ANALYSIS RESPONSE (ОТВЕТ) ---"
    echo "${ANALYSIS_RESPONSE}"
} > "${FULL_REPORT_FILE}"

echo "Полный отчет (запрос и ответ) сохранен в: ${FULL_REPORT_FILE}"
echo ""

# Отправляем только результат анализа в Telegram
send_telegram_notification "${ANALYSIS_RESPONSE}"
echo ""

echo "--- АНАЛИЗ ЗАВЕРШЕН ---"

# --- ОЧИСТКА ---
# Удаляем временный файл с сырыми данными
rm "${REPORT_FILE}"