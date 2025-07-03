#!/bin/bash

# Домашняя директория проекта
PRJ_HOME="{{ PRJ_HOME }}"
# Директория скриптов
PRJ_SCRIPT_DIR="${PRJ_HOME}/scripts"

# Путь к конфигу MediaWiki на виртуальной машине
VM_WEB_CFG="/var/www/html/LocalSettings.php"

# Параметры подключения к PostgreSQL
DB_RESERV_HOST="{{ wiki_db_reserv_ip }}"
DB_HOST="{{ ansible_host }}"
DB_REP_USER="repuser"

# Параметры PostgreSQL
DB_DATA_DIR="/var/lib/postgresql/14/main"


# Подключение функций логирования
# shellcheck source=/dev/null
source "${PRJ_SCRIPT_DIR}/logging.sh"


# Функции логирования сообщения и выхода
function norm_exit() {
  log_info "$1"
  log_end
  exit 0
}
function err_exit() {
  log_error "$1"
  exit 1
}


log_start
cd /tmp || err_exit "Ошибка cd /tmp"


log_info "Проверка этого сервера ${DB_HOST} на реплику:"
if sudo -u postgres psql -c "SELECT pg_is_in_recovery();" | grep -q 't'; then
  err_exit "Этот сервер уже в режиме реплики."
fi


log_info "Остановка сервиса PostgreSQL..."
if ! sudo systemctl stop postgresql; then
  err_exit "Ошибка остановки сервиса"
fi

log_info "Очистка данных для репликации..."
if ! sudo -u postgres rm -rf "${DB_DATA_DIR:?}/"*; then
  err_exit "Ошибка очистки данных"
fi

log_info "Идет репликация..."
if ! sudo -u postgres pg_basebackup \
  -h "${DB_RESERV_HOST}" \
  -D "${DB_DATA_DIR}" \
  -U "${DB_REP_USER}" \
  -P -v -R; then
  err_exit "Ошибка репликации."
fi

log_info "Запуск сервиса PostgreSQL..."
if ! sudo systemctl start postgresql; then
  err_exit "Ошибка запуска сервиса"
fi


log_info "Редактирование конфига MediaWiki"
if ! sed -i "s/${DB_HOST}/${DB_RESERV_HOST}/g" "${VM_WEB_CFG}"; then
  err_exit "Ошибка редактирования конфига"
fi


log_end
