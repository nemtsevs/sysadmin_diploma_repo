#!/bin/bash

readonly -A LOG_LEVELS=(
  ['DEBUG']=10
  ['INFO']=20
  ['WARNING']=30
  ['ERROR']=40
)
LOG_LEVEL='INFO'


function set_level() { LOG_LEVEL="${1^^}"; }

function log_debug() { _log 'DEBUG' "$1"; }
function log_info() { _log 'INFO' "$1"; }
function log_warning() { _log 'WARNING' "$1"; }
function log_error() { _log 'ERROR' "$1"; }

function log_start() { _log 'INFO' 'Start'; }
function log_end() { _log 'INFO' 'End'; }


function demo() {
  log_start
  for level in error warning info debug; do
    set_level "${level}"

    log_error 'error'
    log_warning 'warning'
    log_info 'info'
    log_debug 'debug'
  done
  log_end
}


function main() {
  demo "$@"
}


function _log() {
  if (( LOG_LEVELS["$1"] >= LOG_LEVELS["${LOG_LEVEL}"] )); then
    tms="$(date +'%Y/%m/%d %H:%M:%S.%3N')"
    bsh="${BASH_SOURCE[2]}"
    fnc="${FUNCNAME[2]:-main}"
    lvl="$1"
    msg="$2"
    row="${tms} - ${bsh}:${fnc} - [${lvl}] - ${msg}"
    echo "${row}" >&$(( LOG_LEVELS["$1"] >= LOG_LEVELS['WARNING'] ? 2 : 1 ))
  fi
}


if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
