#!/usr/bin/env bash

SCRIPT=$(readlink -f "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT}")
USER_NAME=$(whoami)
source "${SCRIPT_DIR}/config.cfg"

SSH=true
IMAGE=${1:-CONFIG_OS_IMAGE}
HDD_MOUNT=${2:-CONFIG_ROOT_MOUNT}
SD_DEVICE=${3:-"/dev/mmcblk0"}
BLOCK_SIZE=${4:-"4M"}

SD_BOOT_MOUNT="/media/${USER_NAME}/boot"
SD_ROOT_MOUNT="/media/${USER_NAME}/rootfs"

HDD_PARTITION=$(findmnt -n -o SOURCE "${HDD_MOUNT}")
HDD_PARTUUID=$(lsblk -n -o PARTUUID ${HDD_PARTITION})
HHD_FSTYPE=$(lsblk -n -o FSTYPE ${HDD_PARTITION})

TIME=$(date --utc --iso-8601=date)
TIMESTAMP=$(date +%s)


if [[ ${CONFIG_IMAGE_CARD} == true ]]; then
    echo "Writing OS image to SD card..."
    for PARTITION in $(ls ${SD_DEVICE}?*); do udisksctl unmount -b $PARTITION; done
    sudo dd bs=${BLOCK_SIZE} if="${IMAGE}" of="${SD_DEVICE}" status=progress
    sudo partprobe
    sleep 2
    for PARTITION in $(ls ${SD_DEVICE}?*); do udisksctl mount -b $PARTITION; done
fi


if [[ ${CONFIG_INIT_HDD_ROOT} == true ]]; then
    echo "Initializing HDD root files..."
    sudo rsync -ax "${SD_ROOT_MOUNT}/" "${HDD_MOUNT}"
fi


echo "Configuring the boot root file system..."
CMDLINE_FILE="${SD_BOOT_MOUNT}/cmdline.txt"
cp "${CMDLINE_FILE}" "${CMDLINE_FILE}.${TIME}.${TIMESTAMP}.bak"

ROOT_PATTERN="[[:space:]]root=[^[:space:]]+"
ROOT_REPLACEMENT=" root=PARTUUID=${HDD_PARTUUID}"
sed -i -r "s/${ROOT_PATTERN}/${ROOT_REPLACEMENT}/g" ${CMDLINE_FILE}

ROOT_PATTERN="[[:space:]]rootfstype=[^[:space:]]+"
ROOT_REPLACEMENT=" rootfstype=${HHD_FSTYPE}"
sed -i -r "s/${ROOT_PATTERN}/${ROOT_REPLACEMENT}/g" ${CMDLINE_FILE}


echo "Configuring SSH..."
SSH_FILE="${SD_BOOT_MOUNT}/ssh"
mv "${SSH_FILE}" "${SSH_FILE}.${TIME}.${TIMESTAMP}.bak"
if [[ ${SSH} == true ]]; then
    touch "${SSH_FILE}"
fi


echo "Configuring Wi-Fi..."
WIFI_FILE="${SD_BOOT_MOUNT}/wpa_supplicant.conf"
mv "${WIFI_FILE}" "${WIFI_FILE}.${TIME}.${TIMESTAMP}.bak"
if [[ ${CONFIG_WIFI} == true ]]; then
    echo "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev" >> "${WIFI_FILE}"
    echo "update_config=1" >> "${WIFI_FILE}"
    echo "country=${CONFIG_WIFI_COUNTRY}" >> "${WIFI_FILE}"
    wpa_passphrase "${CONFIG_WIFI_SSID}" "${CONFIG_WIFI_PSK}" >> "${WIFI_FILE}"
    sed -i "/#psk=/d" "${WIFI_FILE}"
fi


if [[ ${CONFIG_SWAP} == true ]]; then
    echo "Configuring swap file..."
    SWAP_FILE="${HDD_MOUNT}/etc/dphys-swapfile"
    cp "${SWAP_FILE}" "${SWAP_FILE}.${TIME}.${TIMESTAMP}.bak"
    SWAP_PATTERN="CONF_SWAPSIZE=[^[:space:]]*"
    SWAP_REPLACEMENT="CONF_SWAPSIZE=${CONFIG_SWAP_SIZE}"
    sed -i -r "s/${SWAP_PATTERN}/${SWAP_REPLACEMENT}/g" ${SWAP_FILE}
fi
