#!/bin/bash
###############################################################
# Created by whiskerz007                                      #
# URL: https://github.com/whiskerz007/wireguard_rpi_installer #
###############################################################
function install_deb() {
    apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y raspberrypi-kernel-headers dirmngr \
    && echo "deb http://deb.debian.org/debian/ unstable main" | tee --append /etc/apt/sources.list.d/unstable.list 1>/dev/null \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8B48AD6246925553 \
    && printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' | tee --append /etc/apt/preferences.d/limit-unstable 1>/dev/null \
    && apt-get update \
    && apt-get install -y wireguard \
    && finish \
    || failed
}

function install_make() {
    declare -r path=(pwd) \
               tmp=(mktemp -d) \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y raspberrypi-kernel-headers libmnl-dev libelf-dev build-essential git \
    && git clone https://git.zx2c4.com/WireGuard $tmp \
    && cd $tmp \
    && make \
    && make install \
    && cd $path \
    && rm -rf $tmp \
    && finish \
    || failed
}

function finish() {
    sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf \
    && sysctl -p \
    && echo -e "\n\n" \
        "#######################################\n" \
        "# WireGuard installation is complete! #\n" \
        "#######################################\n" \
    && exit 0 \
    || failed
}

function failed() {
    echo "ERROR: Failed to complete installation." \
    && exit 1
}

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: This script requires root access. Try running with 'sudo'." \
    && exit 1
fi

# Board model infomation pulled from: https://elinux.org/RPi_HardwareHistory
declare -r -a SUPPORTED_BOARDS_DEB=(
    "a22042" # 2 Model B (with BCM2837) v1.2 1GB
    "a02082" # 3 Model B v1.2 1GB
    "a020a0" # Compute Module 3 (and CM3 Lite) v1.0 1GB
    "a22082" # 3 Model B v1.2 1GB (Mfg by Embest)
    "a32082" # 3 Model B v1.2 1GB (Mfg by Sony Japan)
    "a020d3" # 3 Model B+ v1.3 1GB
    "9020e0" # 3 Model A+ v1.0 512MB
)
declare -r -a SUPPORTED_BOARDS_MAKE=(
    "900021" # A+ v1.1 512MB
    "900032" # B+ v1.2 512MB
    "900092" # Zero v1.2 512MB
    "900093" # Zero v1.3 512MB (Mfg by Sony)
    "920093" # Zero v1.3 512MB (Mfg by Embest)
    "9000c1" # Zero W v1.1 512MB
    "a01040" # 2 Model B v1.0 1GB
    "a01041" # 2 Model B v1.1 1GB (Mfg by Sony)
    "a21041" # 2 Model B v1.1 1GB (Mfg by Embest)
)
declare -r BOARD=`awk '/^Revision/ {sub("^1000", "", $3); print $3}' /proc/cpuinfo`

for i in "${SUPPORTED_BOARDS_DEB[@]}"; do
    if [[ ${i} == ${BOARD} ]]; then
        install_deb
    fi
done
for i in "${SUPPORTED_BOARDS_MAKE[@]}"; do
    if [[ ${i} == ${BOARD} ]]; then
        install_make
    fi
done
echo -e "ERROR: Unsupported device detected!\n" \
        "Refer to the following website for installation instructions.\n" \
        "https://www.wireguard.com/install/\n" \
&& exit 1
