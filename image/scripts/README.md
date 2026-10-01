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
| `7010-ban-profile.hook.chroot` | 1 | development: `maintenance` user with full sudo |
| `7100-ban-grub-timeout.hook.binary` | 1 | 5 s GRUB timeout (replaced in Stage 2) |

**Filled in:** Stage 0 (`build-image.sh`); hooks from Stage 1 onward.
