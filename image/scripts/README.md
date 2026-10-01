# image/scripts/

Build scripts and live-build hooks.

- `build-image.sh <profile> <variant>`: `lb clean` -> stage package lists, image files, units,
  `/etc/ban/release`, hooks -> `lb config` -> `lb build`, then moves the ISO to
  `out/ban-os-<version>-<profile>-<variant>-amd64.iso`. Called by `make build`; the steps are
  described in `docs/architecture/build.md`.
- `hooks/`: live-build hooks, staged into `image/live-build/config/hooks/normal/`. Numbered
  `7xxx-ban-*` so they run after live-build's own `1xxx` hooks and before its `8xxx` clean-up
  hooks. `*.hook.chroot` runs inside the image, `*.hook.binary` on the build host in `binary/`.
  The chroot hooks read the build variables from `/live-build/config/ban/build.env`.

| Hook | Stage | What it does |
| --- | --- | --- |
| `7000-ban-system.hook.chroot` | 1 | locales, timezone, root lock, Ban directories, PostgreSQL TLS off, enable units |
| `7010-ban-users.hook.chroot` | 1, 2 | users and groups of step 2.4 per variant and profile |
| `7030-ban-boot.hook.chroot` | 2 | default target, closed tty2..6, masked timers, no wait-online, `/etc/default/grub.d/ban.cfg`, `/etc/issue` |
| `7040-ban-kiosk.hook.chroot` | 2 | `pos`: LightDM enabled, Plymouth theme `ban` in the initramfs |
| `7100-ban-grub.hook.binary` | 2 | the ISO's GRUB menu: hidden, 1 s, password, Ban OS entries from `variant.env` |

**Filled in:** Stage 0 (`build-image.sh`); hooks from Stage 1 onward.
