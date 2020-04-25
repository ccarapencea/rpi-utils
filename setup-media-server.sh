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
    xrdp \
    samba \
    samba-common-bin \
    smbclient \
    cifs-utils \
    minidlna \
    transmission-daemon \


echo "Setting up media directories..."
mkdir -p "${CONFIG_MEDIA_DIR}"
if [[ -v CONFIG_MEDIA_EXT_MOUNT ]]; then
    ln -sfn "${CONFIG_MEDIA_EXT_MOUNT}" "${CONFIG_MEDIA_DIR}/data-ext"
fi
if [[ -v CONFIG_MEDIA_NTFS_MOUNT ]]; then
    ln -sfn "${CONFIG_MEDIA_NTFS_MOUNT}" "${CONFIG_MEDIA_DIR}/data-ntfs"
fi
if [[ -v CONFIG_SAMBA_CLIENT_SHARE ]]; then
    "${SCRIPT_DIR}/setup-samba-client.sh"
fi


SMB_CONF="/etc/samba/smb.conf"
if ! grep -q "^[[:space:]]*\[${CONFIG_SAMBA_SERVER_SHARE}\][[:space:]]*$" "${SMB_CONF}"; then
    echo "Configuring up the Samba share..."
    sudo cp "${SMB_CONF}" "${SMB_CONF}.${TIME}.${TIMESTAMP}.bak"

    echo | sudo tee -a "${SMB_CONF}"
    echo "[${CONFIG_SAMBA_SERVER_SHARE}]" | sudo tee -a "${SMB_CONF}"
    echo "path = /${CONFIG_MEDIA_DIR}" | sudo tee -a "${SMB_CONF}"
    echo "writeable = yes" | sudo tee -a "${SMB_CONF}"
    echo "create mask = 0777" | sudo tee -a "${SMB_CONF}"
    echo "directory mask = 0777" | sudo tee -a "${SMB_CONF}"
    echo "public = no" | sudo tee -a "${SMB_CONF}"
fi


echo "Configuring the Samba user..."
printf "${CONFIG_SAMBA_SERVER_PASSWORD}\n${CONFIG_SAMBA_SERVER_PASSWORD}\n" | sudo smbpasswd -s -a "${CONFIG_SAMBA_SERVER_USER}"
sudo systemctl restart smbd


echo "Configuring MiniDLNA..."
MINIDLNA_CONF="/etc/minidlna.conf"
sudo cp "${MINIDLNA_CONF}" "${MINIDLNA_CONF}.${TIME}.${TIMESTAMP}.bak"

MINIDLNA_PATTERN=".*wide_links=.*"
MINIDLNA_REPLACEMENT="wide_links=yes"
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


echo "Configuring Transmission..."
sudo systemctl stop transmission-daemon

TRANSMISSION_CUSTOM_SETTINGS="${SCRIPT_DIR}/files/transmission/settings.json"
if [[ -f "${TRANSMISSION_CUSTOM_SETTINGS}" ]]; then
    TRANSMISSION_SETTINGS="/etc/transmission-daemon/settings.json"
    sudo mv "${TRANSMISSION_SETTINGS}" "${TRANSMISSION_SETTINGS}.${TIME}.${TIMESTAMP}.bak"
    sudo cp "${TRANSMISSION_CUSTOM_SETTINGS}" "${TRANSMISSION_SETTINGS}"
fi

sudo systemctl restart transmission-daemon
