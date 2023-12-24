SYSTEMD ?= no

QEMUFLAGS ?= -M q35,smm=off -m 2G -hdd image.hdd -smp 4 \
    -device qemu-xhci,id=xhci -device usb-tablet,bus=xhci.0

.PHONY: all
all:
	rm -f image.hdd
	$(MAKE) SYSTEMD=no image.hdd

all-systemd:
	rm -f image.hdd
	$(MAKE) SYSTEMD=yes image.hdd

image.hdd: jinx
	$(MAKE) distro-base
	./build-support/makeimage.sh

jinx:
	curl -Lo jinx https://github.com/mintsuki/jinx/raw/8e383420e689cae6b642c58943109f384ac71566/jinx
	chmod +x jinx

.PHONY: distro-base
distro-base: jinx
ifeq ($(SYSTEMD),yes)
	./jinx build base systemd linux initramfs
else
	./jinx build base openrc linux initramfs
endif

# XXX BROKEN IF SYSTEMD IS MERGED
.PHONY: distro-full
distro-full: jinx
	./jinx build-all

.PHONY: run-kvm
run-kvm: image.hdd
	qemu-system-x86_64 -enable-kvm -cpu host $(QEMUFLAGS)

.PHONY: run
run: image.hdd
	qemu-system-x86_64 $(QEMUFLAGS)
