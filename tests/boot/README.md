# tests/boot/

Boot tests that run the ISO in QEMU + OVMF.

- `test-boot.sh` (`make test-boot`): headless boot, waits up to 120 s for `BAN-BOOT-OK <version>`
  on the serial port. The marker is written by `ban-boot-ok.service`, which arrives in Stage 1,
  so this test is expected to time out on a Stage 0 image.

**Filled in:** Stage 0 (`test-boot.sh`); Stage 1 (marker service, CI); Stages 2 and 3
(autologin, kiosk and crash-restart checks).
