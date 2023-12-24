#!/bin/sh

set -ex

./jinx host-build limine

if ! [ -f image.hdd ]; then
    first_setup=yes

    dd if=/dev/zero bs=1G count=0 seek=100 of=image.hdd
    sudo parted -s image.hdd mklabel gpt
    sudo parted -s image.hdd mkpart ESP fat32 2048s 1%
    sudo parted -s image.hdd set 1 esp on
    sudo parted -s image.hdd mkpart root ext4 1% 100%
fi

USED_LOOPBACK=$(sudo losetup -Pf --show image.hdd)

if [ "${first_setup}" = "yes" ]; then
    sudo mkfs.fat -F 32 ${USED_LOOPBACK}p1
    sudo mkfs.ext4 ${USED_LOOPBACK}p2
fi

mkdir -p sysroot
sudo mount ${USED_LOOPBACK}p2 sysroot
sudo mkdir -p sysroot/boot
sudo mount ${USED_LOOPBACK}p1 sysroot/boot

cleanup() {
    sudo sync
    sudo umount sysroot/boot
    sudo umount sysroot
    sudo losetup -d ${USED_LOOPBACK}
}

trap 'cleanup; trap - EXIT; exit' EXIT INT TERM QUIT HUP
sudo ./jinx sysroot

sudo mkdir -p sysroot/boot/EFI/BOOT
sudo cp -r host-pkgs/limine/usr/local/share/limine/limine-bios.sys sysroot/boot/
sudo cp -r host-pkgs/limine/usr/local/share/limine/BOOTX64.EFI sysroot/boot/EFI/BOOT/

cat <<EOF | sudo tee sysroot/boot/limine.cfg
:Linux
PROTOCOL=linux
KERNEL_PATH=boot:///vmlinuz
CMDLINE=root=/dev/sda2 rw init=/bin/init
MODULE_PATH=boot:///initramfs.img
EOF

sudo cp pkgs/linux/usr/share/linux/vmlinuz sysroot/boot/
sudo cp pkgs/initramfs/usr/share/initramfs/initramfs.img sysroot/boot/

ls -la sysroot/
host-pkgs/limine/usr/local/bin/limine bios-install image.hdd
