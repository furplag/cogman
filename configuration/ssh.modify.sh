#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# configuration/ssh.modify.sh
# https://github.com/furplag/cogman
# Copyright 2019+ furplag
# Licensed under MIT (https://github.com/furplag/cogman/blob/main/LICENSE)
#
# a part of scripts on initial settings to virtual machines .
#

###
# variable
if ! declare -p indent >/dev/null 2>&1; then declare indent='\xF0\x9F\x91\xBB\xF0\x9F\x91\xB6'; fi

###
# function

###
# returns a port number used to SSH currently .
#
# @return SSH port number
function _get_ssh_ports() {
  local -ar _current=(`grep -Ei '^Port' /etc/ssh/sshd_config | grep -Eo '[0-9]+' 2>/dev/null`)

  if [[ ${#_current[*]} -lt 1 ]]; then echo "22"; else echo "${_current}"; fi
}

###
# change SSH port number for protect under crack .
#
# @param _port TCP port number to change
function _ssh_modify() {
  local -r _port="${1:-}"
  local -ar _current_ports=(`_get_ssh_ports`)
  local -r _indent="${indent}\xE2\x9A\xA1"
  local -i _result=1
  local -i _semanage=1

  if [[ -z "${_port}" ]]; then echo -e "${_indent}\xF0\x9F\x91\xBB: the value of \"ssh-port\" not spacified ( SSH port (s) : ${_current_ports} ) .";
  elif echo "${_port}" | grep -Eo '[^0-9]' >/dev/null 2>&1; then echo -e "${_indent}\xF0\x9F\x91\xBA: the value \"${_port}\" is invalid port number .";
  elif [[ $((_port)) -lt 1 ]] || [[ $((_port)) -gt 65535 ]]; then echo -e "${_indent}\xF0\x9F\x91\xBA: the value \"${_port}\" is invalid port number .";
  elif dnf install policycoreutils-python-utils -y >/dev/null 2>&1; then
    # add another port number of SSH to the list of SELinux allows .
    if semanage port -l | grep ssh_port_t | grep -Eo '[0-9]{1,5}' | grep -E "^${_port}\$" >/dev/null 2>&1; then :;
    elif semanage port -a -t ssh_port_t -p tcp ${_port}; then echo -e "${_indent}\xF0\x9F\x8D\xA3: add ${_port}/TCP to the list of SELinux allows ."; fi
    _result=0
  elif yum install policycoreutils-python -y >/dev/null 2>&1; then
    # add another port number of SSH to the list of SELinux allows .
    if semanage port -l | grep ssh_port_t | grep -Eo '[0-9]{1,5}' | grep -E "^${_port}\$" >/dev/null 2>&1; then :;
    elif semanage port -a -t ssh_port_t -p tcp ${_port}; then echo -e "${_indent}\xF0\x9F\x8D\xA3: add ${_port}/TCP to the list of SELinux allows ."; fi
    _result=0
  else echo -e "${_indent}\xF0\x9F\x91\xBA: could not add ${_port}/TCP to the list of SELinux allows ."; fi

  if [[ $((_result)) -ne 0 ]]; then :;
  elif [[ $((_port)) -ne 22 ]]; then :;
  elif semanage port -l | grep ssh_port_t | grep -Eo '[0-9]+' | grep -E "^${_port}\$" >/dev/null 2>&1; then
    # add SSH with another TCP port number to Firewall services .
    cat /usr/lib/firewalld/services/ssh.xml >"/etc/firewalld/services/ssh-${_port}.xml" && \
    sed -i -e "s@\(short>\).*\(<\/\)@\1SSH via ${_port}\2@" \
      -e "s/port=\".*\"/port=\"$_port\"/" \
      "/etc/firewalld/services/ssh-${_port}.xml" && \
    firewall-cmd --reload >/dev/null 2>&1 && :;
    if grep "port=\"${_port}\"" /etc/firewalld/services/ssh-${_port}.xml >/dev/null 2>&1; then
      echo -e "${_indent}\xF0\x9F\x8D\xA3: defined the service named as \"ssh-${_port}\", which accepts to connect SSH custom port ."
    fi
  fi

  if [[ $((_result)) -ne 0 ]]; then :;
  elif [[ $((_port)) -ne 22 ]]; then :;
  elif systemctl status firewalld >/dev/null 2>&1; then
    # accept TCP port number \"${_port}\" on Firewall .
    for zone in `firewall-cmd --get-zones`; do
      if [[ ' block drop ' =~ " ${zone} " ]]; then :;
      elif [[ ! " `firewall-cmd --list-services --zone=${zone}` " =~ " ssh " ]]; then
        echo -e "${_indent}\xF0\x9F\x8D\xA5: zone \"${zone}\" disallowed SSH connect .";
      elif echo "`firewall-cmd --list-services --zone=${zone}`" | grep "ssh-${_port}" >/dev/null 2>&1; then
        echo -e "${_indent}\xF0\x9F\x8D\xA5: zone \"${zone}\" is accepted to connect via ${_port}/TCP, already .";
      elif firewall-cmd --add-service="ssh-${_port}" --zone=${zone} --permanent >/dev/null 2>&1; then
        echo -e "${_indent}\xF0\x9F\x8D\xA3: zone \"${zone}\" now ready to SSH connect via ${_port}/TCP .";
      else echo -e "${_indent}\xF0\x9F\x91\xBA: could not allowed to SSH connect via ${_port}/TCP at zone \"${zone}\" ."; fi
    done
    if firewall-cmd --reload >/dev/null 2>&1; then :; else _result=1; fi
  else _result=1; fi

  if [[ $((_result)) -ne 0 ]]; then :;
  else
    # failsafe .
    if ls -1 /etc/ssh | grep sshd_config.ofDefault >/dev/null 2>&1; then
      cat /etc/ssh/sshd_config >"/etc/ssh/sshd_config.ofDefault.$(($((`ls -1 /etc/ssh | grep sshd_config.ofDefault | grep -Eo '[^\.]+$' | sed -e 's/^.*[^0-9].*$/0/' | sort -n | tail -n 1`)) + 1))";
    else cat /etc/ssh/sshd_config >/etc/ssh/sshd_config.ofDefault; fi

    local -A _configs=(
      ["AddressFamily"]="inet"
      ["Port"]="${_port}"
      ["PermitRootLogin"]="without-password"
      ["PubkeyAuthentication"]="yes"
      ["PasswordAuthentication"]="no"
      ["PermitEmptyPasswords"]="no"
      ["ChallengeResponseAuthentication"]="no"
      ["KerberosAuthentication"]="no"
      ["GSSAPIAuthentication"]="no"
      ["UsePAM"]="yes"
      ["UseDNS"]="no"
    )

    for _config in "${!_configs[@]}"; do
      if grep -E "^${_config} +${_configs[${_config}]}$" /etc/ssh/sshd_config >/dev/null 2>&1; then :;
      elif grep -E "^#${_config} +${_configs[${_config}]}$" /etc/ssh/sshd_config >/dev/null 2>&1; then sed -i -e "s/^${_config}/#\0/" -e "s/^#\(${_config} \+${_configs[${_config}]}\)$/\1/" /etc/ssh/sshd_config;
      else sed -i -e "s/^${_config}/#\0/" -e "0,/^#\?${_config}.*/s/^#\?\(${_config}\) \+\(.*\)/\1 ${_configs[${_config}]}\n#\1 \2/" /etc/ssh/sshd_config; fi
    done

    if systemctl reload sshd >/dev/null 2>&1; then :;
    else _result=1;
      if [[ $(ls -1 /etc/ssh | grep sshd_config.ofDefault | wc -l) -gt 1 ]]; then
        cat "/etc/ssh/sshd_config.ofDefault.`ls -1 /etc/ssh | grep sshd_config.ofDefault | grep -Eo '[^\.]+$' | sed -e 's/^.*[^0-9].*$/0/' | sort -n | tail -n 1`" >/etc/ssh/sshd_config
      else cat /etc/ssh/sshd_config.ofDefault >/etc/ssh/sshd_config; fi
      if systemctl restart sshd >/dev/null 2>&1; then :;
      else echo -e "${_indent}\xF0\x9F\x91\xB9: FATAL ERROR, check out /etc/ssh/sshd_config, sorry ."; fi
    fi
  fi

  if [[ -z "${_port}" ]]; then _result=0;
  elif [[ $((_result)) -ne 0 ]]; then echo -e "${_indent}\xF0\x9F\x91\xB9: initialization failed, should change SSH port number another way .";
  else echo -e "${_indent}\xF0\x9F\x8D\xA3: SSH now ready to connect via ${_port}/TCP ."; fi

  return ${_result}
}

_ssh_modify "${1:-}"
