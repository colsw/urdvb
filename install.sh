#!/bin/bash

#Vars - feel free to change these
rootfolder="/var/code" #files we be stored in /dvb-build/ subdirectory
mksquashfs_compiled_dl="https://dev.clsw.ie/dl?mksquashfs" #change this if you'd like

#You may not want to change anything below here
kernel_full="4.18.20"
#kernel_full=$(uname -r | grep -Eo '^[0-9\.]+')
kernel_major=$(echo $kernel_full | grep -Eo '^[0-9]+')
kernel_download="https://www.kernel.org/pub/linux/kernel"

libelec_getver="https://github.com/LibreELEC/dvb-firmware/releases/latest"
libelec_download="https://github.com/LibreELEC/dvb-firmware/archive"
#Check where the "/latest" URL redirects to, and grab version from the "effective" url.
libelec_version="$(curl -w "%{url_effective}" -ILs -S $libelec_getver -o /dev/null | grep -Eo "[0-9\.]+$")"

unraid_version_file="/etc/unraid-version"
unraid_version="6.6.6"
#unraid_version=$(cat ${unraid_version_file} | grep -Eo '[0-9\.]+')
unraid_download="https://s3.amazonaws.com/dnld.lime-technology.com/stable/unRAIDServer-${unraid_version}-x86_64.zip"

#Folder Creation
rootpath="${rootfolder}/dvb-build/"
rm -rf "${rootpath}/"
mkdir "${rootpath}/"
mkdir "${rootpath}/dl"
mkdir "${rootpath}/kernel"
mkdir "${rootpath}/libelec"

#Check free space before downloading anything
freespace=$(df -k ${rootpath} | awk '{print $4}' | tail -1)
if (( freespace < 1048576 )); then echo "Err, you need at least 1GB free disk space in the root folder."; exit; fi

#Get latest Kernel
wget "${kernel_download}/v${kernel_major}.x/linux-${kernel_full}.tar.gz" -O "${rootpath}/dl/kernel_latest.tar.gz" -q --show-progress
#Get latest Libre-ELEC
wget "${libelec_download}/${libelec_version}.tar.gz" -O "${rootpath}/dl/libelec_latest.tar.gz" -q --show-progress
#Get latest Unraid
wget ${unraid_download} -O "${rootpath}/dl/unraid_latest.tar.gz" -q --show-progress
#Get mksquashfs binary
wget ${mksquashfs_compiled_dl} -O "${rootpath}/mksquashfs" -q --show-progress

#Permissions
chmod 755 "${rootpath}/mksquashfs"

#Ensure all downloads completed and are non-zero filesize
if [ ! -s "${rootpath}/dl/kernel_latest.tar.gz" ]; then echo "Couldn't download Kernel ${kernel_full}!"; exit; fi
if [ ! -s "${rootpath}/dl/libelec_latest.tar.gz" ]; then echo "Couldn't download LibreELEC ${libelec_version}!"; exit; fi
if [ ! -s "${rootpath}/dl/unraid_latest.tar.gz" ]; then echo "Couldn't download Kernel ${kernel_full}!"; exit; fi
if [ ! -s "${rootpath}/mksquashfs" ]; then echo "Couldn't download mksquashfs from provided URL '${mksquashfs_compiled_dl}'!"; exit; fi