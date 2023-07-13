#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# configuration/ssh.modify.el9.sh
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
    ["ssh"]='\xE2\x9A\xA1'
    ["success"]='\xF0\x9F\x8D\xA3'
    ["error"]='\xF0\x9F\x91\xBA'
    ["fatal"]='\xF0\x9F\x91\xB9'
    ["ignore"]='\xF0\x9F\x8D\xA5'
    ["unspecified"]='\xF0\x9F\x99\x89'
    ["remark"]='\xF0\x9F\x91\xBE'
  )
 declare indent="${symbols['cogman']}${symbols['initialize']}";
fi

###
# function

###
# returns a port number used to SSH currently .
#
# @return SSH port number
function _get_ssh_ports() {
  local -ar _currents=(`grep -Ei '^Port' /etc/ssh/sshd_config | grep -Eo '[0-9]+' 2>/dev/null`)

  if [[ ${#_currents[*]} -lt 1 ]]; then echo "22"; else echo "${_currents}"; fi
}

###
# change SSH port number for protect under crack .
#
# @param _port TCP port number to change
# @param _config_options SSH config parameter
function _ssh_modify() {
  local -r _port="${1:-}"
  local -a _config_options=${2:-}
  local -ar _current_ports=(`_get_ssh_ports`)
  local -r _indent="${indent}${symbols['ssh']}"
  local -i _result=1
  local -A _configs=(
    ["AddressFamily"]="inet"
    ["Port"]="${_port:-22}"
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

  for _config_option in ${_config_options}; do
    local _k="$(echo "${_config_option}" | sed -e 's/=.*$//')"
    local _v="$(echo "${_config_option}" | sed -e 's/^.*=//')"
    if [[ -n "${_k}" ]] && [[ -n "${_v}" ]] && [[ " ${!_configs[@]} " =~ " ${_k} " ]]; then _configs[${_k}]="${_v}"; fi
  done

  if [[ -z "${_port}" ]]; then _result=0; echo -e "${_indent}${symbols['unspecified']}: the value of \"ssh-port\" not spacified ( current setting: ${_current_ports} ) .";
  elif echo "${_port}" | grep -Eo '[^0-9]' >/dev/null 2>&1; then echo -e "${_indent}${symbols['error']}: the value \"${_port}\" is invalid port number .";
  elif [[ $((_port)) -lt 1 ]] || [[ $((_port)) -gt 65535 ]]; then echo -e "${_indent}${symbols['error']}: the value \"${_port}\" is invalid port number .";
  elif [[ " ${_current_ports} " =~ " ${_port} " ]]; then _result=0; echo -e "${_indent}${symbols['ignore']}: SSH already enabled to connect via ${_port}/TCP .";
  elif dnf install policycoreutils-python-utils -y >/dev/null 2>&1; then
    # add another port number of SSH to the list of SELinux allows .
    if semanage port -l | grep ssh_port_t | grep -Eo '[0-9]{1,5}' | grep -E "^${_port}\$" >/dev/null 2>&1; then :;
    elif semanage port -a -t ssh_port_t -p tcp ${_port}; then echo -e "${_indent}${symbols['success']}: add ${_port}/TCP to the list of SELinux allows ."; fi
    _result=0
  elif yum install policycoreutils-python -y >/dev/null 2>&1; then
    # add another port number of SSH to the list of SELinux allows .
    if semanage port -l | grep ssh_port_t | grep -Eo '[0-9]{1,5}' | grep -E "^${_port}\$" >/dev/null 2>&1; then :;
    elif semanage port -a -t ssh_port_t -p tcp ${_port}; then echo -e "${_indent}${symbols['success']}: add ${_port}/TCP to the list of SELinux allows ."; fi
    _result=0
  else echo -e "${_indent}${symbols['error']}: could not add ${_port}/TCP to the list of SELinux allows ."; fi

  if [[ $((_result)) -ne 0 ]]; then :;
  elif [[ "${_port:-22}" = "22" ]]; then :;
  elif semanage port -l | grep ssh_port_t | grep -Eo '[0-9]+' | grep -E "^${_port}\$" >/dev/null 2>&1; then
    # add SSH with another TCP port number to Firewall services .
    cat /usr/lib/firewalld/services/ssh.xml >"/etc/firewalld/services/ssh-${_port}.xml" && \
    sed -i -e "s@\(short>\).*\(<\/\)@\1SSH via ${_port}\2@" \
      -e "s/port=\".*\"/port=\"$_port\"/" \
      "/etc/firewalld/services/ssh-${_port}.xml" && \
    firewall-cmd --reload >/dev/null 2>&1 && :;
    if grep "port=\"${_port}\"" /etc/firewalld/services/ssh-${_port}.xml >/dev/null 2>&1; then
      echo -e "${_indent}${symbols['success']}: defined the service named as \"ssh-${_port}\", which accepts to connect SSH custom port ."
    fi
  fi

  if [[ $((_result)) -ne 0 ]]; then :;
  elif [[ "${_port:-22}" = "22" ]]; then :;
  elif systemctl status firewalld >/dev/null 2>&1; then
    # accept TCP port number \"${_port}\" on Firewall .
    for zone in `firewall-cmd --get-zones`; do
      if [[ ' block drop ' =~ " ${zone} " ]]; then :;
      elif [[ ! " `firewall-cmd --list-services --zone=${zone}` " =~ " ssh " ]]; then
        echo -e "${_indent}${symbols['ignore']}: zone \"${zone}\" disallowed SSH connect .";
      elif echo "`firewall-cmd --list-services --zone=${zone}`" | grep "ssh-${_port}" >/dev/null 2>&1; then
        echo -e "${_indent}${symbols['ignore']}: zone \"${zone}\" is accepted to connect via ${_port}/TCP, already .";
      elif firewall-cmd --add-service="ssh-${_port}" --zone=${zone} --permanent >/dev/null 2>&1; then
        echo -e "${_indent}${symbols['success']}: zone \"${zone}\" now ready to SSH connect via ${_port}/TCP .";
      else echo -e "${_indent}${symbols['error']}: could not allowed to SSH connect via ${_port}/TCP at zone \"${zone}\" ."; fi
    done
    if firewall-cmd --reload >/dev/null 2>&1; then :; else _result=1; fi
  else _result=1; fi

  if [[ $((_result)) -ne 0 ]]; then :;
  else
    # failsafe .
    if ls -1 /etc/ssh/sshd_config.d | grep 00-cogman-modified.conf >/dev/null 2>&1; then
      cat /etc/ssh/sshd_config.d/00-cogman-modified.conf >"/etc/ssh/sshd_config.d/00-cogman-modified.conf.$(($((`ls -1 /etc/ssh/sshd_config.d | grep 00-cogman-modified.conf | grep -Eo '[^\.]+$' | sed -e 's/^.*[^0-9].*$/0/' | sort -n | tail -n 1`)) + 1))";
    fi
    for _config in "${!_configs[@]}"; do echo "${_config} ${_configs[${_config}]}" >>/etc/ssh/sshd_config.d/00-cogman-modified.conf; done

    if systemctl restart sshd; then
      echo -e "${_indent}${symbols['success']}: SSH config changed to ...";
      for _config in "${!_configs[@]}"; do
        echo -e "${_indent}${symbols['success']}:   ${_config}=${_configs[${_config}]}";
      done
    else _result=1;
      rm -rf /etc/ssh/sshd_config.d/00-cogman-modified.conf;
      if systemctl restart sshd >/dev/null 2>&1; then :;
      else echo -e "${_indent}${symbols['fatal']}: FATAL ERROR, check out /etc/ssh/sshd_config, sorry ."; fi
    fi
  fi

  if [[ "${_port:-22}" = "22" ]]; then :;
  elif [[ $((_result)) -ne 0 ]]; then echo -e "${_indent}${symbols['fatal']}: initialization failed, should change SSH port number another way .";
  else echo -e "${_indent}${symbols['success']}: SSH now ready to connect via ${_port}/TCP ."; fi

  return ${_result}
}

_ssh_modify "${1:-}" "${2:-}"
