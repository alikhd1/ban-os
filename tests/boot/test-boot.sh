#!/usr/bin/env bash
# Headless boot test: boot the ISO in QEMU + OVMF and wait for the success
# marker "BAN-BOOT-OK <version>" on the serial port (plan part 1, step 1.7).
# Normally called through `make test-boot`.
#
# The marker is written by ban-boot-ok.service, which arrives in Stage 1.
# Until then this test is expected to time out.
#
# Usage: tests/boot/test-boot.sh <iso> <ovmf-code.fd>
#
# Environment:
#   BOOT_TIMEOUT  seconds to wait for the marker, default 120

set -euo pipefail

ISO="${1:-}"
OVMF_CODE="${2:-}"
BOOT_TIMEOUT="${BOOT_TIMEOUT:-120}"
MARKER="BAN-BOOT-OK"

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
cleanup() {
  if [[ -n "${QEMU_PID}" ]]; then
    kill "${QEMU_PID}" 2> /dev/null || true
  fi
  rm -f "${SERIAL_LOG}"
}
trap cleanup EXIT

qemu-system-x86_64 "${KVM[@]}" -m 4096 -smp 2 \
  -bios "${OVMF_CODE}" \
  -cdrom "${ISO}" \
  -serial "file:${SERIAL_LOG}" -display none -no-reboot &
QEMU_PID=$!

for ((elapsed = 0; elapsed < BOOT_TIMEOUT; elapsed++)); do
  if grep -q "${MARKER}" "${SERIAL_LOG}"; then
    echo "test-boot: OK after ${elapsed}s: $(grep -m1 "${MARKER}" "${SERIAL_LOG}")"
    exit 0
  fi
  kill -0 "${QEMU_PID}" 2> /dev/null || {
    echo "test-boot: FAIL, QEMU exited before the marker appeared" >&2
    exit 1
  }
  sleep 1
done

echo "test-boot: FAIL, no '${MARKER}' on serial within ${BOOT_TIMEOUT}s. Last serial output:" >&2
tail -n 20 "${SERIAL_LOG}" >&2 || true
exit 1
