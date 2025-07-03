#!/bin/bash

# Домашняя директория проекта
PRJ_HOME="{{ PRJ_HOME }}"
# Директория скриптов
PRJ_SCRIPT_DIR="${PRJ_HOME}/scripts"

# Путь к директории с контентом MediaWiki
# Веб пользователь
# Конфиг MediaWiki на виртуальной машине
VM_CONTENT_DIR="/var/www/html"
VM_WEB_CFG_NAM="LocalSettings.php"
VM_WEB_USER="www-data"

# Путь к директории для бэкапов в S3
S3_BACKUP_DIR="{{ S3_BAK_CONTENT_DIR }}"

# Префикс архивов бэкапов
ARH_PREF="mediawiki_content"


# Подключение функций логирования
# shellcheck source=/dev/null
source "${PRJ_SCRIPT_DIR}/logging.sh"


log_start


log_info "Поиск подходящего файла архива"
S3_LATEST_ARH="$(
  find "${S3_BACKUP_DIR}" -type f -name "${ARH_PREF}_*.tar.gz" \
    -printf '%T@ %p\n' \
    | sort -n \
    | tail -1 \
    | cut -d' ' -f2-
)"
if [[ -z "${S3_LATEST_ARH}" ]]; then
  log_error "ERROR: ${S3_BACKUP_DIR}/${ARH_PREF}_*.tar.gz архивов не найдено" >&2
  exit 1
fi

log_info "Идет копирование ${S3_LATEST_ARH} в /tmp..."
cp --parents "${S3_LATEST_ARH}" /tmp || exit $?

sudo rm -rf "${VM_CONTENT_DIR}"
sudo mkdir -p "${VM_CONTENT_DIR}"
sudo chown -R "${VM_WEB_USER}":"${VM_WEB_USER}" "${VM_CONTENT_DIR}"

log_info "Идет разархивирование tar -xzf..."
sudo -u "${VM_WEB_USER}" tar -xzf "/tmp/${S3_LATEST_ARH}" -C "${VM_CONTENT_DIR}" \
  --strip-components=1
exit_code=$?

sudo -u "${VM_WEB_USER}" chmod -R "u=rwX,go=rX" "${VM_CONTENT_DIR}"
sudo -u "${VM_WEB_USER}" chmod 600 "${VM_CONTENT_DIR}/${VM_WEB_CFG_NAM}"

log_info "Удаление временных файлоы"
rm -rf "/tmp/${S3_LATEST_ARH:?}"

if (( exit_code != 0 )); then
  log_error "ERROR: Ошибка при выполнении: \
sudo -u ${VM_WEB_USER} tar -xzf /tmp/${S3_LATEST_ARH} -C ${VM_CONTENT_DIR} ..."
  exit $exit_code
fi


log_end
