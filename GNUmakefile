QEMUFLAGS ?= -M q35,smm=off -m 2G -hdd image.hdd -smp 4 \
    -device qemu-xhci,id=xhci -device usb-tablet,bus=xhci.0

.PHONY: all
all:
	rm -f image.hdd
	$(MAKE) image.hdd

image.hdd: jinx
	$(MAKE) distro-base
	./build-support/makeimage.sh

jinx:
	curl -Lo jinx https://github.com/mintsuki/jinx/raw/f55d2f00e9e4e5a7a42bb283b6128f26fb2a9a65/jinx
	chmod +x jinx

.PHONY: distro-base
distro-base: jinx
	./jinx build base openrc linux

.PHONY: distro-full
distro-full: jinx
	./jinx build-all

.PHONY: run-kvm
run-kvm: image.hdd
	qemu-system-x86_64 -enable-kvm -cpu host $(QEMUFLAGS)

.PHONY: run
run: image.hdd
	qemu-system-x86_64 $(QEMUFLAGS)
