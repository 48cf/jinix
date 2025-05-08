#!/bin/sh

set -ex

: "${SUDO:=sudo}"

set -f
$SUDO rm -rf sysroot

# Retry the installation in case of transient errors like 503 TooManyRequests.
until ./jinx build-if-needed base $PKGS_TO_INSTALL; do
    echo "Package installation failed (likely due to rate limiting). Retrying in 30 seconds..."
    sleep 30
done

$SUDO ./jinx install "sysroot" base $PKGS_TO_INSTALL

set +f
if ! [ -d host-pkgs/limine ]; then
    ./jinx host-build limine
fi

rm -rf mount_dir

if [ -z "$IMAGE_SIZE" ]; then
    IMAGE_SIZE=8G
fi
rm -f jinix.img
fallocate -l "${IMAGE_SIZE}" jinix.img

$SUDO parted -s jinix.img mklabel gpt
$SUDO parted -s jinix.img mkpart ESP fat32 2048s 5%
$SUDO parted -s jinix.img mkpart jinix_root ext4 5% 100%
$SUDO parted -s jinix.img set 1 esp on

LOOPBACK_DEV=$($SUDO losetup -Pf --show jinix.img)
$SUDO mkfs.fat ${LOOPBACK_DEV}p1
$SUDO mkfs.ext4 -U 0e0e97f9-5c96-4826-972f-118e2316e55c ${LOOPBACK_DEV}p2
mkdir -p mount_dir
$SUDO mount ${LOOPBACK_DEV}p2 mount_dir

$SUDO cp -rp sysroot/* mount_dir/
$SUDO rm -rf mount_dir/boot
$SUDO mkdir -p mount_dir/boot
$SUDO mount ${LOOPBACK_DEV}p1 mount_dir/boot

$SUDO cp sysroot/usr/share/linux/vmlinuz mount_dir/boot/
$SUDO cp sysroot/usr/share/linux/initramfs mount_dir/boot/

$SUDO mkdir -p mount_dir/boot/limine
$SUDO cp host-pkgs/limine/usr/local/share/limine/limine-bios.sys mount_dir/boot/limine/
$SUDO mkdir -p mount_dir/boot/EFI/BOOT
$SUDO cp host-pkgs/limine/usr/local/share/limine/BOOTX64.EFI mount_dir/boot/EFI/BOOT/
$SUDO cp host-pkgs/limine/usr/local/share/limine/BOOTIA32.EFI mount_dir/boot/EFI/BOOT/

$SUDO sudo cp ./build-support/limine.conf mount_dir/boot/

sync
$SUDO umount -R mount_dir
$SUDO rm -rf mount_dir
$SUDO losetup -d ${LOOPBACK_DEV}

host-pkgs/limine/usr/local/bin/limine bios-install jinix.img

sync
