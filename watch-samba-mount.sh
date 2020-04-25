#!/usr/bin/env bash

SCRIPT=$(readlink -f "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT}")
USER_NAME=$(whoami)
source "${SCRIPT_DIR}/config.cfg"

MOUNT_DIR="/mnt/${CONFIG_SAMBA_CLIENT_SHARE}"
if [[ -z "$(ls -A ${MOUNT_DIR})" ]]; then
    echo "Could not find '${MOUNT}' - remounting..."
    mount -av
fi
