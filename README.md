# Cogman (CentOS 8)
scripts on startup, shutdown and initial settings to virtual machines, maybe useful for
all poor man like me, but currently just only for me own .

## Overview
1. ### Server initial setting (do only first time) .
    1. #### [makes some optimizations for the VM to stands a web server .](#user-content-makes-some-optimizations-for-the-vm-to-stands-a-web-server--1)
        - [i18N (Locale / Language) setting .](#user-content-i18n-locale--language-setting-)
        - [l10N (Timezone) setting .](#user-content-l10n-timezone-setting-)
        - [unforcing SELinux .](#user-content-unforcing-selinux-)
    1. #### [change SSH port number for protect under crack .](#user-content-change-ssh-port-number-for-protect-under-crack--1)
        - [Firewall setting (firewalld) .](#user-content-add-ssh-service-with-another-tcp-port-number-to-firewall-)
        - [SSH port number setting (sshd) .](#user-content-important-notice-)
            - only use Public Key Authentication .
            - enable to login as Root directly .
        - [generate SSH key pair .](#user-content-generate-ssh-key-pair-)
    1. #### and never repeated .
1. ### [Server startup/shutdown notification .](#user-content-server-startupshutdown-notification--1)
    - #### [using IFTTT .](#user-content-using-ifttt--1)

## Prerequirement

- [ ] a VM instance need to could be accessible to internet .
- [ ] all commands need you are "root" or you listed in "wheel" .

## Getting Start

### makes some optimizations for the VM to stands a web server .

#### i18N (Locale / Language) setting .
```bash
localctl set-locale LANG="${LANG}"
```

#### l10N (Timezone) setting .
```bash
timedatectl set-timezone "${Area/City}"
```
#### Unforcing SELinux .
Set "Permissive" to SELinux .
```bash
[[ $(getenforce | grep -Eo "^P" | wc -l) -lt 1 ]] && \
  sed -i -e 's/^SELINUX=.*/#\0\nSELINUX=Permissive/' /etc/selinux/config && \
  setenforce 0
```

### change SSH port number for protect under crack .

#### add SSH service with another TCP port number to Firewall .
```bash
ssh_port_number=${the_port_number_you_decide_to_change:-23456}

# add another port number of SSH to the list of SELinux allows .
[[ $(semanage port -l | grep ssh_port_t | grep ${ssh_port_number} |wc -l) -lt 1 ]] && \
  setenforce 1 && \
  semanage port -a -t ssh_port_t -p tcp ${ssh_port_number} && \
  setenforce 0

# add SSH with another TCP port number to Firewall services .
[[ ! -e /etc/firewalld/services/ssh-tweaked.xml ]] && \
  cat /usr/lib/firewalld/services/ssh.xml > /etc/firewalld/services/ssh-tweaked.xml
sed -i -e "s@\(short>\).*\(<\/\)@\1SSH via $ssh_port_number\2@" \
 -e "s/port=\".*\"/port=\"$ssh_port_number\"/" /etc/firewalld/services/ssh-tweaked.xml

# accept TCP port number \"${ssh_port_number}\" on Firewall .
[[ $(systemctl status firewalld | grep -E "active \(running\)" | wc -l) -gt 0 ]] && \
  systemctl restart firewalld && \
  firewall-cmd --reload && \
  [[ $(firewall-cmd --list-service --zone=public | grep ssh-tweaked | wc -l) -lt 1 ]] && \
  firewall-cmd --add-service=ssh-tweaked --zone=public --permanent && \
  firewall-cmd --reload
```

> ## Important notice:
> you should test to can be connect the server using new port
> before you logged out from current session .

#### SSH (sshd) setting .

| setting | change to |
|----|----|
| Port | the port number you  decide to change . |
| PermitRootLogin | without-password |
| PubkeyAuthentication | yes |
| PasswordAuthentication | no |
| PermitEmptyPasswords | no |
| ChallengeResponseAuthentication | no |
| GSSAPIAuthentication | no |

```bash
ssh_port_number=${the_port_number_you_decide_to_change:-23456}
cat /etc/ssh/sshd_config > /etc/ssh/sshd_config.ofDefault
sed -i -e "s/^#\?Port/Port ${ssh_port_number}\n#\0/" \
  -e 's/^#\?PermitRootLogin .*/PermitRootLogin without-password\n#\0/' \
  -e 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes\n#\0/' \
  -e 's/^#\?PasswordAuthentication .*/PasswordAuthentication no\n#\0/' \
  -e 's/^#\?PermitEmptyPasswords .*/PermitEmptyPasswords no\n#\0/' \
  -e 's/^#\?GSSAPIAuthentication .*/GSSAPIAuthentication no\n#\0/' \
  -e 's/^#\?GSSAPICleanupCredentials .*/GSSAPICleanupCredentials no\n#\0/' \
  -e 's/^#\+/#/' \
  /etc/ssh/sshd_config && \
  systemctl reload sshd

# systemctl status sshd
```
#### generate SSH key pair .
```bash
[[ -d ~/.ssh ]] || mkdir -p ~/.ssh
# variable
ssh_passphrase=${set_password_that_have_enough_strength:-$(mkpasswd -l 14 -d 2 -s 2)}
echo -e "remember that, the passphrase is \"${ssh_passphrase}\" ."
ssh-keygen -t Ed25519 -N ${ssh_passphrase} -C "${HOSTNAME}.ssh.key" -f ~/.ssh/${HOSTNAME}.ssh.key && \
  cat ~/.ssh/${HOSTNAME}.ssh.key.pub >> ~/.ssh/authorized_keys && \
  mv ~/.ssh/${HOSTNAME}.ssh.key ~/.ssh/${HOSTNAME}.private.key && \
  mv ~/.ssh/${HOSTNAME}.ssh.key.pub ~/.ssh/${HOSTNAME}.public.key && \
  chmod -R 600 ~/.ssh && \
  chmod -R 400 ~/.ssh/*.key
```

### Server startup/shutdown notification .
you can receive notification of server startup, shutdown and any some way .

- #### using IFTTT .
Create [IFTTT](https://ifttt.com) like that as below .
> IF This: webhook named as "${some_event_you_gazing}" event fired .
> Then That: send a email message from "Webhooks via IFTTT" to you .
>> Note: you should create endpoints of "send email" per events you need to receive notification .
See also [IFTTT webhook documentation](https://maker.ifttt.com/use/${key_of_ifttt_webhook_api}), for more information .
```bash
curl -X POST "https://maker.ifttt.com/trigger/${event_name}/with/key/${key_of_ifttt_webhook_api}" \
  -H "Content-Type: application/json" -d \
  "{\"value1\":\"${platform}\",\"value2\":\"${project}\",\"value3\":\"${instance}\"}"
```

## License
Code is under [MIT License](LICENSE).
