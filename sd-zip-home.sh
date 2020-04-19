#!/usr/bin/env bash

SCRIPT=$(readlink -f "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT}")
USER_NAME=$(whoami)
source "${SCRIPT_DIR}/config.cfg"

SOURCE=${1:-"/media/${USER_NAME}/rootfs/home"}

NAME="home"
DIR=${CONFIG_BACKUP_DIR}

mkdir -p "${DIR}"
if [[ ! -d "$DIR" ]]; then
    DIR=${SCRIPT_DIR}
fi
TIME=$(date --utc --iso-8601=date)
FILE=${2:-"${DIR}/${NAME}-${TIME}.zip"}

echo "Backing '${SOURCE}' up to '${FILE}'..."
zip -r -y -q "${FILE}" ${SOURCE}
