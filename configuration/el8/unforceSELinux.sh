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
if ! declare -p indent >/dev/null 2>&1; then declare indent='\xF0\x9F\x91\xBB\xF0\x9F\x91\xB6'; fi

function _unforcing_selinux() {
  local _indent="${indent}\xF0\x9F\x92\x82"

  setenforce 0
  if grep -Ei '^SELINUX\=P' /etc/selinux/config 1>/dev/null; then
    echo -e "${_indent}\xF0\x9F\x8D\xA5: SELinux already unforced ( `getenforce` ) .";
  elif sed -i -e 's/^SELINUX=.*/SELINUX=Permissive\n#\0/' /etc/selinux/config; then
    echo -e "${_indent}\xF0\x9F\x8D\xA3: SELinux unforced ."
  else echo -e "${_indent}\xF0\x9F\x91\xB9: initialization failed, should change mode of SELinux another way ."; fi

  if grep -Ei '^SELINUX\=P' /etc/selinux/config 1>/dev/null; then return 0; else return 1; fi
}

_unforcing_selinux
