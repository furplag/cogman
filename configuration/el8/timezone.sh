#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# configuration/timezone.sh
# https://github.com/furplag/cogman
# Copyright 2019+ furplag
# Licensed under MIT (https://github.com/furplag/cogman/blob/master/LICENSE)
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
  local -r _timezone=${1:-}
  local -r _current=$(timedatectl status | grep zone | sed -e 's/^.*zone: \+//' -e 's/ .*$//')
  local -r _indent="${indent}\xF0\x9F\x97\xBA"

  if [[ -z ${_timezone} ]]; then echo -e "${_indent}\xF0\x9F\x91\xBB: the value of \"timezone\" not spacified ( timezone: ${_current} ) ."
  elif [[ ${_timezone} = ${_current} ]]; then echo -e "${_indent}\xF0\x9F\x8D\xA5: system time zone already set to \"${_timezone}\" .";
  elif [[ $(timedatectl list-timezones | grep -E "^${_timezone}$" | wc -l) -lt 1 ]]; then
    echo -e "${_indent}\xF0\x9F\x91\xBA: the value of \"timezone\": \"${_timezone}\" does not listed in valid timezones ."
  elif timedatectl set-timezone "${_timezone}" 1>/dev/null; then
    echo -e "${_indent}\xF0\x9F\x8D\xA3: change system time zone \"${_current}\" to \"${_timezone}\" ."
  else echo -e "${_indent}\xF0\x9F\x91\xB9: initialization failed, should set time zone manually ."; fi

  if [[ -z ${_timezone} || $(timedatectl status | grep zone | sed -e 's/^.*zone: \+//' -e 's/ .*$//') = ${_timezone} ]]; then return 0; else return 1; fi
}

_set_timezone "${1:-}"
