#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# gce/el78.shutdown.sh
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
if ! declare -p indent >/dev/null 2>&1; then declare -r indent='\xF0\x9F\xA4\x96'; fi

# install command `retrieve_metadata` .
if ! which retrieve_metadata >/dev/null 2>&1; then bash <(curl "${repo_url}/gce/install.retrieve_metadata.sh" -LfsS); fi

# install command `is_preempted` .
if ! which is_preempted >/dev/null 2>&1; then bash <(curl "${repo_url}/gce/install.is_preempted.sh" -LfsS); fi

# vars of server status notification
declare -r ifttt_api_key=$(retrieve_metadata 'ifttt-api-key')
declare -r platform="GCE.$(retrieve_metadata 'zone' 'Unknown' | sed -e 's/^.*\///')"
declare -r project=$(retrieve_metadata 'project-id' 'Unknown')
declare -r instance=$(retrieve_metadata 'name' "$(hostname)")
declare -r eventName=$(if is_preempted; then echo 'preempted'; else echo 'shutdown'; fi)

source <(curl "${repo_url}/el8.shutdown.sh" -fLsS)

