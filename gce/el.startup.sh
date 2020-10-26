#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# gce/el.startup.sh
# https://github.com/furplag/cogman
# Copyright 2019+ furplag
# Licensed under MIT (https://github.com/furplag/cogman/blob/main/LICENSE)
#
# scripts on startup, shutdown and initial settings to virtual machines,
# maybe useful for poor man like me, but currently just only for me own .
#
# Overview
# 1.  Server initial setting (do only first time) .
#   1.  makes some optimizations for the VM to stands a web server .
#     - i18N (Locale / Language) setting .
#     - l10N (Timezone) setting .
#     - unforcing SELinux .
#   2.  change SSH port number for protect under crack .
#     - Firewall setting (firewalld) .
#     - SSH port number setting (sshd) .
#
#       | setting | default | change to |
#       |----|----|----|
#       | AddressFamily | any | inet (v4 only) |
#       | Port | 22 | the port number you decide to change . |
#       | PermitRootLogin | no | without-password |
#       | PubkeyAuthentication | yes | yes |
#       | PasswordAuthentication | yes | no |
#       | PermitEmptyPasswords | no | no |
#       | ChallengeResponseAuthentication | yes | no |
#       | GSSAPIAuthentication | yes | no |
#       | UsePAM | yes | yes |
#       | UseDNS | yes | no |
#
#       - only use Public Key Authentication .
#       - enable to login as Root directly .
#       > you can override SSH setting with option named as "ssh_config_options", like this
#       > "PasswordAuthentication=yes PermitRootLogin=yes" .
#     - generate SSH key pair .
#   3.  install Slackbot ( Hubot Slack adapter ) .
#     - install daemonized Hubot .
#   4.  and never repeated .
# 2.  Server startup notification .
#     you can receive notification of server startup using IFTTT webhook API .
#     1. Create IFTTT like that as below .
#     > IF This: webhook named as "startup" event fired .
#     > Then That: send a email message from "Webhooks via IFTTT" to you .
#     >>  Note: you should create endpoints of "send email" per events you need to receive notification .
#     >>  See also IFTTT webhook documentation, for more information .

# variable
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
declare -r repo_url='https://raw.githubusercontent.com/furplag/cogman/main'
declare -r metadata_url='http://metadata.google.internal/computeMetadata/v1'
declare indent="${symbols['cogman']}"

# install command `retrieve_metadata` .
if ! which retrieve_metadata >/dev/null 2>&1; then bash <(curl "${repo_url}/gce/install.retrieve_metadata.sh" -LfsS); fi

# install command `is_preempted` .
if ! which is_preempted >/dev/null 2>&1; then bash <(curl "${repo_url}/gce/install.is_preempted.sh" -LfsS); fi

###
# variable

# vars of server initial setting
declare -r locale_lang=$(retrieve_metadata 'locale')
declare -r timezone=$(retrieve_metadata 'timezone')
declare -r ssh_port_number=$(retrieve_metadata 'ssh-port')
declare -r ssh_config_options=$(retrieve_metadata 'ssh-config-options')
declare -r ssh_key_passphrase=$(retrieve_metadata 'ssh-key-passphrase')
declare -r ssh_keygen_options=$(retrieve_metadata 'ssh-keygen-options' '-t ed25519')

# vars of server status notification using IFTTT
declare -r ifttt_api_key=$(retrieve_metadata 'ifttt-api-key')
declare -r platform="GCE ($(retrieve_metadata 'zone' 'Unknown' | sed -e 's/^.*\///')) "
declare -r project=$(retrieve_metadata 'project-id' 'Unknown')
declare -r instance=$(retrieve_metadata 'name' "$(hostname)")
declare -r eventName='statechanged'
declare -r status='started'

# vars of server status notification using Slack and HUBOT
declare -r slackbot_user=$(retrieve_metadata 'slackbot-user' 'shockwave')
declare -r slackbot_group=$(retrieve_metadata 'slackbot-group' 'decepticons')
declare -ir slackbot_uid=$(retrieve_metadata 'slackbot-uid' 1101)
declare -ir slackbot_gid=$(retrieve_metadata 'slackbot-gid' 1111)
declare -r hubot_slack_token=$(retrieve_metadata 'hubot-slack-token')
declare -r hubot_owner_domain=$(retrieve_metadata 'hubot-owner-domain' 'example.com')
declare -r hubot_home=$(retrieve_metadata 'hubot-home' "/home/${slackbot_user}/hubot-${slackbot_user}")
declare -r hubot_name=$(retrieve_metadata 'hubot-name' "slackbot-${slackbot_user}")
declare -r hubot_desc=$(retrieve_metadata 'hubot-desc' 'server status notifierer generated by Cogman .')
declare -r hubot_owner=$(retrieve_metadata 'hubot-owner' "${slackbot_user} ${slackbot_user}.${project,,}.${platform,,}@${slackbot_hubot_domain}")
declare -ir hubot_heroku_keepalive=1

source <(curl "${repo_url}/el.startup.sh" -fLsS)