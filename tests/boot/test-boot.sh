#!/usr/bin/env bash
# Headless boot test: boot the ISO in QEMU + OVMF and wait for the success
# marker "BAN-BOOT-OK <version>" on the serial port (plan part 1, step 1.7).
# The marker is written by ban-boot-ok.service after multi-user.target.
# Normally called through `make test-boot`.
#
# Usage: tests/boot/test-boot.sh <iso> <ovmf-code.fd>
#
# Environment:
#   BOOT_TIMEOUT  seconds to wait for the marker, default 120 (raise it
#                 without KVM: software emulation boots several times slower)
#   VM_MEM        guest RAM in MiB, default 4096
#   BOOT_LOG      if set, the full serial output is copied there

set -euo pipefail

ISO="${1:-}"
OVMF_CODE="${2:-}"
BOOT_TIMEOUT="${BOOT_TIMEOUT:-120}"
VM_MEM="${VM_MEM:-4096}"
# The marker line itself, not systemd's "Starting ban-boot-ok.service" line.
MARKER_RE='^BAN-BOOT-OK [0-9]'

[[ -f "${ISO}" && -f "${OVMF_CODE}" ]] || {
  echo "usage: $0 <iso> <ovmf-code.fd>" >&2
  exit 2
}

KVM=()
if [[ -w /dev/kvm ]]; then
  KVM=(-enable-kvm)
else
  echo "test-boot: /dev/kvm not usable, falling back to emulation (slow)" >&2
fi

SERIAL_LOG="$(mktemp)"
QEMU_PID=""
# shellcheck disable=SC2317,SC2329  # invoked through the EXIT trap
cleanup() {
  if [[ -n "${QEMU_PID}" ]]; then
    kill "${QEMU_PID}" 2> /dev/null || true
  fi
  if [[ -n "${BOOT_LOG:-}" ]]; then
    cp "${SERIAL_LOG}" "${BOOT_LOG}" || true
  fi
  rm -f "${SERIAL_LOG}"
}
trap cleanup EXIT

qemu-system-x86_64 "${KVM[@]}" -m "${VM_MEM}" -smp 2 \
  -bios "${OVMF_CODE}" \
  -cdrom "${ISO}" \
  -serial "file:${SERIAL_LOG}" -display none -no-reboot &
QEMU_PID=$!

for ((elapsed = 0; elapsed < BOOT_TIMEOUT; elapsed++)); do
  if tr -d '\r' < "${SERIAL_LOG}" | grep -aqE "${MARKER_RE}"; then
    echo "test-boot: OK after ${elapsed}s: $(tr -d '\r' < "${SERIAL_LOG}" | grep -aE -m1 "${MARKER_RE}")"
    exit 0
  fi
  kill -0 "${QEMU_PID}" 2> /dev/null || {
    echo "test-boot: FAIL, QEMU exited before the marker appeared" >&2
    exit 1
  }
  sleep 1
done

echo "test-boot: FAIL, no BAN-BOOT-OK on serial within ${BOOT_TIMEOUT}s. Last serial output:" >&2
tail -n 40 "${SERIAL_LOG}" >&2 || true
exit 1
