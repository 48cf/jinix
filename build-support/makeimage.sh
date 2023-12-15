#!/bin/sh

set -ex

./jinx host-build limine

rm -f image.hdd
dd if=/dev/zero bs=1G count=0 seek=100 of=image.hdd
parted -s image.hdd mklabel gpt
parted -s image.hdd mkpart ESP fat32 2048s 1%
parted -s image.hdd set 1 esp on
parted -s image.hdd mkpart root ext4 1% 100%

USED_LOOPBACK=$(sudo losetup -Pf --show image.hdd)

sudo mkfs.fat -F 32 ${USED_LOOPBACK}p1
sudo mkfs.ext4 ${USED_LOOPBACK}p2

rm -rf sysroot
mkdir -p sysroot
sudo mount ${USED_LOOPBACK}p2 sysroot
sudo mkdir -p sysroot/boot
sudo mount ${USED_LOOPBACK}p1 sysroot/boot

sudo ./jinx sysroot

sudo mkdir -p sysroot/boot/EFI/BOOT
sudo cp -r host-pkgs/limine/usr/local/share/limine/limine-bios.sys sysroot/boot/
sudo cp -r host-pkgs/limine/usr/local/share/limine/BOOTX64.EFI sysroot/boot/EFI/BOOT/

cat <<EOF | sudo tee sysroot/boot/limine.cfg
:Linux
PROTOCOL=linux
KERNEL_PATH=boot:///vmlinuz
CMDLINE=root=/dev/sda2 rw init=/bin/openrc-init
EOF

sudo cp pkgs/linux/usr/share/linux/vmlinuz sysroot/boot/

ls -la sysroot/

sudo sync
sudo umount sysroot/boot
sudo umount sysroot
sudo losetup -d ${USED_LOOPBACK}

host-pkgs/limine/usr/local/bin/limine bios-install image.hdd
