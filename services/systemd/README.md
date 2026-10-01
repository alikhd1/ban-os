# services/systemd/

All systemd units of Ban OS and the standard unit template `_template.service` (Stage 4).

`image/scripts/build-image.sh` installs every `*.service`, `*.timer`, `*.mount` and `*.target`
here into `/usr/lib/systemd/system/`, and `user/*` into `/usr/lib/systemd/user/`; the image
hooks enable them. Unit drop-ins for Debian services (e.g. `lightdm.service.d/`) live in the
variant's or profile's `configuration/`.

| Unit | Stage | Purpose |
| --- | --- | --- |
| `ban-boot-ok.service` | 1, 2 | after `multi-user.target`: `SYSTEM_BOOT` and boot counter reset (`ban-boot-events`), then `BAN-BOOT-OK <OS_VERSION>` on ttyS0 for `make test-boot` |
| `ban-clock-check.service` | 1 (step 1.4) | `CLOCK_INVALID` when the clock is older than the build year |
| `var-tmp.mount` | 1 (step 1.5) | `/var/tmp` as tmpfs |
| `ban-bootcount.service` | 2 (step 2.7) | counts consecutive boots that did not reach `multi-user.target` |
| `ban-shutdown-mark.service` | 2 | `SYSTEM_SHUTDOWN` / `SYSTEM_REBOOT` and the clean-shutdown mark (else `SYSTEM_CRASH` next boot) |
| `ban-bootfail.service` | 2 (step 2.7) | `pos`: error screen on tty1 when the graphical session cannot start |
| `ban-recovery.target`, `ban-recovery.service` | 2 (step 2.1) | target of the GRUB Recovery entry; placeholder screen until Stage 10 |
| `user/ban-session.target` | 2 (step 2.5) | user services of the graphical session; empty until Stage 3 |

Their scripts are in `image/configuration/opt/ban/boot/` and `kiosk/`. Until `ban-event` exists
(Stage 4) the events are journal lines such as `SYSTEM_BOOT duration_s=... previous=...`
(`journalctl -g SYSTEM_`).

**Filled in:** boot units in Stages 1 and 2; template and Ban service units in Stage 4; session
user units in Stage 3.
