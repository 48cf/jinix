#! /bin/sh

qemu-system-x86_64 -M q35 -m 8G -smp 8 -enable-kvm -cpu host -hda jinix.img $QEMUFLAGS
