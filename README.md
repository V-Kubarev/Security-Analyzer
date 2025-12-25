# Security Analyzer

An automated script for auditing the security of Linux systems using OpenAI for analysis and Telegram for notifications.

## Description

This project is a `bash` script that collects key data about a server's security posture, generates a detailed report, and sends it to OpenAI for analysis. The resulting analysis, complete with findings and recommendations from the AI, is saved to a file and sent as a notification to Telegram.

## Features

- **Comprehensive Data Collection**: Gathers information about the system, network, users, logs, installed packages, and more.
- **Intelligent Analysis**: Leverages the power of OpenAI's language models (GPT) to identify potential vulnerabilities and suspicious activity.
- **Instant Notifications**: Sends the analysis results directly to your Telegram chat.
- **Automation**: Easily configured for regular automatic execution using `cron`.
- **Archiving**: Saves both the raw data and the analysis results for later review.

## How It Works

1.  **Data Collection**: The script runs a set of system commands (`chkrootkit`, `iptables`, `lsof`, `last`, etc.) to gather information.
2.  **Report Generation**: All collected data is consolidated into a temporary text report.
3.  **Request to OpenAI**: The report is sent to the OpenAI API with a system prompt instructing the model to analyze the data as a cybersecurity expert.
4.  **Saving and Notification**: The response from OpenAI, along with the original request, is saved to a file in the `analysis_reports/` directory and also sent to Telegram.

## Requirements

Before running, ensure your system has the following utilities installed:
- `curl`
- `jq`
- `chkrootkit`
- `fail2ban-client` (if using Fail2Ban)
- `iptables`
- `netstat` (or `ss` from the `iproute2` package)
- `lsof`

You can install them using your distribution's package manager (e.g., `sudo apt-get install curl jq chkrootkit lsof`).

## Installation and Configuration

1.  **Clone the repository** (or simply copy the project files):
    ```bash
    git clone [your-repository-url]
    cd Security-Analyzer-Project
    ```

2.  **Set up the configuration files**:
    The project includes two example configuration files: `openai.conf.example` and `telegram.conf.example`.

    - **OpenAI**: Create a copy of `openai.conf.example` and name it `openai.conf`.
      ```bash
      cp openai.conf.example openai.conf
      ```
      Open `openai.conf` and insert your OpenAI API key.
      ```ini
      OPENAI_API_KEY="sk-..."
      ```

    - **Telegram**: Create a copy of `telegram.conf.example` and name it `telegram.conf`.
      ```bash
      cp telegram.conf.example telegram.conf
      ```
      Open `telegram.conf` and enter your Telegram bot token and your `CHAT_ID`.
      ```ini
      BOT_TOKEN="1234567890:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      CHAT_ID="123456789"
      ```

3.  **Set execute permissions**:
    ```bash
    chmod +x final_analyzer.sh
    ```

## Usage

To run the analysis, execute the script with `sudo` rights:
```bash
sudo ./final_analyzer.sh
```
The script will print the analysis from OpenAI to the console, save the full report to the `analysis_reports/` directory, and send a notification to Telegram.

## Automation (Cron)

To have the script run automatically, add it to the `root` user's `crontab`.

1.  Open the `crontab` for editing:
    ```bash
    sudo crontab -e
    ```

2.  Add the following line to run the analysis every day at 6:00 AM (specify the absolute path to the script):
    ```
    0 6 * * * /path/to/project/Security-Analyzer-Project/final_analyzer.sh
    ```
    For example:
    ```
    0 6 * * * /root/gemini/Security-Analyzer-Project/final_analyzer.sh
    ```

## Security and Privacy

**API Keys**:
**IMPORTANT:** The `openai.conf` and `telegram.conf` files contain your secret API keys and tokens. They are already included in the `.gitignore` file to prevent them from being accidentally committed to a public repository. **Never publish these files.**

**Data Transmission**:
This script collects a wide range of system information, including logs, user lists, and network configurations. This data is sent to the OpenAI API for analysis. While the transmission to the OpenAI API is encrypted (using HTTPS), be aware that you are sending potentially sensitive system data to a third-party service. Review the data collected by the script and assess if it aligns with your privacy and security requirements.

---

# Security Analyzer (Анализатор Безопасности)

Автоматизированный скрипт для аудита безопасности Linux-систем с использованием OpenAI для анализа и Telegram для уведомлений.

## Описание

Этот проект представляет собой `bash`-скрипт, который собирает ключевые данные о состоянии безопасности сервера, формирует на их основе подробный отчет и отправляет его на анализ в OpenAI. Полученный от искусственного интеллекта анализ с выводами и рекомендациями сохраняется в файл и отправляется в виде уведомления в Telegram.

## Основные возможности

- **Комплексный сбор данных**: Собирает информацию о системе, сети, пользователях, логах, установленных пакетах и многом другом.
- **Интеллектуальный анализ**: Использует мощь языковых моделей OpenAI (GPT) для выявления потенциальных уязвимостей и подозрительной активности.
- **Мгновенные уведомления**: Отправляет результаты анализа прямо в ваш чат в Telegram.
- **Автоматизация**: Легко настраивается для регулярного автоматического запуска с помощью `cron`.
- **Архивирование**: Сохраняет как исходные данные, так и результаты анализа для последующего изучения.

## Как это работает

1.  **Сбор данных**: Скрипт запускает набор системных команд (`chkrootkit`, `iptables`, `lsof`, `last` и др.) для сбора информации.
2.  **Формирование отчета**: Все собранные данные объединяются во временный текстовый отчет.
3.  **Запрос к OpenAI**: Отчет отправляется в API OpenAI с системным промптом, который инструктирует модель проанализировать данные как эксперт по кибербезопасности.
4.  **Сохранение и уведомление**: Ответ от OpenAI вместе с исходным запросом сохраняется в файл в директории `analysis_reports/`, а также отправляется в Telegram.

## Требования

Перед запуском убедитесь, что в вашей системе установлены следующие утилиты:
- `curl`
- `jq`
- `chkrootkit`
- `fail2ban-client` (если используется Fail2Ban)
- `iptables`
- `netstat` (или `ss` из пакета `iproute2`)
- `lsof`

Вы можете установить их с помощью менеджера пакетов вашего дистрибутива (например, `sudo apt-get install curl jq chkrootkit lsof`).

## Установка и настройка

1.  **Клонируйте репозиторий** (или просто скопируйте файлы проекта):
    ```bash
    git clone [URL-вашего-репозитория]
    cd Security-Analyzer-Project
    ```

2.  **Настройте конфигурационные файлы**:
    В проекте есть два файла с примерами конфигурации: `openai.conf.example` и `telegram.conf.example`.

    - **OpenAI**: Создайте копию файла `openai.conf.example` и назовите ее `openai.conf`.
      ```bash
      cp openai.conf.example openai.conf
      ```
      Откройте `openai.conf` и вставьте ваш API-ключ от OpenAI.
      ```ini
      OPENAI_API_KEY="sk-..."
      ```

    - **Telegram**: Создайте копию файла `telegram.conf.example` и назовите ее `telegram.conf`.
      ```bash
      cp telegram.conf.example telegram.conf
      ```
      Откройте `telegram.conf` и впишите токен вашего Telegram-бота и ваш `CHAT_ID`.
      ```ini
      BOT_TOKEN="1234567890:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      CHAT_ID="123456789"
      ```

3.  **Установите права на выполнение**:
    ```bash
    chmod +x final_analyzer.sh
    ```

## Использование

Для запуска анализа выполните скрипт с правами `sudo`:
```bash
sudo ./final_analyzer.sh
```
Скрипт выведет в консоль результат анализа от OpenAI, сохранит полный отчет в директорию `analysis_reports/` и отправит уведомление в Telegram.

## Автоматизация (Cron)

Чтобы скрипт запускался автоматически, добавьте его в `crontab` пользователя `root`.

1.  Откройте `crontab` для редактирования:
    ```bash
    sudo crontab -e
    ```

2.  Добавьте следующую строку для запуска анализа каждый день в 6:00 утра (укажите абсолютный путь к скрипту):
    ```
    0 6 * * * /путь/к/проекту/Security-Analyzer-Project/final_analyzer.sh
    ```
    Например:
    ```
    0 6 * * * /root/gemini/Security-Analyzer-Project/final_analyzer.sh
    ```

## Безопасность и Приватность

**Ключи API**:
**ВАЖНО:** Файлы `openai.conf` и `telegram.conf` содержат ваши секретные ключи и токены. Они уже добавлены в файл `.gitignore`, чтобы предотвратить их случайную выгрузку в публичный репозиторий. **Никогда не публикуйте эти файлы.**

**Передача данных**:
Этот скрипт собирает большой объем системной информации, включая логи, списки пользователей и сетевые конфигурации. Эти данные отправляются на анализ в API OpenAI. Хотя передача данных в OpenAI API зашифрована (с использованием HTTPS), помните, что вы отправляете потенциально чувствительные системные данные стороннему сервису. Ознакомьтесь с данными, которые собирает скрипт, и оцените, соответствует ли это вашим требованиям к приватности и безопасности.