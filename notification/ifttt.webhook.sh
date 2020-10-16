#! /bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# notification/ifttt.webhook.sh
# https://github.com/furplag/cogman
# Copyright 2019+ furplag
# Licensed under MIT (https://github.com/furplag/cogman/blob/master/LICENSE)
#
# scripts on startup, shutdown and initial settings to virtual machines,
# maybe useful for poor man like me, but currently just only for me own .
#
# Overview
# 1.  Server status notification using IFTTT Webhooks .
#     1. Create IFTTT like that as below .
#        > IF This: webhook named as "${some_event_you_gazing}" event fired .
#        > Then That: send a email message from "Webhooks via IFTTT" to you .
#        >>  Note: you should create endpoints of "send email" per events you need to receive notification .
#        >>  See also IFTTT webhook documentation, for more information .

###
# variable
if ! declare -p webhook_url >/dev/null 2>&1; then declare -r webhook_url='https://maker.ifttt.com/trigger'; fi

###
# function

###
# send request to IFTTT webhook API .
#
# @param api_key key of IFTTT webhook API
# @param eventName event name you want to fire
# @param value1 a value to set email template
# @param value2 a value to set email template
# @param value3 a value to set email template
function _ifttt_webhook() {
  local -i _result=1

  if [[ -z ${1:-} ]] || [[ -z ${2:-} ]]; then echo "empty 1:${1:-} 2:${2:-}";
  elif curl -X POST "${webhook_url}/${2}/with/key/${1}" \
    -H "Content-Type: application/json" \
    -d "{\"value1\":\"${3:-}\",\"value2\":\"${4:-}\",\"value3\":\"${5:-}\"}" -LfsS; then _result=0; fi

  return ${_result}
}

_ifttt_webhook "${1:-}" "${2:-}" "${3:-}" "${4:-}" "${5:-}"

