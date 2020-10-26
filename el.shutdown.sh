#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# el.shutdown.sh
# https://github.com/furplag/cogman
# Copyright 2019+ furplag
# Licensed under MIT (https://github.com/furplag/cogman/blob/main/LICENSE)
#
# scripts on startup, shutdown and initial settings to virtual machines,
# maybe useful for poor man like me, but currently just only for me own .
#
# you can receive notification of server shutdown using IFTTT webhook API .
#
# Overview
# 1. Create IFTTT like that as below .
# > IF This: webhook named as "shutdown" event fired .
# > Then That: send a email message from "Webhooks via IFTTT" to you .
# >>  Note: you should create endpoints of "send email" per events you need to receive notification .
# >>  See also IFTTT webhook documentation, for more information .

# variable
if ! declare -p repo_url >/dev/null 2>&1; then declare -r repo_url='https://raw.githubusercontent.com/furplag/cogman/main'; fi
if ! declare -p symbols >/dev/null 2>&1; then
  declare -Ar symbols=(
    ["cogman"]='\xF0\x9F\xA4\x96'
    ["initialize"]='\xF0\x9F\x91\xB6'
    ["locale"]='\xF0\x9F\x92\xAC'
    ["timezone"]='\xF0\x9F\x8C\x90'
    ["selinux"]='\xF0\x9F\x92\x82'
    ["ssh"]='\xE2\x9A\xA1'
    ["sshkey"]='\xF0\x9F\x94\x90'
    ["slackbot"]='\xF0\x9F\x91\xBB'
    ["success"]='\xF0\x9F\x8D\xA3'
    ["error"]='\xF0\x9F\x91\xBA'
    ["fatal"]='\xF0\x9F\x91\xB9'
    ["ignore"]='\xF0\x9F\x8D\xA5'
    ["unspecified"]='\xF0\x9F\x99\x89'
    ["remark"]='\xF0\x9F\x91\xBE'
  )
fi

# start .
if ! declare -p indent >/dev/null 2>&1; then declare indent='${symbols['cogman']}'; fi

# vars of server status notification
if ! declare -p ifttt_api_key >/dev/null 2>&1; then declare -r ifttt_api_key=; fi
if ! declare -p platform >/dev/null 2>&1; then declare -r platform='unknown'; fi
if ! declare -p project >/dev/null 2>&1; then declare -r project='unknown'; fi
if ! declare -p instance >/dev/null 2>&1; then declare -r instance="$(hostname)"; fi
if ! declare -p eventName >/dev/null 2>&1; then declare -r eventName='statechanged'; fi
if ! declare -p status >/dev/null 2>&1; then declare -r status='shutdown'; fi

# Server shutdown notification .
if [[ -z ${ifttt_api_key} ]]; then
  echo -e "${indent}${symbols['success']}    : ${eventName}/${status}"
  echo -e "${indent}      : Platform: ${platform}"
  echo -e "${indent}      : Project : ${project}"
  echo -e "${indent}      : Instance: ${instance}"
elif ! bash -c "curl ${repo_url}/notification/ifttt.webhook.sh -LfsS | bash -s \"${ifttt_api_key}\" \"${eventName}\" \"${status:-shutdown}\" \"${platform}/${project}\" \"${instance}\""; then
  echo -e "${indent}${symbols['fatal']}: server ${eventName} notification (IFTTT webhook) failed ."; fi
else
