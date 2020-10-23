#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# configuration/locale.sh
# https://github.com/furplag/cogman
# Copyright 2019+ furplag
# Licensed under MIT (https://github.com/furplag/cogman/blob/main/LICENSE)
#
# a part of scripts on initial settings to virtual machines .
#

###
# variable
if ! declare -p indent >/dev/null 2>&1; then declare indent='\xF0\x9F\x91\xBB\xF0\x9F\x91\xB6'; fi

##
# i18N (Locale / Language) setting .
#
# @param lang, see also `localectl list-locales`
# @return the result of `localectl set-locale`
function _set_locale() {
  local -i _install=1

  local -r _lang="$(echo ${1:-} | sed -e 's/\..\+$//')$(echo ${1:-} | sed -e 's/^[^\.]\+//' -e 's/-//g' -e 's/.*/\L&/')"
  local -r _current="$(localectl status | grep LANG= | sed -e 's/^.*LANG=\(.\+\)\s\?$/\1/')"
  local -r _indent="${indent}\xF0\x9F\x92\xAC"

  if [[ -z ${_lang} ]]; then echo -e "${_indent}\xF0\x9F\x91\xBB: the value of \"lang\" not spacified ( current setting: ${_current} ) .";
  elif [[ ${_lang} = ${_current} ]]; then echo -e "${_indent}\xF0\x9F\x8D\xA5: system locale already set to \"${_current}\" .";
  elif localectl list-locales | grep -E "^${_lang}$" >/dev/null 2>&1; then _install=0;
  elif dnf install -y glibc-langpack-$(echo "${_lang}" | cut -d '_' -f 1) >/dev/null 2>&1; then _install=0;
  elif yum install -y glibc-common >/dev/null 2>&1; then _install=0;
  else echo -e "${_indent}\xF0\x9F\x91\xB9: initialization failed, should set locale manually ."; fi

  if [[ $(($_install)) -ne 0 ]]; then :;
  elif localectl list-locales | grep -E "^${_lang}$" >/dev/null 2>&1 && localectl set-locale LANG="${_lang}" >/dev/null 2>&1; then
    echo -e "${_indent}\xF0\x9F\x8D\xA3: change system locale \"${_current}\" to \"${_lang}\" ."
  else echo -e "${_indent}\xF0\x9F\x91\xB9: \"${1:-}\" does not listed in valid locale ."; fi

  if [[ "$(localectl status | grep LANG= | sed -e 's/^.*LANG=\(.\+\)\s\?$/\1/')" = ${_lang:-_current} ]]; then return 0; else return 1; fi
}

_set_locale "${1:-}"
