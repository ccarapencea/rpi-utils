#!/usr/bin/env bash

SCRIPT=$(readlink -f "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT}")
USER_NAME=$(whoami)
source "${SCRIPT_DIR}/config.cfg"

TIME=$(date --utc --iso-8601=date)
TIMESTAMP=$(date +%s)

sudo apt update
sudo apt upgrade
sudo apt install \
    xrdp \
    samba \
    samba-common-bin \
    smbclient \
    cifs-utils \
