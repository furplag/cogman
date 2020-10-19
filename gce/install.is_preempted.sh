#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# gce/install_is_preempted.sh
# https://github.com/furplag/cogman
# Copyright 2019+ furplag
# Licensed under MIT (https://github.com/furplag/cogman/blob/main/LICENSE)
#
# detects whether this server getting under preempted or not .
# see also https://cloud.google.com/compute/docs/instances/preemptible .
#
# enable to use command, e.g. "if is_preempted; then echo 'preempted'; else echo 'shutdown'; fi" .


###
# variable
if ! declare -p repo_url >/dev/null 2>&1; then declare -r repo_url='https://raw.githubusercontent.com/furplag/cogman/main'; fi

curl "${repo_url}/gce/is_preempted" -LfsS -o /usr/local/bin/is_preempted
if cat /usr/local/bin/is_preempted >/dev/null 2>&1; then chmod +x /usr/local/bin/is_preempted; fi

