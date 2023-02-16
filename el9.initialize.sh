#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# el9.initialize.sh
# https://github.com/furplag/cogman
# Copyright 2019+ furplag
# Licensed under MIT (https://github.com/furplag/cogman/blob/main/LICENSE)
#
# scripts on initial settings to virtual machines,
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
#     - SSH daemon setting (sshd) .
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
#   3.  and never repeated .

###
# variable
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
if ! declare -p repo_url >/dev/null 2>&1; then declare -r repo_url='https://raw.githubusercontent.com/furplag/cogman/main'; fi
if ! declare -p we_have_done >/dev/null 2>&1; then declare -r we_have_done='/etc/profile.d/cogman.initialized.sh'; fi

# add some parameter before you create instance .
# key | default value if not specified the value of this key
# ---- | ----
# locale_lang | (no change locale, if not specified the value of this key .)
# timezone | (no change Timezone, if not specified the value of this key .)
# ssh_port_number | (nothing to do about SSH daemon, if not specified the value of this key .)
# ssh_config_options | e.g. "PasswordAuthentication=yes UseDNS=no" ( use default settings, if not specified the value of this key .)
# ssh_key_passphrase | (create random string using mkpasswd, if not specified the value of this key or empty .)
# ssh_keygen_options | -t ed25519 ( e.g. RSA key: -t rsa -b 4096 .)
# skip_ssh_keygen | (declare this variable with no value, if you want to skip generate SSH keypair .)
if ! declare -p locale_lang >/dev/null 2>&1; then declare -r locale_lang=; fi
if ! declare -p timezone >/dev/null 2>&1; then declare -r timezone=; fi
if ! declare -p ssh_port_number >/dev/null 2>&1; then declare -r ssh_port_number=; fi

if ! declare -p ssh_config_options >/dev/null 2>&1; then declare -r ssh_config_options=; fi
if ! declare -p ssh_key_passphrase >/dev/null 2>&1; then declare -r ssh_key_passphrase=; fi
if ! declare -p ssh_keygen_options >/dev/null 2>&1; then declare -r ssh_keygen_options=; fi

# vars of server status notification using Slack and HUBOT
if ! declare -p slackbot_user >/dev/null 2>&1; then declare -r slackbot_user=; fi
if ! declare -p slackbot_group >/dev/null 2>&1; then declare -r slackbot_group=; fi
if ! declare -p slackbot_uid >/dev/null 2>&1; then declare -ir slackbot_uid=; fi
if ! declare -p slackbot_gid >/dev/null 2>&1; then declare -ir slackbot_gid=; fi
if ! declare -p hubot_slack_token >/dev/null 2>&1; then declare -r hubot_slack_token=; fi
if ! declare -p hubot_owner_domain >/dev/null 2>&1; then declare -r hubot_owner_domain=; fi
if ! declare -p hubot_home >/dev/null 2>&1; then declare -r hubot_home=; fi
if ! declare -p hubot_name >/dev/null 2>&1; then declare -r hubot_name=; fi
if ! declare -p hubot_desc >/dev/null 2>&1; then declare -r hubot_desc=; fi
if ! declare -p hubot_owner >/dev/null 2>&1; then declare -r hubot_owner=; fi
if ! declare -p hubot_heroku_keepalive >/dev/null 2>&1; then declare -ir hubot_heroku_keepalive=; fi

# start .
if declare -p indent >/dev/null 2>&1; then indent="${indent}${symbols['initialize']}"; else declare indent="${symbols['cogman']}${symbols['initialize']}"; fi

declare -r script_path=${repo_url}/configuration

###
# Prerequirement
#
# all commands need you are "root" or you listed in "wheel" .
[[ ${EUID:-${UID}} -ne 0 ]] && [[ $(id -u) -ne 0 ]] && \
  echo -e "${indent}${symbols['fatal']}: this script must have to run as Root user .\n${indent}${symbols['fatal']}: Hint: sudo ${0} ." && exit 1

# load ./misc.sh .
if ! misc_available >/dev/null 2>&1; then source <(curl "${repo_url}/configuration/misc.sh" -fLs); fi

###
# functions
echo -e "${indent}    : start processing to server initialize ..."

# i18N (Locale / Language) setting .
if do_we_have_to_do 'locale'; then echo -e "${indent}${symbols['locale']}  : setting i18N (Locale / Language) ...";
  if bash -c "curl ${script_path}/locale.sh -LfsS | bash -s ${locale_lang}"; then do_config_completed 'locale'; fi
else echo -e "${indent}${symbols['locale']}${symbols['ignore']}: system locale already set to \"$(locale | grep -E ^LANG= | sed -e 's/LANG=//')\" ."; fi

# l10N (Timezone) setting .
if do_we_have_to_do 'timezone'; then echo -e "${indent}${symbols['timezone']}  : setting l10N (Timezone) ...";
  if bash -c "curl ${script_path}/timezone.sh -LfsS | bash -s ${timezone}"; then do_config_completed 'timezone'; fi
else echo -e "${indent}${symbols['timezone']}${symbols['ignore']}: system Timezone already set to \"$(timedatectl status | grep zone | sed -e 's/^.*zone: \+//' -e 's/ .*$//')\" ."; fi

# Unforcing SELinux .
if do_we_have_to_do 'selinux'; then echo -e "${indent}${symbols['selinux']}  : unforcing SELinux ...";
  if bash <(curl "${script_path}/unforceSELinux.el9.sh" -LfsS); then do_config_completed 'selinux'; fi
else echo -e "${indent}${symbols['selinux']}${symbols['ignore']}: SELinux already unforced ( $(grep -Ei ^SELINUX\=[^\s]+ /etc/selinux/config | sed -e 's/.*=//') ) ."; fi

# change SSH port number for protect under crack .
if do_we_have_to_do 'ssh'; then echo -e "${indent}${symbols['ssh']}  : change SSH port number for protect under crack ...";
  if bash -c "curl ${script_path}/ssh.modify.sh -LfsS | bash -s -- \"${ssh_port_number}\" \"${ssh_config_options}\""; then do_config_completed 'ssh'; fi
else
  declare -a _current_ports=(`grep -Ei '^Port' /etc/ssh/sshd_config | grep -Eo '[0-9]+' 2>/dev/null`)
  if [[ ${#_current_ports[*]} -lt 1 ]]; then _current_ports=(22); fi
  echo -e "${indent}${symbols['ssh']}${symbols['ignore']}: SSH daemon running with port number(s) \"${_current_ports}\", already .";
fi

# generate SSH key pair .
if declare -p skip_ssh_keygen >/dev/null 2>&1; then echo -e "${indent}${symbols['sshkey']}${symbols['ignore']}: skipping generate SSH key pair ."; do_config_completed 'sshkey';
elif do_we_have_to_do 'sshkey'; then echo -e "${indent}${symbols['sshkey']}  : generate SSH key pair ...";
  if bash -c "curl ${script_path}/ssh.keygen.sh -LfsS | bash -s -- \"${ssh_key_passphrase}\" \"${ssh_keygen_options}\""; then do_config_completed 'sshkey'; fi
else echo -e "${indent}${symbols['sshkey']}${symbols['ignore']}: SSH key already generated, check out directory \"/root/.ssh\" ."; fi

# and never repeated .
echo -e "# ${we_have_done}\n\nexport INIT_CONFIG_INITIALIZED=${INIT_CONFIG_INITIALIZED}\n" >"${we_have_done}"

# result .
if [[ -n "${INIT_CONFIG_INITIALIZED:-}" ]]; then
  echo -e "${indent}    : server initialization completed:"
  for completed in $(echo "${INIT_CONFIG_INITIALIZED}" | sed -e 's/,/\n/g' | sort); do
    echo -e "${indent}    : ${symbols[$completed]} ${completed}"
  done
fi

# end .
indent="$(echo -e ${indent} | sed -e "s/${symbols['initialize']}//")"
