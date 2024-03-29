#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# configuration/ssh.keygen.sh
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
    ["sshkey"]='\xF0\x9F\x94\x90'
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
# just a shorthand .
#
# @param passphrase passphrase of private key file
# @return generated password if passphrase is empty
function _passphrase() {
  local _result=${1:-}
  if [[ -n ${_result} ]]; then :;
  elif mkpasswd >/dev/null 2>&1; then _result="$(mkpasswd -l 14 -d 2 -s 2)";
  elif dnf install -y expect >/dev/null 2>&1; then _result="$(mkpasswd -l 14 -d 2 -s 2)";
  elif yum install -y expect >/dev/null 2>&1; then _result="$(mkpasswd -l 14 -d 2 -s 2)"; fi

  echo $_result;
}

###
# generate SSH key pair .
#
# @param _ssh_key_passphrase create random string using mkpasswd, if not specified the value of this key or empty
# @param _ssh_keygen_options parameter which ssh key generate ( default: -t ed25519 ) .
function _ssh_keygen() {
  local -r _indent="${indent}${symbols['sshkey']}"
  local -r _dir=${HOME:-/root}/.ssh
  local -r _prefix=${HOSTNAME:-"cogman-generated"}.ssh
  local -i _result=1
  [[ -d ${_dir} ]] || mkdir -p ${_dir}
  if [ -f "${_dir}/${_prefix}.ssh.privatekey" ]; then
    echo -e "${_indent}${symbols['ignore']}: SSH key already generated, check out key file \"${_prefix}.ssh.privatekey\" in \"${_dir}\" .";
    _result=0;
  else
    local -r _ssh_key_passphrase="$(_passphrase "${1:-}")"
    local -r _ssh_keygen_options="${2:-"-t ed25519"}"

    if [[ -z "${_ssh_key_passphrase}" ]]; then echo -e "${_indent}${symbols['unspecified']}: could not generate key without passphrase .";
    elif ssh-keygen ${_ssh_keygen_options} -N "${_ssh_key_passphrase}" -C "${HOSTNAME}" -f "${_dir}/${_prefix}.key" 1>/dev/null; then
      cat ${_dir}/${_prefix}.key.pub >>${_dir}/authorized_keys && \
      mv ${_dir}/${_prefix}.key ${_dir}/${_prefix}.privatekey && \
      mv ${_dir}/${_prefix}.key.pub ${_dir}/${_prefix}.publickey && \
      chmod -R 600 ${_dir} && \
      chmod -R 400 ${_dir}/*.{public,private}key

      echo -e "${_indent}${symbols['remark']}: Remember that, the passphrase is: \"${_ssh_key_passphrase}\" ."
      echo -e "${_indent}${symbols['remark']}: \xF0\x9F\x99\x88\xF0\x9F\x99\x8A\xF0\x9F\x99\x89   MAKE IT NOTE OF BELOW, AND   \xF0\x9F\x99\x89\xF0\x9F\x99\x8A\xF0\x9F\x99\x88"
      cat ${_dir}/${_prefix}.privatekey
      echo -e "${_indent}${symbols['remark']}: \xF0\x9F\x99\x88\xF0\x9F\x99\x8A\xF0\x9F\x99\x89 PLEASE KEEP IT IN A SAFE PLACE \xF0\x9F\x99\x89\xF0\x9F\x99\x8A\xF0\x9F\x99\x88"
      _result=0;
    else echo -e "${_indent}${symbols['fatal']}: initialization failed, should generate SSH key pair another way ."; fi
  fi

  return ${_result}
}

_ssh_keygen "${1:-}" "${2:-}"
