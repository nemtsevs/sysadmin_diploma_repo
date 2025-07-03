#!/bin/bash

# Домашняя директория проекта
PRJ_HOME="{{ PRJ_HOME }}"
# Директория скриптов
PRJ_SCRIPT_DIR="${PRJ_HOME}/scripts"

# Путь к директории с контентом MediaWiki
# и веб пользователь на виртуальной машине
VM_CONTENT_DIR="/var/www/html"
VM_WEB_USER="www-data"

# Путь к директории для бэкапов в S3
S3_BACKUP_DIR="{{ S3_BAK_CONTENT_DIR }}"

# Префикс для архивов бэкапов
ARH_PREF="mediawiki_content"
# Генерация метки времени с точностью до миллисекунд
TMS="$(date +'%Y%m%d_%H%M%S_%3N')"
# Имя архива бэкапа
ARH_NAME="${ARH_PREF}_${TMS}.tar.gz"

# Формирование пути к архиву бэкапа с временной меткой
VM_TMP_ARH="/tmp/${ARH_NAME}"

# Количество дней, после которых старые бэкапы будут удаляться
S3_DELETE_AFTER_DAYS=5


# Подключение функций логирования
# shellcheck source=/dev/null
source "${PRJ_SCRIPT_DIR}/logging.sh"


log_start


# "Переходим в директорию с контентом"
cd "${VM_CONTENT_DIR}" || exit $?

log_info "Создаем сжатый архив (tar.gz) с контентом MediaWiki"
sudo -u "${VM_WEB_USER}" tar -czf "${VM_TMP_ARH}" . || exit $?

cd /tmp || exit $?
mkdir -p "${S3_BACKUP_DIR}"

log_info "Копируем архив в бакет"
cp "${VM_TMP_ARH}" "${S3_BACKUP_DIR}"
# Сохраняем код возврата команды для последующего использования
exit_code=$?

log_info "Удаляем временные архивы"
sudo -u "${VM_WEB_USER}" rm -f /tmp/${ARH_PREF}_*.tar.gz

# Если код возврата не равен 0 (т.е. произошла ошибка),
# то завершаем выполнение скрипта с этим кодом ошибки
if (( exit_code != 0 )); then
  log_error "ERROR: cp ${VM_TMP_ARH} ${S3_BACKUP_DIR}"
  exit $exit_code
fi

log_info "Удаляем старые бэкапы (старше $S3_DELETE_AFTER_DAYS дней)"
# Ищем файлы с шаблоном имени и удаляем их
find "${S3_BACKUP_DIR}" -type f -name "${ARH_PREF}_*.tar.gz" \
  -mtime +$S3_DELETE_AFTER_DAYS -delete


log_end
