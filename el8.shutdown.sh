#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# el8.shutdown.sh
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
if ! declare -p indent >/dev/null 2>&1; then declare indent='\xF0\x9F\x91\xBB'; fi

# vars of server status notification
if ! declare -p ifttt_api_key >/dev/null 2>&1; then declare -r ifttt_api_key=; fi
if ! declare -p platform >/dev/null 2>&1; then declare -r platform='Unknown'; fi
if ! declare -p project >/dev/null 2>&1; then declare -r project='Unknown'; fi
if ! declare -p instance >/dev/null 2>&1; then declare -r instance="$(hostname)"; fi
if ! declare -p eventName >/dev/null 2>&1; then declare -r eventName='shutdown'; fi

# Server shutdown notification .
if [[ -z ${ifttt_api_key} ]]; then echo -e "${indent}\xF0\x9F\x8D\xA3  : ${platform}:${project}:${instance} ${eventName} ."
elif ! bash -c "curl ${repo_url}/notification/ifttt.webhook.sh -LfsS | bash -s \"${ifttt_api_key}\" \"ping\" \"${eventName:-shutdown}\" \"${platform}/${project}\" \"${instance}\""; then
  echo -e "${indent}\xF0\x9F\x91\xB9: server ${eventName} notification (IFTTT webhook) failed ."; fi
