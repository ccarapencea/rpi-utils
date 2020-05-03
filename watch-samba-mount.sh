#!/usr/bin/env bash

SCRIPT=$(readlink -f "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT}")
USER_NAME=$(whoami)
source "${SCRIPT_DIR}/config.cfg"


if [[ -z "$(ls -A ${CONFIG_SAMBA_CLIENT_MOUNT})" ]]; then
    echo "Could not find '${CONFIG_SAMBA_CLIENT_MOUNT}' - remounting..."
    mount -av
fi
