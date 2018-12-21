#!/bin/bash

#Vars - feel free to change these
base_folder="/tmp/" #all files we be stored in /dvb-build/ subdirectory, use absolute path

# -- You may not want to change anything below here -- #

mksquashfs_download="https://github.com/colsw/urdvb/raw/master/mksquashfs"
unzip_download="https://github.com/colsw/urdvb/raw/master/unzip"

kernel_full="4.18.20" #only for testing
#kernel_full=$(uname -r | grep -Eo '^[0-9\.]+')
kernel_major=$(echo $kernel_full | grep -Eo '^[0-9]+')
kernel_download_root="https://www.kernel.org/pub/linux/kernel"
kernel_download="${kernel_download_root}/v${kernel_major}.x/linux-${kernel_full}.tar.gz"

libelec_getver="https://github.com/LibreELEC/dvb-firmware/releases/latest"
libelec_download_root="https://github.com/LibreELEC/dvb-firmware/archive"
#Check where the "/latest" URL redirects to, and grab version from the "effective" url.
libelec_version="$(curl -w "%{url_effective}" -ILs -S $libelec_getver -o /dev/null | grep -Eo "[0-9\.]+$")"
libelec_download="${libelec_download_root}/${libelec_version}.tar.gz"

unraid_version_file="/etc/unraid-version"
unraid_version="6.6.6" #only for testing
#unraid_version=$(cat ${unraid_version_file} | grep -Eo '[0-9\.]+')
unraid_download="https://s3.amazonaws.com/dnld.lime-technology.com/stable/unRAIDServer-${unraid_version}-x86_64.zip"

#Folder Creation
rootpath="${base_folder}/dvb-build/"
rm -rf "${rootpath}/"
mkdir "${rootpath}/"
mkdir "${rootpath}/dl"
mkdir "${rootpath}/kernel"
mkdir "${rootpath}/libelec"
mkdir "${rootpath}/unraid"
mkdir "${rootpath}/compile"

#Check free space before downloading anything
freespace=$(df -k ${rootpath} | awk '{print $4}' | tail -1)
if (( freespace < 1048576 )); then echo "Err, you need at least 1GB free disk space in the root folder."; exit; fi

echo "Downloading required files..."

#Get latest Kernel
wget ${kernel_download} -O "${rootpath}/dl/kernel_latest.tar.gz" -q --show-progress
#Get latest Libre-ELEC
wget ${libelec_download} -O "${rootpath}/dl/libelec_latest.tar.gz" -q --show-progress
#Get latest Unraid
wget ${unraid_download} -O "${rootpath}/dl/unraid_latest.zip" -q --show-progress
#Get mksquashfs binary
wget ${mksquashfs_download} -O "${rootpath}/mksquashfs" -q --show-progress
#Get unzip binary
wget ${unzip_download} -O "${rootpath}/unzip" -q --show-progress

#Ensure all downloads completed and are non-zero filesize
if [ ! -s "${rootpath}/dl/kernel_latest.tar.gz" ]; then echo "Couldn't download Kernel ${kernel_full}!"; exit; fi
if [ ! -s "${rootpath}/dl/libelec_latest.tar.gz" ]; then echo "Couldn't download LibreELEC ${libelec_version}!"; exit; fi
if [ ! -s "${rootpath}/dl/unraid_latest.zip" ]; then echo "Couldn't download Unraid ${unraid_version}!"; exit; fi
if [ ! -s "${rootpath}/mksquashfs" ]; then echo "Couldn't download mksquashfs from provided URL '${mksquashfs_download}'!"; exit; fi
if [ ! -s "${rootpath}/unzip" ]; then echo "Couldn't download unzip from provided URL '${unzip_download}'!"; exit; fi

echo "...Downloads complete!"

#Set Permissions
chmod 744 "${rootpath}/dl/kernel_latest.tar.gz"
chmod 744 "${rootpath}/dl/libelec_latest.tar.gz"
chmod 744 "${rootpath}/dl/unraid_latest.zip"
chmod 755 "${rootpath}/mksquashfs"
chmod 755 "${rootpath}/unzip"

#Extract Files
echo "Extracting files..."
tar -C "${rootpath}/kernel" --strip-components=1 -xf "${rootpath}/dl/kernel_latest.tar.gz"
tar -C "${rootpath}/libelec" --strip-components=1 -xf "${rootpath}/dl/libelec_latest.tar.gz"
${rootpath}/unzip -qo "${rootpath}/dl/unraid_latest.zip" -d "${rootpath}/unraid"
echo "...Extraction complete!"

#Other Installs


#Begin Compile
#bzroot and bzroot-gui are unchanged for LibreELEC, no need to copy them?
#cp "${rootpath}/unraid/bzroot" "${rootpath}/compile"
#cp "${rootpath}/unraid/bzroot-gui" "${rootpath}/compile"

cp "${rootpath}/libelec/firmware/*" "/lib/firmware/"
${rootpath}/mksquashfs "/lib/firmware" "${rootpath}/compile/bzfirmware" -noappend
${rootpath}/mksquashfs "/lib/modules/$(uname -r)/" "${rootpath}/compile/bzmodules" -keep-as-directory -noappend

#BZIMAGE