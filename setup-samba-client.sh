#!/usr/bin/env bash

SCRIPT=$(readlink -f "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT}")
USER_NAME=$(whoami)
source "${SCRIPT_DIR}/config.cfg"

TIME=$(date --utc --iso-8601=date)
TIMESTAMP=$(date +%s)

CREDENTIALS_FILE=$(realink -f ~/.smbcredentials)
mv "${CREDENTIALS_FILE}" "${SSH_FILE}.${TIME}.${TIMESTAMP}.bak"
touch ${CREDENTIALS_FILE}
echo "username=${CONFIG_SAMBA_CLIENT_USER}" >> ${CREDENTIALS_FILE}
echo "password=${CONFIG_SAMBA_CLIENT_PASSWORD}" >> ${CREDENTIALS_FILE}

MOUNT_DIR="/mnt/${CONFIG_SAMBA_CLIENT_SHARE}"
sudo mkdir -p "${MOUNT_DIR}"

if ! grep -q "^[[:space:]]*//${CONFIG_SAMBA_CLIENT_SHARE}[[:space:]]" /etc/fstab; then
    echo "//${CONFIG_SAMBA_CLIENT_SHARE}  ${MOUNT_DIR}  cifs  credentials=${CREDENTIALS_FILE},vers=1.0  0  0" >> /etc/fstab
fi
sudo mount -av

ln -s "${MOUNT_DIR}${CONFIG_SAMBA_CLIENT_LINK_PATH}" ~/${CONFIG_SAMBA_CLIENT_LINK_NAME}
cd ~/${CONFIG_SAMBA_CLIENT_LINK_NAME}
ls -al
