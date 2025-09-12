#!/bin/sh

set -e

script_dir="$(dirname "$0")"
test -z "${script_dir}" && script_dir=.

source_dir="$(cd "${script_dir}"/.. && pwd -P)"
build_dir="$(pwd -P)"

# Let the user pass their own $SUDO (or doas).
: "${SUDO:=sudo}"

# Set ARCH based on the build directory.
case "$(basename "${build_dir}")" in
    build-x86_64) ARCH=x86_64 ;;
    build-riscv64) ARCH=riscv64 ;;
    *)
        echo "error: The build directory must be called 'build-<architecture>'." 1>&2
        exit 1
        ;;
esac

# Create build directory if needed.
mkdir -p "${build_dir}"

# Enter build directory.
cd "${build_dir}"

# If already initialized, get ARCH from .jinx-parameters file.
if [ -f .jinx-parameters ]; then
    if ! [ "${ARCH}" = "$(. ./.jinx-parameters && echo "${JINX_ARCH}")" ]; then
        echo "error: Jinx architecture and build dir derived architecture mismatch. Delete build dir." 1>&2
        exit 1
    fi
fi

# Build the sysroot with jinx, and make sure the packages the particular
# target needs.
set -f
$SUDO rm -rf sysroot

if ! [ -f .jinx-parameters ]; then
    "${source_dir}"/jinx init "${source_dir}" ARCH="${ARCH}"
fi

"${source_dir}"/jinx build-if-needed base $PKGS_TO_INSTALL

$SUDO --preserve-env "${source_dir}"/jinx install "sysroot" base $PKGS_TO_INSTALL

set +f

if ! [ -d host-pkgs/limine ]; then
    "${source_dir}"/jinx host-build limine
fi

# Prepare the iso and boot directories.
rm -rf mount_dir

# Allocate the image. If a size is passed, we just use that size, else, we try
# to guesstimate calculate a rough size.
# Try to not use fractional sizes (3.X for example) since certain Linux distros
# like debian struggle to use it.
if [ -z "$IMAGE_SIZE" ]; then
    IMAGE_SIZE=8G
fi
rm -f jinix.img
fallocate -l "${IMAGE_SIZE}" jinix.img

# Format and mount the image.
PATH=$PATH:/usr/sbin:/sbin parted -s jinix.img mklabel gpt
PATH=$PATH:/usr/sbin:/sbin parted -s jinix.img mkpart ESP fat32 2048s 5%
PATH=$PATH:/usr/sbin:/sbin parted -s jinix.img mkpart jinix_root ext4 5% 100%
PATH=$PATH:/usr/sbin:/sbin parted -s jinix.img set 1 esp on
LOOPBACK_DEV=$($SUDO losetup -Pf --show jinix.img)
$SUDO mkfs.fat ${LOOPBACK_DEV}p1
$SUDO mkfs.ext4 -U 0e0e97f9-5c96-4826-972f-118e2316e55c ${LOOPBACK_DEV}p2
mkdir -p mount_dir
$SUDO mount ${LOOPBACK_DEV}p2 mount_dir

# Copy the system root to the initramfs filesystem.
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

$SUDO sudo cp "${source_dir}/build-support/limine.conf" mount_dir/boot/

sync
$SUDO umount mount_dir/boot
$SUDO umount mount_dir
$SUDO rm -rf mount_dir
$SUDO losetup -d ${LOOPBACK_DEV}

# Arch-specific image triggers.
if [ "$ARCH" = x86_64 ]; then
    host-pkgs/limine/usr/local/bin/limine bios-install jinix.img
fi

sync
