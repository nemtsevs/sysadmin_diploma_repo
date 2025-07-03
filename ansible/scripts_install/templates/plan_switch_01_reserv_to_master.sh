#!/bin/bash

# Домашняя директория проекта
PRJ_HOME="{{ PRJ_HOME }}"
# Директория скриптов
PRJ_SCRIPT_DIR="${PRJ_HOME}/scripts"

# Путь к конфигу MediaWiki на виртуальной машине
VM_WEB_CFG="/var/www/html/LocalSettings.php"

# Параметры подключения к PostgreSQL
DB_MASTER_HOST="{{ wiki_db_master_ip }}"
DB_HOST="{{ ansible_host }}"


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


log_info "Проверка мастер-хоста ${DB_MASTER_HOST}:"
if pg_isready -h "${DB_MASTER_HOST}" -U postgres -q; then
  norm_exit "Мастер-хост доступен. Переключение не требуется."
fi

log_info "Проверка этого сервера ${DB_HOST} на мастера:"
if sudo -u postgres psql -c "SELECT pg_is_in_recovery();" | grep -q 'f'; then
  err_exit "Этот сервер уже в режиме мастера"
fi


log_info "Идет остановка репликации..."
if ! sudo -u postgres psql -c "SELECT pg_wal_replay_pause();"; then
  err_exit "Ошибка pg_wal_replay_pause"
fi

log_info "Идет промоут реплики..."
if ! sudo -u postgres psql -c "SELECT pg_promote();"; then
  err_exit "Ошибка pg_promote"
fi


log_info "Редактирование конфига MediaWiki"
if ! sed -i "s/${DB_MASTER_HOST}/${DB_HOST}/g" "${VM_WEB_CFG}"; then
  err_exit "Ошибка редактирования конфига"
fi


log_end
