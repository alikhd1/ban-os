# services/systemd/

All systemd units of Ban OS and the standard unit template `_template.service` (Stage 4).

`image/scripts/build-image.sh` installs every `*.service`, `*.timer`, `*.mount` and `*.target`
here into `/usr/lib/systemd/system/` of the image; the image hook enables them.

| Unit | Stage | Purpose |
| --- | --- | --- |
| `ban-boot-ok.service` | 1 (step 1.7) | writes `BAN-BOOT-OK <OS_VERSION>` to ttyS0 after `multi-user.target` (`make test-boot`) |
| `ban-clock-check.service` | 1 (step 1.4) | `CLOCK_INVALID` when the clock is older than the build year |
| `var-tmp.mount` | 1 (step 1.5) | `/var/tmp` as tmpfs |

Their scripts are in `image/configuration/opt/ban/boot/`.

**Filled in:** boot units in Stage 1; template and Ban service units in Stage 4; session (user)
units in Stages 2 and 3.
