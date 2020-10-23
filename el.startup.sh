#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# el.startup.sh
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
if ! declare -p init_configs >/dev/null 2>&1; then declare -r init_configs='locale selinux slackbot ssh sshkey timezone'; fi
if ! declare -p indent >/dev/null 2>&1; then declare indent="${symbols['cogman']}"; fi

# vars of server initialization
if ! declare -p locale_lang >/dev/null 2>&1; then declare -r locale_lang=; fi
if ! declare -p timezone >/dev/null 2>&1; then declare -r timezone=; fi
if ! declare -p ssh_port_number >/dev/null 2>&1; then declare -r ssh_port_number=; fi
if ! declare -p ssh_config_options >/dev/null 2>&1; then declare -r ssh_config_options=; fi
if ! declare -p ssh_key_passphrase >/dev/null 2>&1; then declare -r ssh_key_passphrase=; fi
if ! declare -p ssh_keygen_options >/dev/null 2>&1; then declare -r ssh_keygen_options='-t ed25519'; fi

# vars of server status notification using IFTTT
if ! declare -p ifttt_api_key >/dev/null 2>&1; then declare -r ifttt_api_key=${IFTTT_API_KEY:-}; fi
if ! declare -p platform >/dev/null 2>&1; then declare -r platform='unknown'; fi
if ! declare -p project >/dev/null 2>&1; then declare -r project='unknown'; fi
if ! declare -p instance >/dev/null 2>&1; then declare -r instance="$(hostname)"; fi
if ! declare -p eventName >/dev/null 2>&1; then declare -r eventName='statechanged'; fi
if ! declare -p status >/dev/null 2>&1; then declare -r status='started'; fi

# vars of server status notification using Slack and HUBOT
if ! declare -p slackbot_user >/dev/null 2>&1; then declare -r slackbot_user='shockwave'; fi
if ! declare -p slackbot_group >/dev/null 2>&1; then declare -r slackbot_group='decepticons'; fi
if ! declare -p slackbot_uid >/dev/null 2>&1; then declare -ir slackbot_uid=1101; fi
if ! declare -p slackbot_gid >/dev/null 2>&1; then declare -ir slackbot_gid=1111; fi
if ! declare -p hubot_slack_token >/dev/null 2>&1; then declare -r hubot_slack_token=${HUBOT_SLACK_TOKEN:-}; fi
if ! declare -p hubot_owner_domain >/dev/null 2>&1; then declare -r hubot_owner_domain='example.com'; fi
if ! declare -p hubot_home >/dev/null 2>&1; then declare -r hubot_home="/home/${slackbot_user}/hubot-${slackbot_user}"; fi
if ! declare -p hubot_name >/dev/null 2>&1; then declare -r hubot_name="slackbot-${slackbot_user}"; fi
if ! declare -p hubot_desc >/dev/null 2>&1; then declare -r hubot_desc='server status notifierer generated by Cogman .'; fi
if ! declare -p hubot_owner >/dev/null 2>&1; then declare -r hubot_owner="${slackbot_user} ${slackbot_user}.${instance,,}.${project,,}.${platform,,}@${hubot_owner_domain}"; fi

# load ./misc.sh .
source <(curl "${repo_url}/configuration/misc.sh" -fLs);

# Server initial setting (do only first time) .
if ! did_we_have_done; then source <(curl "${repo_url}/el.initialize.sh" -fLsS); fi

# Server startup notification .
if ! do_we_have_to_do 'slackbot' || [[ -z "${ifttt_api_key:-}" ]]; then
  echo -e "${indent}${symbols['success']}    : ${eventName}/${status}"
  echo -e "${indent}      : Platform: ${platform}"
  echo -e "${indent}      : Project : ${project}"
  echo -e "${indent}      : Instance: ${instance}"
elif ! bash -c "curl ${repo_url}/notification/ifttt.webhook.sh -LfsS | bash -s \"${ifttt_api_key}\" \"${eventName}\" \"${status}\" \"${platform}/${project}\" \"${instance}\""; then
  echo -e "${indent}${symbols['fatal']}    : server startup notification (IFTTT webhook) failed .";
fi

# end .
indent="${symbols['cogman']}"
