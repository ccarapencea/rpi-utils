#!/usr/bin/env bash

SCRIPT=$(readlink -f "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT}")
USER_NAME=$(whoami)
source "${SCRIPT_DIR}/config.cfg"

TIME=$(date --utc --iso-8601=date)
TIMESTAMP=$(date +%s)

echo "Configuring Samba credentials..."
CREDENTIALS_FILE="/home/${USER_NAME}/.smbcredentials"
mv "${CREDENTIALS_FILE}" "${CREDENTIALS_FILE}.${TIME}.${TIMESTAMP}.bak"
touch ${CREDENTIALS_FILE}
echo "username=${CONFIG_SAMBA_CLIENT_USER}" >> ${CREDENTIALS_FILE}
echo "password=${CONFIG_SAMBA_CLIENT_PASSWORD}" >> ${CREDENTIALS_FILE}

echo "Creating the Samba mount directories..."
MOUNT_DIR="/mnt/${CONFIG_SAMBA_CLIENT_SHARE}"
sudo mkdir -p "${MOUNT_DIR}"

FSTAB="/etc/fstab"
if ! grep -q "^[[:space:]]*//${CONFIG_SAMBA_CLIENT_SHARE}[[:space:]]" "${FSTAB}"; then
    echo "Configuring the CIFS auto-mount..."
    sudo cp "${FSTAB}" "${FSTAB}.${TIME}.${TIMESTAMP}.bak"
    echo "//${CONFIG_SAMBA_CLIENT_SHARE}  ${MOUNT_DIR}  cifs  credentials=${CREDENTIALS_FILE},vers=1.0  0  0" | sudo tee -a "${FSTAB}"
fi

sudo mount -av
echo "* * * * * root ${SCRIPT_DIR}/watch-samba-mount.sh" | sudo tee "/etc/cron.d/samba-crontab"

echo "Creating Samba Media link..."
LINK="${CONFIG_MEDIA_DIR}/${CONFIG_SAMBA_CLIENT_LINK_NAME}"
ln -sfn "${MOUNT_DIR}${CONFIG_SAMBA_CLIENT_LINK_PATH}" "${LINK}"
