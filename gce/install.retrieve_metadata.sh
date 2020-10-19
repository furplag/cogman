#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# gce/install_retrieve_metadata.sh
# https://github.com/furplag/cogman
# Copyright 2019+ furplag
# Licensed under MIT (https://github.com/furplag/cogman/blob/main/LICENSE)
#
# get metadata from GCP setting .
# see also https://cloud.google.com/compute/docs/storing-retrieving-metadata .
#
# enable to use command, e.g. "retrieve_meta project-id 'unknown'" .


###
# variable
if ! declare -p repo_url >/dev/null 2>&1; then declare -r repo_url='https://raw.githubusercontent.com/furplag/cogman/main'; fi

curl "${repo_url}/gce/retrieve_metadata" -LfsS -o /usr/local/bin/retrieve_metadata
if cat /usr/local/bin/retrieve_metadata >/dev/null 2>&1; then chmod +x /usr/local/bin/retrieve_metadata; fi

