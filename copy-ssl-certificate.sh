#!/usr/bin/env bash

SCRIPT=$(readlink -f "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT}")
USER_NAME=pi
source "${SCRIPT_DIR}/config.cfg"

DEST_USER="${CONFIG_TORRENT_USER}"

DEST_DIR="/home/${DEST_USER}/${CONFIG_SSL_DEST_DIR}"
DEST_CHAIN="${DEST_DIR}/chain.pem"
DEST_KEY="${DEST_DIR}/key.pem"

mkdir -p "${DEST_DIR}"
chown "${DEST_USER}:${DEST_USER}" "${DEST_DIR}"

cp "${CONFIG_SSL_SOURCE_CHAIN}" "${DEST_CHAIN}"
cp "${CONFIG_SSL_SOURCE_KEY}" "${DEST_KEY}"

chown "root:${DEST_USER}" "${DEST_CHAIN}"
chown "root:${DEST_USER}" "${DEST_KEY}"

chmod 640 "${DEST_CHAIN}"
chmod 640 "${DEST_KEY}"
