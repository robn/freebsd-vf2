#!/bin/sh

set -euo pipefail

BASE_IMAGE=FreeBSD-13.1-RELEASE-riscv-riscv64-GENERICSD.img
DTB_FILE=jh7110-visionfive-v2.dtb

# get base image
if [ ! -f $BASE_IMAGE ] ; then
  curl -LOC - https://download.freebsd.org/releases/riscv/riscv64/ISO-IMAGES/13.1/$BASE_IMAGE.xz
  xz -kd $BASE_IMAGE.xz
fi

# get dtb
if [ ! -f $DTB_FILE ] ; then
  curl -LOC - https://github.com/starfive-tech/VisionFive2/releases/download/VF2_v2.5.0/$DTB_FILE
fi


# attach the image, so we can extract the partition info
mdconfig -a -t vnode -f $BASE_IMAGE -u 0

# extract the esp and root partitions into their own files
dd if=$BASE_IMAGE of=efi.img bs=512 $(gpart show -l /dev/md0 | grep efi | awk '{ printf "skip=%d count=%d", $1, $2 }')
dd if=$BASE_IMAGE of=root.img bs=512 $(gpart show -l /dev/md0 | grep rootfs | awk '{ printf "skip=%d count=%d", $1, $2 }')

# unmount it
mdconfig -d -u 0


# mount the esp image to put the dtb in
mdconfig -a -t vnode -f efi.img -u 0
mount_msdosfs /dev/md0 /mnt
mkdir -p /mnt/dtb/starfive
cp -v $DTB_FILE /mnt/dtb/starfive
umount /dev/md0
mdconfig -d -u 0


# now mount the extracted image
mdconfig -a -t vnode -f root.img -u 0
mount /dev/md0 /mnt

# make updates
echo 'root_rw_mount="NO"' >> /mnt/etc/rc.conf
rm -f /mnt/etc/fstab
touch /mnt/etc/fstab

# and unmount
umount /mnt
mdconfig -d -u 0


# and zip it up
mkuzip -A zstd -d -o root.img.uzip root.img 


# source and target mountpoints
mkdir -p /mnt/s /mnt/t


# create empty boot image
truncate -s 1G boot.img
mdconfig -a -t vnode -f boot.img -u 1
newfs -L bootfs /dev/md1

# mount root and boot
mdconfig -a -t vnode -f root.img -u 0
mount -o ro /dev/md0 /mnt/s
mount /dev/md1 /mnt/t

# and copy over everything we need
cp -rv /mnt/s/boot/ /mnt/t/boot
cp -v root.img.uzip /mnt/t

# unmount it all
umount /mnt/s
umount /mnt/t
mdconfig -d -u 0
mdconfig -d -u 1


# build the final image
mkimg -s gpt -f raw -p efi/esp:=efi.img -p freebsd-ufs/boot:=boot.img -o vf2.img
