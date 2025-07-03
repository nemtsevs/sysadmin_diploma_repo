#!/bin/bash

# Домашняя директория проекта
PRJ_HOME="{{ PRJ_HOME }}"
# Директория скриптов
PRJ_SCRIPT_DIR="${PRJ_HOME}/scripts"

# Параметры подключения к PostgreSQL
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="wikiuser"
DB_NAME="my_wiki"

# Путь к директории для дампов в S3
S3_BACKUP_DIR="{{ S3_BAK_DB_DIR }}"

# Префикс файлов дампов
DUMP_PREF="mediawiki_db"


# Подключение функций логирования
# shellcheck source=/dev/null
source "${PRJ_SCRIPT_DIR}/logging.sh"


log_start


log_info "Поиск подходящего файла дампа"
S3_LATEST_DUMP="$( \
  find "${S3_BACKUP_DIR}" -type f -name "${DUMP_PREF}_*.dump" \
    -printf '%T@ %p\n' \
    | sort -n \
    | tail -1 \
    | cut -d' ' -f2- \
)"
if [[ -z "${S3_LATEST_DUMP}" ]]; then
  log_error "ERROR: ${S3_BACKUP_DIR}/${DUMP_PREF}_*.dump дампов не найдено" >&2
  exit 1
fi

log_info "Идет копирование ${S3_LATEST_DUMP} в /tmp..."
cp --parents "${S3_LATEST_DUMP}" /tmp || exit $?

log_info "Идет pg_restore..."
pg_restore -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" \
  --no-password --clean --if-exists --no-owner --no-acl "/tmp/${S3_LATEST_DUMP}"
exit_code=$?

log_info "Удаление временных файлоы"
rm -rf "/tmp/${S3_LATEST_DUMP:?}"

if (( exit_code != 0 )); then
  log_error "ERROR: Ошибка при выполнении: \
pg_restore -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} ... \
/tmp/${S3_LATEST_DUMP}"
  exit $exit_code
fi

log_end
