#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# misc.sh
# https://github.com/furplag/cogman
# Copyright 2019+ furplag
# Licensed under MIT (https://github.com/furplag/cogman/blob/main/LICENSE)
#
# code snippets for know about what are we have to do .

###
# variable

if ! declare -p we_have_done >/dev/null 2>&1; then declare -r we_have_done='/etc/profile.d/cogman.initialized.sh'; fi
if ! declare -p init_configs >/dev/null 2>&1; then declare -r init_configs='locale selinux slackbot ssh sshkey timezone'; fi

if [[ -f "${we_have_done}" ]]; then source "${we_have_done}"; fi
if ! env | grep INIT_CONFIG_INITIALIZED; then INIT_CONFIG_INITIALIZED=; fi

cat <<_EOT_>"${we_have_done}"

export INIT_CONFIG_INITIALIZED=${INIT_CONFIG_INITIALIZED}

_EOT_
if [[ -f "${we_have_done}" ]]; then source "${we_have_done}"; fi

###
# just a shorthand .
#
# @return whether we have done all configuration, or not
function did_we_have_done() {
  local -ar _initialized=("$(echo ${INIT_CONFIG_INITIALIZED} | sed -e 's/,/\n/g' | sort)")

  if [[ ${#_initialized[@]} -gt 0 && ${init_configs} = ${_initialized[@]} ]]; then return 0; else return 1; fi
}

###
# just a shorthand .
#
# @param key of attribute
# @return whether we have to do, or not
function do_we_have_to_do() {
  local -ar _initialized=($(echo ${INIT_CONFIG_INITIALIZED} | sed -e 's/,/\n/g' | sort))
  local -i _result=0

  if did_we_have_done; then _result=1; # done all initialization task alreasdy .
  elif [[ -z ${1:-} ]]; then _result=1; # ignores empty .
  elif [[ $(echo " ${init_configs} " | grep " ${1:-} " | wc -l) -lt 1 ]]; then _result=1; # ignores invalid task name .
  elif [[ ${#_initialized[@]} -lt 1 ]]; then :; # does not have any completed tasks yet .
  elif echo " ${_initialized[@]} " | grep " ${1:-} " 1>/dev/null; then _result=1; fi # the task has done already .

  return ${_result}
}

###
# storing completed tasks to the environment variable as named "INIT_CONFIG_INITIALIZED" .
#
# @param key of attribute
function do_config_completed() {
  if do_we_have_to_do ${1:-}; then
    INIT_CONFIG_INITIALIZED=${INIT_CONFIG_INITIALIZED}${INIT_CONFIG_INITIALIZED:+,}${1:-}
    local -ar _initialized=($(echo ${INIT_CONFIG_INITIALIZED} | sed -e 's/,/\n/g' | sort))
    INIT_CONFIG_INITIALIZED="$(echo "${_initialized[@]}" | sed -e 's/^ \+//' -e 's/ \+/,/g')"

    export INIT_CONFIG_INITIALIZED=${INIT_CONFIG_INITIALIZED}

  fi
}
