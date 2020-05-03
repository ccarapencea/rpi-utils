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


SOURCE_FILE="/etc/apt/sources.list.d/plexmediaserver.list"
if [[ ! -f "${SOURCE_FILE}" ]]; then
    echo "Adding package repository..."
    sudo apt install apt-transport-https
    curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add -
    echo deb https://downloads.plex.tv/repo/deb public main | sudo tee "${SOURCE_FILE}"
    sudo apt update
fi


echo "Installing packages..."
sudo apt install plexmediaserver
