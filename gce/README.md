# Google Compute Engine

## Prerequirement
add some metadatas before you create VM instance .

 key | default value if not specified the value of this key
 ---- | ----
 locale | (no change locale, if not specified the value of this key .)
 timezone | (no change Timezone, if not specified the value of this key .)
 ssh-port | (nothing to do about SSH daemon, if not specified the value of this key .)
 ssh-config-options | you can override SSH setting with option named as "ssh_config_options", like this  "PasswordAuthentication=yes PermitRootLogin=yes" .
 ssh-key-passphrase | (create random string using mkpasswd, if not specified the value of this key or empty .)
 ssh-keygen-options | "-t ed25519"

### server status notification using IFTTT .
 key | default value if not specified the value of this key
 ---- | ----
 ifttt-api-key | (nothing to do about IFTTT, if not specified the value of this key .)

### server status notification using Slack and HUBOT
 key | default value if not specified the value of this key
 ---- | ----
 slackbot-user | Shockwave (1101)
 slackbot-group | decepticons (1111)
 hubot-slack-token | (nothing to do about Slack, if not specified the value of this key .)
 hubot-home | /home/shockwave/hubot-shockwave
 hubot-name | slackbot-shockwave
 hubot-desc | server status notifierer generated by Cogman .
 hubot-owner | shockwave <shockwave.[project-id].gce@example.com>

## TL;DR
[That's it .](https://github.com/furplag/cogman/blob/main/gce/el.startup.sh)
```bash
curl "https://github.com/furplag/cogman/raw/main/gce/el.startup.sh" -LfsS | bash
```
