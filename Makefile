# Ban OS build entry points (plan part 1, step 0.5).
# All targets run on the Debian 13 build VM (see docs/architecture/build.md).

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

VERSION := $(shell tr -d '[:space:]' < VERSION)
PROFILE ?= development
# pos = graphical kiosk with Adad; server = headless (PostgreSQL + Ban services).
VARIANT ?= pos

OUT  := out
ISO  ?= $(OUT)/ban-os-$(VERSION)-$(PROFILE)-$(VARIANT)-amd64.iso
# One virtual disk per variant, so an installed pos system and an installed
# server system never share a disk.
DISK ?= $(OUT)/disk-$(VARIANT).qcow2

# Rust crates that ship as .deb. center, launcher, hardware and updater join
# this target in their own stages.
DEB_CRATES := ban-agent ban-event

# UEFI firmware. Debian 13 ships only the split 4 MB build: read-only code plus
# a template for the UEFI variable store. QEMU needs both as pflash drives
# (-bios cannot load it). Older Debian releases name them without _4M.
OVMF_CODE ?= $(firstword $(wildcard /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd))
OVMF_VARS_TEMPLATE ?= $(subst OVMF_CODE,OVMF_VARS,$(OVMF_CODE))
# Writable copy of the variable store, one per variant like the disk.
OVMF_VARS ?= $(OUT)/ovmf-vars-$(VARIANT).fd
KVM       := $(if $(wildcard /dev/kvm),-enable-kvm,)
# Extra QEMU arguments for run-vm, e.g. QEMU_EXTRA="-display vnc=:1" over SSH.
QEMU_EXTRA ?=
# Guest RAM in MiB (plan: 4096); lower it on a small build VM, e.g. VM_MEM=2048.
VM_MEM ?= 4096
# Seconds test-boot waits for BAN-BOOT-OK; raise it without KVM, e.g. 900.
BOOT_TIMEOUT ?= 120
export VM_MEM BOOT_TIMEOUT

SUDO := $(if $(filter 0,$(shell id -u)),,sudo)

.PHONY: help debs build run-vm test-boot clean

help:
	@echo "make debs                      build all Ban .deb packages into $(OUT)/debs/"
	@echo "make build PROFILE=<profile> VARIANT=<variant>"
	@echo "                               build the ISO; profile: development|staging|production,"
	@echo "                               variant: pos (default) | server"
	@echo "make run-vm                    boot the ISO in QEMU + OVMF (32GB disk, 1024x768)"
	@echo "make test-boot                 headless boot, wait for BAN-BOOT-OK on serial"
	@echo "make clean                     remove the live-build chroot and cache"

debs:
	mkdir -p $(OUT)/debs
	for crate in $(DEB_CRATES); do \
		cargo deb --package "$$crate" --output $(OUT)/debs/; \
	done

build:
	image/scripts/build-image.sh $(PROFILE) $(VARIANT)

$(DISK):
	mkdir -p $(OUT)
	qemu-img create -f qcow2 $@ 32G

$(OVMF_VARS):
	@test -f "$(OVMF_VARS_TEMPLATE)" || { echo "OVMF firmware not found; install the ovmf package" >&2; exit 1; }
	mkdir -p $(OUT)
	cp $(OVMF_VARS_TEMPLATE) $@

# "-vga none -device virtio-vga,xres=..,yres=.." is "-vga virtio" with the
# 1024x768 POS screen size.
run-vm: $(DISK) $(OVMF_VARS)
	@test -f "$(ISO)" || { echo "$(ISO) not found; run: make build PROFILE=$(PROFILE) VARIANT=$(VARIANT)" >&2; exit 1; }
	@test -n "$(OVMF_CODE)" || { echo "OVMF firmware not found; install the ovmf package" >&2; exit 1; }
	qemu-system-x86_64 $(KVM) -m $(VM_MEM) -smp 2 \
		-drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
		-drive if=pflash,format=raw,file=$(OVMF_VARS) \
		-cdrom $(ISO) \
		-drive file=$(DISK),if=virtio \
		-serial stdio \
		-vga none -device virtio-vga,xres=1024,yres=768 \
		$(QEMU_EXTRA)

test-boot:
	@test -f "$(ISO)" || { echo "$(ISO) not found; run: make build PROFILE=$(PROFILE) VARIANT=$(VARIANT)" >&2; exit 1; }
	@test -n "$(OVMF_CODE)" || { echo "OVMF firmware not found; install the ovmf package" >&2; exit 1; }
	BOOT_LOG=$(OUT)/boot-$(PROFILE)-$(VARIANT).log tests/boot/test-boot.sh $(ISO) $(OVMF_CODE) $(OVMF_VARS_TEMPLATE)

clean:
	cd image/live-build && $(SUDO) lb clean --purge
	rm -rf image/live-build/config/package-lists \
		image/live-build/config/includes.chroot_after_packages \
		image/live-build/config/hooks image/live-build/config/ban
