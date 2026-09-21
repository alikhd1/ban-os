# Ban OS build entry points (plan part 1, step 0.5).
# All targets run on the Debian 13 build VM (see docs/architecture/build.md).

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

VERSION := $(shell tr -d '[:space:]' < VERSION)
PROFILE ?= development

OUT  := out
ISO  ?= $(OUT)/ban-os-$(VERSION)-$(PROFILE)-amd64.iso
DISK ?= $(OUT)/disk.qcow2

# Rust crates that ship as .deb. center, launcher, hardware and updater join
# this target in their own stages.
DEB_CRATES := ban-agent ban-event

# The plan uses /usr/share/OVMF/OVMF_CODE.fd; fall back to the other names the
# Debian ovmf package has used.
OVMF_CODE ?= $(firstword $(wildcard /usr/share/OVMF/OVMF_CODE.fd /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/ovmf/OVMF.fd))
KVM       := $(if $(wildcard /dev/kvm),-enable-kvm,)
# Extra QEMU arguments for run-vm, e.g. QEMU_EXTRA="-display vnc=:1" over SSH.
QEMU_EXTRA ?=

SUDO := $(if $(filter 0,$(shell id -u)),,sudo)

.PHONY: help debs build run-vm test-boot clean

help:
	@echo "make debs                      build all Ban .deb packages into $(OUT)/debs/"
	@echo "make build PROFILE=<profile>   build the ISO (development|staging|production)"
	@echo "make run-vm                    boot the ISO in QEMU + OVMF (32GB disk, 1024x768)"
	@echo "make test-boot                 headless boot, wait for BAN-BOOT-OK on serial"
	@echo "make clean                     remove the live-build chroot and cache"

debs:
	mkdir -p $(OUT)/debs
	for crate in $(DEB_CRATES); do \
		cargo deb --package "$$crate" --output $(OUT)/debs/; \
	done

build:
	image/scripts/build-image.sh $(PROFILE)

$(DISK):
	mkdir -p $(OUT)
	qemu-img create -f qcow2 $@ 32G

# "-vga none -device virtio-vga,xres=..,yres=.." is "-vga virtio" with the
# 1024x768 POS screen size.
run-vm: $(DISK)
	@test -f "$(ISO)" || { echo "$(ISO) not found; run: make build PROFILE=$(PROFILE)" >&2; exit 1; }
	@test -n "$(OVMF_CODE)" || { echo "OVMF firmware not found; install the ovmf package" >&2; exit 1; }
	qemu-system-x86_64 $(KVM) -m 4096 -smp 2 \
		-bios $(OVMF_CODE) \
		-cdrom $(ISO) \
		-drive file=$(DISK),if=virtio \
		-serial stdio \
		-vga none -device virtio-vga,xres=1024,yres=768 \
		$(QEMU_EXTRA)

test-boot:
	@test -f "$(ISO)" || { echo "$(ISO) not found; run: make build PROFILE=$(PROFILE)" >&2; exit 1; }
	@test -n "$(OVMF_CODE)" || { echo "OVMF firmware not found; install the ovmf package" >&2; exit 1; }
	tests/boot/test-boot.sh $(ISO) $(OVMF_CODE)

clean:
	cd image/live-build && $(SUDO) lb clean --purge
	rm -rf image/live-build/config/package-lists
