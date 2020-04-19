#!/usr/bin/env bash

SCRIPT=$(readlink -f "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT}")
USER_NAME=$(whoami)
source "${SCRIPT_DIR}/config.cfg"

DEVICE=${1:-"/dev/mmcblk0"}
BLOCK_SIZE=${3:-"4M"}

NAME="image"
DIR=${CONFIG_BACKUP_DIR}

mkdir -p "${DIR}"
if [[ ! -d "$DIR" ]]; then
    DIR=${SCRIPT_DIR}
fi
TIME=$(date --utc --iso-8601=date)
FILE=${2:-"${DIR}/${NAME}-${TIME}.zip"}

echo "Backing '${DEVICE}' up to '${FILE}'..."
sudo dd bs=${BLOCK_SIZE} if=${DEVICE} status=progress | gzip > "${FILE}"
