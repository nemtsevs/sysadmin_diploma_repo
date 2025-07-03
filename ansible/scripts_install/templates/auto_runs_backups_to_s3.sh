#!/bin/bash

# Домашняя директория проекта
PRJ_HOME="{{ PRJ_HOME }}"
# Директория скриптов
PRJ_SCRIPT_DIR="${PRJ_HOME}/scripts"
# Директория временных файлов
PRJ_TMP_DIR="${PRJ_HOME}/tmp"

# Префикс лог-файлов
LOG_PREF="mediawiki_backups"
# Генерация метки времени с точностью до миллисекунд
TMS="$(date +'%Y%m%d_%H%M%S_%3N')"
# Формирование полного пути к лог-файлу с временной меткой
LOGFILE="${PRJ_TMP_DIR}/${LOG_PREF}_${TMS}.lo"


# Создание лог-файла
touch "${LOGFILE}"

# Переход в директорию скриптов, иначе выход с кодом ошибки
cd "${PRJ_SCRIPT_DIR}" || exit $?

# Запуск скрипта бэкапа контента в S3
"${PRJ_SCRIPT_DIR}"/auto_backup_content_to_s3.sh &>> "${LOGFILE}"
# Запуск скрипта бэкапа базы данных в S3
"${PRJ_SCRIPT_DIR}"/auto_backup_db_to_s3.sh &>> "${LOGFILE}"

# Переименование лог-файла, добавляем 'g'
mv -f "${LOGFILE}" "${LOGFILE}g"
