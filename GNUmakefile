SYSTEMD ?= no

QEMUFLAGS ?= -M q35,smm=off -m 2G -hdd image.hdd -smp 4 \
    -device qemu-xhci,id=xhci -device usb-tablet,bus=xhci.0 \
    -device ich9-intel-hda,id=sound0,bus=pcie.0,addr=0x1b \
    -device hda-duplex,id=sound0-codec0,bus=sound0.0,cad=0

.PHONY: all
all:
	$(MAKE) image

.PHONY: image
image: jinx
	$(MAKE) distro-base
	./build-support/makeimage.sh

jinx:
	curl -Lo jinx https://github.com/mintsuki/jinx/raw/28efd9f86ffbaeccb0f4552a4f1ad85f42fccad0/jinx
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
