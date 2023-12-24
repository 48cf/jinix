QEMUFLAGS ?= -M q35,smm=off -m 2G -hdd image.hdd -smp 4 \
    -device qemu-xhci,id=xhci -device usb-tablet,bus=xhci.0

.PHONY: all
all:
	rm -f image.hdd
	$(MAKE) image.hdd

all-systemd:
	rm -f image.hdd
	$(MAKE) image.hdd-systemd

image.hdd: jinx
	$(MAKE) distro-base
	./build-support/makeimage.sh

.PHONY: image.hdd-systemd
image.hdd-systemd: jinx
	$(MAKE) distro-base-systemd
	./build-support/makeimage.sh

jinx:
	curl -Lo jinx https://github.com/mintsuki/jinx/raw/05a8ab665f36e24ff808c5c3c245479fa5951d50/jinx
	chmod +x jinx

.PHONY: distro-base
distro-base: jinx
	./jinx build base openrc linux initramfs

.PHONY: distro-base-systemd
distro-base: jinx
	./jinx build base systemd linux initramfs

#BROKEN IF SYSTEMD IS MERGED
.PHONY: distro-full
distro-full: jinx
	./jinx build-all

.PHONY: run-kvm
run-kvm: image.hdd-systemd
	qemu-system-x86_64 -enable-kvm -cpu host $(QEMUFLAGS)

.PHONY: run
run: image.hdd
	qemu-system-x86_64 $(QEMUFLAGS)
