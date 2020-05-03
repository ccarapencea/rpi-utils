#!/usr/bin/env bash

SCRIPT=$(readlink -f "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT}")
USER_NAME=$(whoami)
source "${SCRIPT_DIR}/config.cfg"

TIME=$(date --utc --iso-8601=date)
TIMESTAMP=$(date +%s)


if [[ ${CONFIG_UPDATE_PACKAGES} == true ]]; then
    echo "Updating packages..."
    sudo apt update
    sudo apt upgrade
fi


echo "Installing packages..."
sudo apt install minidlna


echo "Configuring MiniDLNA..."
MINIDLNA_CONF="/etc/minidlna.conf"
sudo cp "${MINIDLNA_CONF}" "${MINIDLNA_CONF}.${TIME}.${TIMESTAMP}.bak"

MINIDLNA_PATTERN=".*wide_links=.*"
MINIDLNA_REPLACEMENT="wide_links=yes"
sudo sed -i -r "s/${MINIDLNA_PATTERN}/${MINIDLNA_REPLACEMENT}/g" ${MINIDLNA_CONF}

MINIDLNA_PATTERN=".*inotify=.*"
MINIDLNA_REPLACEMENT="inotify=yes"
sudo sed -i -r "s/${MINIDLNA_PATTERN}/${MINIDLNA_REPLACEMENT}/g" ${MINIDLNA_CONF}

if [[ ${CONFIG_DLNA_MERGE_DIRS} == true ]]; then
    MINIDLNA_PATTERN=".*merge_media_dirs=.*"
    MINIDLNA_REPLACEMENT="merge_media_dirs=yes"
    sudo sed -i -r "s/${MINIDLNA_PATTERN}/${MINIDLNA_REPLACEMENT}/g" ${MINIDLNA_CONF}
fi

sudo sed -i -r "/^[[:space:]]*media_dir=/d" ${MINIDLNA_CONF}
for DIR in "${CONFIG_DLNA_VIDEO_DIRS[@]}"; do
    if ! grep -q "^[[:space:]]*media_dir=V,${DIR}[[:space:]]*" ${MINIDLNA_CONF}; then
        echo "media_dir=V,${DIR}" | sudo tee -a ${MINIDLNA_CONF}
    fi
done
for DIR in "${CONFIG_DLNA_AUDIO_DIRS[@]}"; do
    if ! grep -q "^[[:space:]]*media_dir=A,${DIR}[[:space:]]*" ${MINIDLNA_CONF}; then
        echo "media_dir=A,${DIR}" | sudo tee -a ${MINIDLNA_CONF}
    fi
done
for DIR in "${CONFIG_DLNA_PICTURE_DIRS[@]}"; do
    if ! grep -q "^[[:space:]]*media_dir=P,${DIR}[[:space:]]*" ${MINIDLNA_CONF}; then
        echo "media_dir=P,${DIR}" | sudo tee -a ${MINIDLNA_CONF}
    fi
done

sudo systemctl restart minidlna
