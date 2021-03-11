#!/bin/bash

set -eEuo pipefail

readonly OS_NAME="lubuntu"
readonly OS_VERSION="20.04"
readonly OS_ARCH="amd64"
readonly VM_PROVIDER="virtualbox"
readonly BASE_NAME="${OS_NAME}-${OS_VERSION}-${OS_ARCH}-${VM_PROVIDER}"
readonly BOX_NAME="${BASE_NAME}.box"

if [[ -e "${BOX_NAME}" ]]; then
    if [[ -f "${BOX_NAME}" ]]; then
        rm -vf "${BOX_NAME}"
    else
        printf 'Could not remove existing output file: %s\n' "${BOX_NAME}"
        exit 1
    fi
fi

set -x
vagrant box remove "${BASE_NAME}"
vagrant package --base "${BASE_NAME}" --output "${BOX_NAME}"
vagrant box add --force --name "${BASE_NAME}" "${BOX_NAME}"
set +x
