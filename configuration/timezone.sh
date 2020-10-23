#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# configuration/timezone.sh
# https://github.com/furplag/cogman
# Copyright 2019+ furplag
# Licensed under MIT (https://github.com/furplag/cogman/blob/main/LICENSE)
#
# a part of scripts on initial settings to virtual machines .
#

###
# variable
if ! declare -p indent >/dev/null 2>&1; then declare indent='\xF0\x9F\x91\xBB\xF0\x9F\x91\xB6'; fi

###
# l10N (Timezone) setting .
#
# @param timezone "area/location", see also `timedatectl list-timezones`
# @return the result of `timedatectl set-timezone`
function _set_timezone() {
  local -A _globe_map=(
    ["Africa"]='euro_africa'
    ["America"]='americas'
    ["Antarctica"]='meridians'
    ["Arctic"]='meridians'
    ["Asia"]='asia-australia'
    ["Atlantic"]='euro_africa'
    ["Australia"]='asia-australia'
    ["Europe"]='euro_africa'
    ["Indian"]='asia-australia'
    ["Pacific"]='asia-australia'
    ["UTC"]='meridians'
  )
  local -A _globe_symbols=(
    ["euro_africa"]='\xF0\x9F\x8C\x8D'
    ["asia-australia"]='\xF0\x9F\x8C\x8F'
    ["meridians"]='\xF0\x9F\x8C\x90'
    ["americas"]='\xF0\x9F\x8C\x8E'
  )
  local -r _timezone=${1:-}
  local -r _zone="$(echo "${_timezone}" | sed -e 's/\/.*//')"
  local -r _current=$(timedatectl status | grep zone | sed -e 's/^.*zone: \+//' -e 's/ .*$//')

  local _indent="${indent}${_globe_symbols['meridians']}"
  if [[ " ${!_globe_map[@]} " =~ " ${_zone:-} " ]]; then _indent="${indent}${_globe_symbols[${_globe_map[${_zone:-UTC}]}]}"; fi

  if [[ -z ${_timezone} ]]; then echo -e "${_indent}\xF0\x9F\x91\xBB: the value of \"timezone\" not spacified ( current setting: ${_current} ) ."
  elif [[ ${_timezone} = ${_current} ]]; then echo -e "${_indent}\xF0\x9F\x8D\xA5: system time zone already set to \"${_timezone}\" .";
  elif [[ $(timedatectl list-timezones | grep -E "^${_timezone}$" | wc -l) -lt 1 ]]; then
    echo -e "${_indent}\xF0\x9F\x91\xBA: the value of \"timezone\": \"${_timezone}\" does not listed in valid timezones ."
  elif timedatectl set-timezone "${_timezone}" 1>/dev/null; then
    echo -e "${_indent}\xF0\x9F\x8D\xA3: change system time zone \"${_current}\" to \"${_timezone}\" ."
  else echo -e "${_indent}\xF0\x9F\x91\xB9: initialization failed, should set time zone manually ."; fi

  if [[ "$(timedatectl status | grep zone | sed -e 's/^.*zone: \+//' -e 's/ .*$//')" = "${_timezone:-${_current}}" ]]; then return 0; else return 1; fi
}

_set_timezone "${1:-}"
