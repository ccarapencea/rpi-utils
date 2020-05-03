#!/usr/bin/env bash

SCRIPT=$(readlink -f "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT}")
USER_NAME=$(whoami)
source "${SCRIPT_DIR}/config.cfg"

if [[ -v CONFIG_MEDIA_EXT_MOUNT ]]; then
    while [[ ! -d ${CONFIG_MEDIA_EXT_MOUNT} ]]; do
        sleep 2
    done
fi

if [[ -v CONFIG_MEDIA_NTFS_MOUNT ]]; then
    while [[ ! -d ${CONFIG_MEDIA_NTFS_MOUNT} ]]; do
        sleep 2
    done
fi


if [[ ${CONFIG_DLNA} == true ]]; then
    echo "Reloading Minidlna..."s
    systemctl restart minidlna
fi

if [[ ${CONFIG_TORRENT} == true ]]; then
    echo "Reloading Transmission..."
    systemctl restart transmission-daemon
fi
