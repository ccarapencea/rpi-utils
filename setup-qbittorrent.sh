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
sudo apt install qbittorrent-nox

sudo useradd -r -m "${CONFIG_TORRENT_USER}"
sudo usermod -a -G "${CONFIG_TORRENT_USER}" ${USER_NAME}


SERVICE_FILE="/etc/systemd/system/qbittorrent.service"
sudo cp "${SERVICE_FILE}" "${SERVICE_FILE}.${TIME}.${TIMESTAMP}.bak"

echo "[Unit]" | sudo tee -a "${SERVICE_FILE}"
echo "Description=qBittorrent" | sudo tee -a "${SERVICE_FILE}"
echo "After=network.target" | sudo tee -a "${SERVICE_FILE}"
echo | sudo tee -a "${SERVICE_FILE}"
echo "[Service]" | sudo tee -a "${SERVICE_FILE}"
echo "Type=forking" | sudo tee -a "${SERVICE_FILE}"
echo "User=${CONFIG_TORRENT_USER}" | sudo tee -a "${SERVICE_FILE}"
echo "Group=${CONFIG_TORRENT_USER}" | sudo tee -a "${SERVICE_FILE}"
echo "UMask=002" | sudo tee -a "${SERVICE_FILE}"
echo "ExecStart=/usr/bin/qbittorrent-nox -d" | sudo tee -a "${SERVICE_FILE}"
echo "Restart=on-failure" | sudo tee -a "${SERVICE_FILE}"
echo | sudo tee -a "${SERVICE_FILE}"
echo "[Install]" | sudo tee -a "${SERVICE_FILE}"
echo "WantedBy=multi-user.target" | sudo tee -a "${SERVICE_FILE}"

sudo systemctl enable qbittorrent
sudo systemctl restart qbittorrent
