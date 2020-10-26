#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# configuration/unforceSELinux.sh
# https://github.com/furplag/cogman
# Copyright 2019+ furplag
# Licensed under MIT (https://github.com/furplag/cogman/blob/main/LICENSE)
#
# a part of scripts on initial settings to virtual machines .
#

###
# variable
if declare -p indent >/dev/null 2>&1; then :;
elif declare -p symbols >/dev/null 2>&1; then
 declare indent="${symbols['cogman']}${symbols['initialize']}";
else
  declare -Ar symbols=(
    ["cogman"]='\xF0\x9F\xA4\x96'
    ["initialize"]='\xF0\x9F\x91\xB6'
    ["selinux"]='\xF0\x9F\x92\x82'
    ["success"]='\xF0\x9F\x8D\xA3'
    ["error"]='\xF0\x9F\x91\xBA'
    ["fatal"]='\xF0\x9F\x91\xB9'
    ["ignore"]='\xF0\x9F\x8D\xA5'
    ["unspecified"]='\xF0\x9F\x99\x89'
    ["remark"]='\xF0\x9F\x91\xBE'
  )
 declare indent="${symbols['cogman']}${symbols['initialize']}";
fi

function _unforcing_selinux() {
  local _indent="${indent}${symbols['selinux']}"

  local -r _permanent="$(grep -Ei ^SELINUX\=[^\s]+ /etc/selinux/config | sed -e 's/.*=//')"
  local -r _current="`setenforce 0; getenforce`"

  if echo "${_permanent:-Disabled}" | grep -vEi ^E /dev/null 2>&1; then
    echo -e "${_indent}${symbols['ignore']}: SELinux already unforced ( config: ${_permanent}, current setting: ${_current} ) .";
  elif sed -i -e 's/^SELINUX=.*/SELINUX=Permissive\n#\0/' /etc/selinux/config; then echo -e "${_indent}${symbols['success']}: SELinux unforced ( config: $(grep -Ei ^SELINUX\=[^\s]+ /etc/selinux/config | sed -e 's/.*=//'), current setting: ${_current} ) .";
  else echo -e "${_indent}${symbols['fatal']}: initialization failed, should change mode of SELinux another way ."; fi

  if grep -vEi '^SELINUX\=E' /etc/selinux/config >/dev/null 2>&1; then return 0; else return 1; fi
}

_unforcing_selinux
