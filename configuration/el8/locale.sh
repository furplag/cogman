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
  local -r _lang="$(echo ${1:-} | sed -e 's/\..\+$//')$(echo ${1:-} | sed -e 's/^[^\.]\+//' -e 's/-//g' -e 's/.*/\L&/')"
  local -r _current="$(localectl status | grep LANG= | sed -e 's/^.*LANG=\(.\+\)\s\?$/\1/')"
  local -r _indent="${indent}\xF0\x9F\x92\xAC"

  if [[ -z ${_lang} ]]; then echo -e "${_indent}\xF0\x9F\x91\xBB: the value of \"lang\" not spacified ( current setting: ${_current} ) .";
  elif [[ ${_lang} = ${_current} ]]; then echo -e "${_indent}\xF0\x9F\x8D\xA5: system locale already set to \"${_current}\" .";
  elif [[ $(localectl list-locales | grep -E "^${_lang}$" | wc -l) -lt 1 ]]; then
    if dnf install -y glibc-langpack-$(echo "${_lang}" | cut -d '_' -f 1) >/dev/null 2>&1; then
      if localectl set-locale LANG="${_lang}" 1>/dev/null; then
        echo -e "${_indent}\xF0\x9F\x8D\xA3: change system locale \"${_current}\" to \"${_lang}\" ."
      else echo -e "${_indent}\xF0\x9F\x91\xB9: initialization failed, should set locale manually ."; fi
    else echo -e "${_indent}\xF0\x9F\x91\xBA: the value of \"lang\": \"${1:-}\" ( ${_lang} ) does not listed in valid locales ."; fi
  elif localectl set-locale LANG="${_lang}" 1>/dev/null; then
    echo -e "${_indent}\xF0\x9F\x8D\xA3: change system locale \"${_current}\" to \"${_lang}\" ."
  else echo -e "${_indent}\xF0\x9F\x91\xB9: initialization failed, should set locale manually ."; fi

  if [[ -z ${_lang} || "$(localectl status | grep LANG= | sed -e 's/^.*LANG=\(.\+\)\s\?$/\1/')" = ${_lang} ]]; then return 0; else return 1; fi
}

_set_locale "${1:-}"
