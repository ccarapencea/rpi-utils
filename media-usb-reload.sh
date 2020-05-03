#!/usr/bin/env bash

SCRIPT=$(readlink -f "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT}")
USER_NAME=pi
source "${SCRIPT_DIR}/config.cfg"

sleep 30

if [[ -v CONFIG_MEDIA_EXT_MOUNT ]]; then
    while [[ ! -d ${CONFIG_MEDIA_EXT_MOUNT} ]]; do
        sleep 2
        ls ${CONFIG_MEDIA_EXT_MOUNT}
    done
fi

if [[ -v CONFIG_MEDIA_NTFS_MOUNT ]]; then
    while [[ ! -d ${CONFIG_MEDIA_NTFS_MOUNT} ]]; do
        sleep 2
    done
fi


sleep 2

if [[ ${CONFIG_DLNA} == true ]]; then
    logger "Reloading Minidlna..."
    systemctl restart minidlna
fi

if [[ ${CONFIG_TORRENT} == true ]]; then
    logger "Reloading Transmission..."
    systemctl restart transmission-daemon
fi
