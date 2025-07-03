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

# Базовое имя для файлов дампов БД
DUMP_PREF="mediawiki_db"
# Генерация метки времени с точностью до миллисекунд
TMS="$(date +'%Y%m%d_%H%M%S_%3N')"
# Имя файла дампа
DUMP_NAME="${DUMP_PREF}_${TMS}.dump"

# Формирование пути к файлу дампа с временной меткой
VM_TMP_DUMP="/tmp/${DUMP_NAME}"

# Количество дней, после которых старые дампы будут удаляться
S3_DELETE_AFTER_DAYS=5


# Подключение функций логирования
# shellcheck source=/dev/null
source "${PRJ_SCRIPT_DIR}/logging.sh"


log_start


log_info "Создаем дамп базы данных в custom-формате PostgreSQL"
# -Fc - custom-формат (сжатый и позволяющий выборочное восстановление)
pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -Fc -d "${DB_NAME}" \
  > "${VM_TMP_DUMP}"

cd /tmp || exit $?
mkdir -p "${S3_BACKUP_DIR}"

log_info "Копируем файл дампа в бакет"
cp "${VM_TMP_DUMP}" "${S3_BACKUP_DIR}"
# Сохраняем код возврата команды для последующего использования
exit_code=$?

log_info "Удаляем временные файлы дампов"
rm -f /tmp/${DUMP_PREF}_*.dump

# Если код возврата не равен 0 (т.е. произошла ошибка),
# то завершаем выполнение скрипта с этим кодом ошибки
if (( exit_code != 0 )); then
  log_error "ERROR: cp ${VM_TMP_DUMP} ${S3_BACKUP_DIR}"
  exit $exit_code
fi

log_info "Удаляем старые дампы (старше $S3_DELETE_AFTER_DAYS дней)"
# Ищем файлы с шаблоном имени и удаляем их
find "${S3_BACKUP_DIR}" -type f -name "${DUMP_PREF}_*.dump" \
  -mtime +$S3_DELETE_AFTER_DAYS -delete


log_end
