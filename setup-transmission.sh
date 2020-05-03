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
sudo apt install transmission-daemon


echo "Configuring Transmission..."
sudo systemctl stop transmission-daemon

TRANSMISSION_CUSTOM_SETTINGS="${SCRIPT_DIR}/files/transmission/settings.json"
if [[ -f "${TRANSMISSION_CUSTOM_SETTINGS}" ]]; then
    TRANSMISSION_SETTINGS="/etc/transmission-daemon/settings.json"
    sudo mv "${TRANSMISSION_SETTINGS}" "${TRANSMISSION_SETTINGS}.${TIME}.${TIMESTAMP}.bak"
    sudo cp "${TRANSMISSION_CUSTOM_SETTINGS}" "${TRANSMISSION_SETTINGS}"
fi

if [[ ${CONFIG_TORRENT_CHANGE_USER} == true ]]; then
    TRANSMISSION_FILE="/etc/init.d/transmission-daemon"
    sudo cp "${TRANSMISSION_FILE}" "${TRANSMISSION_FILE}.${TIME}.${TIMESTAMP}.bak"
    TRANSMISSION_PATTERN="^[[:space:]]*USER=.*"
    TRANSMISSION_REPLACEMENT="USER=${USER_NAME}"
    sudo sed -i -r "s/${TRANSMISSION_PATTERN}/${TRANSMISSION_REPLACEMENT}/g" ${TRANSMISSION_FILE}

    TRANSMISSION_FILE="/etc/systemd/system/multi-user.target.wants/transmission-daemon.service"
    sudo cp "${TRANSMISSION_FILE}" "${TRANSMISSION_FILE}.${TIME}.${TIMESTAMP}.bak"
    TRANSMISSION_PATTERN="^[[:space:]]*User=.*"
    TRANSMISSION_REPLACEMENT="User=${USER_NAME}"
    sudo sed -i -r "s/${TRANSMISSION_PATTERN}/${TRANSMISSION_REPLACEMENT}/g" ${TRANSMISSION_FILE}

    sudo chown -R "${USER_NAME}:debian-transmission" /etc/transmission-daemon
    sudo mkdir -p /home/pi/.config/transmission-daemon/
    sudo ln -sf "/etc/transmission-daemon/settings.json" "/home/${USER_NAME}/.config/transmission-daemon/"
    sudo chown -R "${USER_NAME}:debian-transmission" "/home/${USER_NAME}/.config/transmission-daemon/"
fi

sudo systemctl daemon-reload
sudo usermod -a -G debian-transmission "${USER_NAME}"
sudo systemctl restart transmission-daemon
