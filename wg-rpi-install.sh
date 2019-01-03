#!/bin/bash

function install() {
    apt-get update \
    && apt-get upgrade \
    && apt-get install raspberrypi-kernel-headers dirmngr \
    && echo "deb http://deb.debian.org/debian/ unstable main" | tee --append /etc/apt/sources.list.d/unstable.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8B48AD6246925553 \
    && printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' | tee --append /etc/apt/preferences.d/limit-unstable \
    && apt-get update \
    && apt-get install wireguard \
    && modprobe wireguard \
    && exit 0 \
    || (echo "ERROR: Failed to complete installtion." && exit 1)
}

# Check for root permissions
if [[ $EUID -ne 0 ]]; then
#  __SELF="$( cd "$(dirname "$0")" ; pwd -P )/$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
#  $__SELF $@
#  exit $?
    echo "ERROR: This script requires root access. Try running with 'sudo'." \
    && exit 1
fi

declare -r -a SUPPORTED_BOARDS=( \
    "a22042" \ # 2 Model B (with BCM2837) v1.2 1GB
    "a02082" \ # 3 Model B v1.2	1GB
    "a020a0" \ # Compute Module 3 (and CM3 Lite) v1.0 1GB
    "a22082" \ # 3 Model B v1.2 1GB
    "a32082" \ # 3 Model B v1.2 1GB
    "a020d3" \ # 3 Model B+ v1.3 1GB
    "9020e0" \ # 3 Model A+ v1.0 512MB
    )
declare -r BOARD=`awk '/^Revision/ {sub("^1000", "", $3); print $3}' /proc/cpuinfo`

for i in ${!SUPPORTED_BOARDS}; do
    if [[ ${i} == ${BOARD} ]]; then
        install
    fi
done
echo -e "ERROR: Unsupported device detected!\n" \
    "Refer to the following website for installation instructions.\n" \
    "https://www.wireguard.com/install/\n" \
&& exit 1
