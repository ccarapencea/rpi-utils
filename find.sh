#!/usr/bin/env bash

SCRIPT=$(readlink -f "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT}")
USER_NAME=$(whoami)
source "${SCRIPT_DIR}/config.cfg"

sudo find "${2:-/}" -type d \( \
    -path "/home/${USER_NAME}/Media" -o \
    -path /mnt -o \
    -path /dev -o \
    -path /proc -o \
    -path /sys \) \
    -prune -o -wholename "${1}" -print
