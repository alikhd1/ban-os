# tests/boot/

Boot tests that run the ISO in QEMU + OVMF.

- `test-boot.sh` (`make test-boot`): headless boot, waits up to `BOOT_TIMEOUT` (120 s) for the
  line `BAN-BOOT-OK <version>` on the serial port, written by `ban-boot-ok.service` after
  `multi-user.target`. `VM_MEM` sets the guest RAM; `make test-boot` keeps the serial output in
  `out/boot-<profile>-<variant>.log`.

**Filled in:** Stage 0 (`test-boot.sh`); Stage 1 (marker service, CI); Stages 2 and 3
(autologin, kiosk and crash-restart checks).
