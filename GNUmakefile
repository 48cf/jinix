QEMUFLAGS ?= -M q35,smm=off -m 2G -hdd image.hdd -smp 4

.PHONY: all
all:
	rm -f image.hdd
	$(MAKE) image.hdd

image.hdd: jinx
	$(MAKE) distro-base
	./build-support/makeimage.sh

jinx:
	curl -Lo jinx https://github.com/mintsuki/jinx/raw/ba9f68465334cd045e06f42dab861764a39234f3/jinx
	chmod +x jinx

.PHONY: distro-base
distro-base: jinx
	./jinx build base-files linux bash coreutils nano less

.PHONY: distro-full
distro-full: jinx
	./jinx build-all

.PHONY: run-kvm
run-kvm: image.hdd
	qemu-system-x86_64 -enable-kvm -cpu host $(QEMUFLAGS)

.PHONY: run
run: image.hdd
	qemu-system-x86_64 $(QEMUFLAGS)
