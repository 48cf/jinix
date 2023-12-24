SYSTEMD ?= no

QEMUFLAGS ?= -M q35,smm=off -m 2G -hdd image.hdd -smp 4 \
    -device qemu-xhci,id=xhci -device usb-tablet,bus=xhci.0

.PHONY: all
all:
	$(MAKE) image

.PHONY: image
image: jinx
	$(MAKE) distro-base
	./build-support/makeimage.sh

jinx:
	curl -Lo jinx https://github.com/mintsuki/jinx/raw/2dc45a09339ed4fb77a66fa2b7ce246a4feed3f8/jinx
	chmod +x jinx

.PHONY: distro-base
distro-base: jinx
ifeq ($(SYSTEMD),yes)
	SYSTEMD=yes ./jinx build base systemd linux initramfs
else
	SYSTEMD=no ./jinx build base openrc linux initramfs
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
