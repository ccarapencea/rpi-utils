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
sudo apt install \
    acl \
    iotop \
    xrdp \
    samba \
    samba-common-bin \
    smbclient \
    cifs-utils \


echo "Setting permissions..."
sudo chmod a+rx "/media"
sudo chmod a+rx "/media/${USER_NAME}"
sudo chmod a+rwx "${CONFIG_MEDIA_EXT_MOUNT}"


echo "Setting up media directories..."
mkdir -p "${CONFIG_MEDIA_DIR}"
if [[ -v CONFIG_MEDIA_EXT_MOUNT ]]; then
    ln -sfn "${CONFIG_MEDIA_EXT_MOUNT}" "${CONFIG_MEDIA_DIR}/data-ext"
fi
if [[ -v CONFIG_MEDIA_NTFS_MOUNT ]]; then
    ln -sfn "${CONFIG_MEDIA_NTFS_MOUNT}" "${CONFIG_MEDIA_DIR}/data-ntfs"
fi
if [[ -v CONFIG_SAMBA_CLIENT_MOUNT ]]; then
    "${SCRIPT_DIR}/setup-samba-client.sh"
fi


SMB_CONF="/etc/samba/smb.conf"
if ! grep -q "^[[:space:]]*\[${CONFIG_SAMBA_SERVER_SHARE}\][[:space:]]*$" "${SMB_CONF}"; then
    echo "Configuring up the Samba share..."
    sudo cp "${SMB_CONF}" "${SMB_CONF}.${TIME}.${TIMESTAMP}.bak"

    echo | sudo tee -a "${SMB_CONF}"
    echo "[${CONFIG_SAMBA_SERVER_SHARE}]" | sudo tee -a "${SMB_CONF}"
    echo "path = ${CONFIG_MEDIA_DIR}" | sudo tee -a "${SMB_CONF}"
    echo "writeable = yes" | sudo tee -a "${SMB_CONF}"
    echo "create mask = 0777" | sudo tee -a "${SMB_CONF}"
    echo "directory mask = 0777" | sudo tee -a "${SMB_CONF}"
    echo "public = no" | sudo tee -a "${SMB_CONF}"
    echo "force user = pi" | sudo tee -a "${SMB_CONF}"

    echo | sudo tee -a "${SMB_CONF}"
    echo "[ext]" | sudo tee -a "${SMB_CONF}"
    echo "path = ${CONFIG_MEDIA_EXT_MOUNT}" | sudo tee -a "${SMB_CONF}"
    echo "writeable = yes" | sudo tee -a "${SMB_CONF}"
    echo "create mask = 0777" | sudo tee -a "${SMB_CONF}"
    echo "directory mask = 0777" | sudo tee -a "${SMB_CONF}"
    echo "public = no" | sudo tee -a "${SMB_CONF}"
    echo "force user = pi" | sudo tee -a "${SMB_CONF}"
    echo | sudo tee -a "${SMB_CONF}"

    echo "[ntfs]" | sudo tee -a "${SMB_CONF}"
    echo "path = ${CONFIG_MEDIA_EXT_MOUNT}" | sudo tee -a "${SMB_CONF}"
    echo "writeable = yes" | sudo tee -a "${SMB_CONF}"
    echo "create mask = 0777" | sudo tee -a "${SMB_CONF}"
    echo "directory mask = 0777" | sudo tee -a "${SMB_CONF}"
    echo "public = no" | sudo tee -a "${SMB_CONF}"
    echo "force user = pi" | sudo tee -a "${SMB_CONF}"
fi


echo "Configuring the Samba user..."
printf "${CONFIG_SAMBA_SERVER_PASSWORD}\n${CONFIG_SAMBA_SERVER_PASSWORD}\n" | sudo smbpasswd -s -a "${CONFIG_SAMBA_SERVER_USER}"
sudo systemctl restart smbd


if [[ ${CONFIG_PLEX} == true ]]; then
    echo "Setting up Plex..."
    "${SCRIPT_DIR}/setup-plex.sh"
fi

if [[ ${CONFIG_DLNA} == true ]]; then
    echo "Setting up Minidlna..."
    "${SCRIPT_DIR}/setup-minidlna.sh"
fi

if [[ ${CONFIG_TORRENT} == true ]]; then
    echo "Setting up Transmission..."
    "${SCRIPT_DIR}/setup-transmission.sh"
fi


echo "@reboot root ${SCRIPT_DIR}/media-usb-reload.sh" | sudo tee "/etc/cron.d/usb-crontab"
