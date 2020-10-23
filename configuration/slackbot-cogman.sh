#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# configuration/slackbot-cogman.sh
# https://github.com/furplag/cogman
# Copyright 2019+ furplag
# Licensed under MIT (https://github.com/furplag/cogman/blob/main/LICENSE)
#
# script that automate to install and activate Hubot .

###
# Prerequirement

###
# variable
if declare -p indent >/dev/null 2>&1; then :;
elif declare -p symbols >/dev/null 2>&1; then
 declare indent="${symbols['cogman']}${symbols['initialize']}";
else
  declare -Ar symbols=(
    ["cogman"]='\xF0\x9F\xA4\x96'
    ["initialize"]='\xF0\x9F\x91\xB6'
    ["slackbot"]='\xF0\x9F\x91\xBB'
    ["success"]='\xF0\x9F\x8D\xA3'
    ["error"]='\xF0\x9F\x91\xBA'
    ["fatal"]='\xF0\x9F\x91\xB9'
    ["ignore"]='\xF0\x9F\x8D\xA5'
    ["unspecified"]='\xF0\x9F\x99\x89'
    ["remark"]='\xF0\x9F\x91\xBE'
  )
 declare indent="${symbols['cogman']}${symbols['initialize']}";
fi

if ! declare -p platform >/dev/null 2>&1; then declare -r platform='unknown'; fi
if ! declare -p project >/dev/null 2>&1; then declare -r project='unknown'; fi
if ! declare -p instance >/dev/null 2>&1; then declare -r instance="$(hostname)"; fi

if ! declare -p slackbot_user >/dev/null 2>&1; then declare -r slackbot_user='cogman'; fi
if ! declare -p slackbot_group >/dev/null 2>&1; then declare -r slackbot_group='hubot'; fi
if ! declare -p slackbot_uid >/dev/null 2>&1; then declare -ir slackbot_uid=1101; fi
if ! declare -p slackbot_gid >/dev/null 2>&1; then declare -ir slackbot_gid=1111; fi
if ! declare -p hubot_slack_token >/dev/null 2>&1; then declare -r hubot_slack_token=; fi
if ! declare -p hubot_owner_domain >/dev/null 2>&1; then declare -r hubot_owner_domain='example.com'; fi
if ! declare -p hubot_home >/dev/null 2>&1; then declare -r hubot_home="/home/${slackbot_user}/hubot-${slackbot_user}"; fi
if ! declare -p hubot_name >/dev/null 2>&1; then declare -r hubot_name="slackbot-${slackbot_user}"; fi
if ! declare -p hubot_desc >/dev/null 2>&1; then declare -r hubot_desc='Slackbot generated by Cogman .'; fi
if ! declare -p hubot_owner >/dev/null 2>&1; then declare -r hubot_owner="${slackbot_user} ${slackbot_user}.$(hostname -s)@${hubot_owner_domain}"; fi

###
# function

###
# validate required variables .
#
# @param name the name of variable
# @return returns the result tests whether the variable has no value, or not .
function _is_empty() {
  if [[ -z ${1:-} ]]; then return 0;
  elif [[ -z "$(eval echo \"\$${1:-}\")" ]]; then return 0; else return 1; fi
}

###
# validate required variables .
#
# @param indent
# @return returns the result tests whether the variable has no value, or not .
function _validate() {
  local -r _indent="${1:-${indent}${symbols['slackbot']}}"
  local -i _result=0

  for _var in 'slackbot_group' 'slackbot_user' 'slackbot_uid' 'hubot_slack_token'; do
    if _is_empty $_var; then
      echo -e "${_indent}${symbols['unspecified']}: the value of \"\$${_var}\" not spacified ."
      _result=1
      break
    fi
  done

  return $_result
}

function _create_slackbot_user() {
  local -r _indent="${1:-${indent}${symbols['slackbot']}}"
  local -i _result=0

  # create slackbot group
  if getent group "${slackbot_group}" >/dev/null 2>&1; then echo -e "${_indent}${symbols['ignore']}: the group \"${slackbot_group}\" already exists .";
  elif [[ "${slackbot_group}" = "${slackbot_user}" ]]; then :;
  elif groupadd -g ${slackbot_gid} "${slackbot_group}" >/dev/null 2>&1; then echo -e "${_indent}${symbols['success']}: create slackbot group \"${slackbot_group}\" ( $(getent group "${slackbot_group}" | awk -F '[::]' '{print $3}') ) .";
  elif groupadd -g $((${slackbot_gid} + 1)) "${slackbot_group}" >/dev/null 2>&1; then echo -e "${_indent}${symbols['success']}: create slackbot group \"${slackbot_group}\" ( $(getent group "${slackbot_group}" | awk -F '[::]' '{print $3}') ) .";
  elif groupadd "${slackbot_group}" 2>/dev/null; then echo -e "${_indent}${symbols['success']}: create slackbot group \"${slackbot_group}\" ( $(getent group "${slackbot_group}" | awk -F '[::]' '{print $3}') ) .";
  else echo -e "${_indent}${symbols['error']}: could not create group \"${slackbot_group}\" ."; fi

  if getent passwd "${slackbot_user}" >/dev/null 2>&1; then echo -e "${_indent}${symbols['ignore']}: user \"${slackbot_user}\" already exists .";
  elif useradd -u ${slackbot_uid} "${slackbot_user}" -d /home/${slackbot_user} >/dev/null 2>&1; then echo -e "${_indent}${symbols['success']}: create slackbot user \"${slackbot_user}\" ( $(getent passwd "${slackbot_user}" | awk -F '[::]' '{print $3}') ) .";
  elif useradd -u $((${slackbot_uid} + 1)) "${slackbot_user}" -d /home/${slackbot_user} >/dev/null 2>&1; then echo -e "${_indent}${symbols['success']}: create slackbot user \"${slackbot_user}\" ( $(getent passwd "${slackbot_user}" | awk -F '[::]' '{print $3}') ) .";
  elif useradd "${slackbot_user}" -d /home/${slackbot_user} >/dev/null 2>&1; then echo -e "${_indent}${symbols['success']}: create slackbot user \"${slackbot_user}\" ( $(getent passwd "${slackbot_user}" | awk -F '[::]' '{print $3}') ) .";
  else _result=1; echo -e "${_indent}${symbols['error']}: could not create user \"${slackbot_user}\" ."; fi

  local -ir _uid=$(getent passwd "${slackbot_user}" | awk -F '[::]' '{print $3}')
  if [[ $_uid -gt 0 ]]; then
    if usermod -aG "${slackbot_group}" "${slackbot_user}"; then :;
    else echo -e "${_indent}${symbols['error']}: could not associate user \"${slackbot_user}\" to group \"${slackbot_group}\" ."; fi
  elif [[ "${slackbot_user}" = 'root' ]]; then :;
  else _result=1; fi

  return $_result
}

function _install_nodejs() {
  local -r _indent="${1:-${indent}${symbols['slackbot']}}"
  local -i _result=0

  if node -v >/dev/null 2>&1 && npm -v >/dev/null 2>&1; then echo -e "${_indent}${symbols['ignore']}: Node.js installed, already .";
  elif bash <(curl https://rpm.nodesource.com/setup_lts.x -LfsS) >/dev/null 2>&1 && sed -i -e 's/enabled \?=\?1/enabled=0/' /etc/yum.repos.d/nodesource*.repo; then
    if dnf install nodejs -y --enablerepo=nodesource >/dev/null 2>&1; then echo -e "${_indent}${_indent}${symbols['success']}: Node.js installed .";
    elif yum install nodejs -y --enablerepo=nodesource >/dev/null 2>&1; then echo -e "${_indent}${symbols['success']}: Node.js installed .";
    else _result=1; echo -e "${_indent}${symbols['error']}: failed install Node.js ."; fi
  else _result=1; echo -e "${_indent}${symbols['error']}: failed install Node.js ."; fi

  return $_result
}

function _install_node_modules() {
  local -r _indent="${1:-${indent}${symbols['slackbot']}}"
  local -i _result=0
  for module in yo generator-hubot; do
    if [[ $_result -ne 0 ]]; then :;
    elif npm install -g $module >/dev/null 2>&1; then echo -e "${_indent}${symbols['success']}: Node modules ( ${module} ) installed .";
    else echo -e "${_indent}${symbols['error']}: failed install Node modules ( ${module} ) ."; _result=1; fi
  done

  return $_result
}

function _install_redis() {
  local -r _indent="${1:-${indent}${symbols['slackbot']}}"
  local -i _result=0
  if [[ "`redis-cli ping 2>/dev/null`" = 'PONG' ]]; then echo -e "${_indent}${symbols['ignore']}: Redis is running, already .";
  elif systemctl start redis >/dev/null 2>&1; then echo -e "${_indent}${symbols['ignore']}: Redis is running, already .";
  elif dnf install redis -y >/dev/null 2>&1 && systemctl start redis >/dev/null 2>&1 && systemctl enable redis >/dev/null 2>&1; then
    echo -e "${_indent}${symbols['success']}: ready to use Redis server .";
  elif yum install epel-release -y >/dev/null 2>&1 && yum install redis -y >/dev/null 2>&1 && systemctl start redis >/dev/null 2>&1 && systemctl enable redis >/dev/null 2>&1; then
    echo -e "${_indent}${symbols['success']}: ready to use Redis server .";
  else echo -e "${_indent}${symbols['error']}: failed start up Redis ."; _result=1; fi

  return $_result
}

function _install_hubot() {
  local -r _indent="${1:-${indent}${symbols['slackbot']}}"
  local -i _result=0
  if [[ -d "${hubot_home}" ]]; then echo -e "${_indent}${symbols['ignore']}: directory \"${hubot_home}\" already exists .";
  elif sudo -i -u ${slackbot_user} bash -c "mkdir -p ${hubot_home}" >/dev/null 2>&1; then :;
  else _result=1; echo -e "${_indent}${symbols['error']}: failed create directory \"${hubot_home}\" ."; fi

  local _command="`which yo` hubot --no-insight --owner=\"${hubot_owner}\" --name=${hubot_name} --description=\"${hubot_desc}\" --adapter=slack"

  if [[ $_result -ne 0 ]]; then :;
  elif [[ -f ${hubot_home}/bin/hubot ]]; then echo -e "${_indent}${symbols['ignore']}: Hubot ( ${hubot_home}/bin/hubot ) already exists .";
  elif sudo -i -u ${slackbot_user} bash -c "cd ${hubot_home} && ${_command} && cd -"; then
    echo -e "${_indent}${symbols['success']}: Hubot activate .";
  else _result=1; echo -e "${_indent}${symbols['error']}: failed construction Hubot ."; fi

  return $_result
}

function _daemonize_slackbot() {
  local -r _indent="${1:-${indent}${symbols['slackbot']}}"
  local -i _result=0
  if systemctl status slackbot-cogman.service >/dev/null 2>&1; then echo -e "${_indent}${symbols['ignore']}: slackbot-cogman.service is running, already .";
  elif systemctl list-unit-files --type=service | grep -E '^slackbot-cogman\.service'; then echo -e "${_indent}${symbols['ignore']}: slackbot-cogman.service already available .";
  else cat <<_EOT_>/etc/systemd/system/slackbot-cogman.service
[Unit]
Description=Hubot - Slack, Cogman
Requires=redis.service

[Service]
User=${slackbot_user}
Group=${slackbot_group}
WorkingDirectory=${hubot_home}
Environment=HUBOT_SLACK_TOKEN=${hubot_slack_token}
ExecStart=/bin/sh -c "bin/hubot --adapter slack"
ExecStop=/bin/kill \$MAINPID

[Install]
WantedBy=multi-user.target

_EOT_
  fi

  if [[ -f /etc/systemd/system/slackbot-cogman.service ]]; then :;
  else _result=1; echo -e "${_indent}${symbols['error']}: failed construction Hubot ."; fi

  if [[ $_result -ne 0 ]]; then :;
  elif systemctl daemon-reload && systemctl start slackbot-cogman.service >/dev/null 2>&1 && systemctl enable slackbot-cogman.service >/dev/null 2>&1; then
    echo -e "${_indent}${symbols['success']}: Slackbot deamonized, running named as \"slackbot-cogman\" .";
  else _result=1; fi

  [[ $_result -ne 0 ]] && echo -e "${_indent}${symbols['error']}: failed construction Hubot .";

  return $_result
}

_validate && _install_redis && _install_nodejs && _install_node_modules && _create_slackbot_user && _install_hubot && _daemonize_slackbot

