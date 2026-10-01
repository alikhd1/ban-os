# Changelog

All notable changes to Ban OS are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and Ban OS
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html). This file tracks
`OS_VERSION`; components with their own version are named explicitly.

## [Unreleased]

### Added (Stage 2, boot and login)

- ISO boot menu (`7100-ban-grub.hook.binary`): hidden, 1 s, Esc or Shift shows it; entries
  "Ban OS" (unrestricted), "Maintenance" (`pos`) and "Recovery" (placeholder target until
  Stage 10); editing needs GRUB user `ban`. development: known password; staging/production: a
  random password per build that is not kept. Kernel command line per variant in `variant.env`;
  `server` also on the serial port. `/etc/default/grub.d/ban.cfg` for the installed system.
- Boot sequence: `graphical.target` (`pos`) / `multi-user.target` (`server`), tty2..6 closed,
  `apt-daily*`, `ModemManager`, `e2scrub_all` masked, `NetworkManager-wait-online` disabled,
  `/etc/issue` with version, hostname and IP, `/etc/motd` without the Debian text and uname line.
- Users of step 2.4: `adad` (`pos`), `maintenance`, `ban-agent`, `ban-console` (`server`), group
  `ban-ipc`.
- `pos` graphical session: `kiosk.list.chroot`, LightDM autologin of `adad` into the `ban`
  session, `ban-session`, `apply-display` with `/etc/ban/display.toml`, Openbox config, user target
  `ban-session.target`.
- Plymouth theme `ban` with the BAN logo, a progress bar and "Powered by bans.ir" on `#101418`.
- `ban-bootfail` screen on tty1 after 3 failed LightDM starts in 60 s (`GRAPHICS_FAILED`).
- Boot events in the journal: `SYSTEM_BOOT` (duration, previous end), `SYSTEM_CRASH`,
  `SYSTEM_SHUTDOWN`, `SYSTEM_REBOOT`; boot counter `/var/lib/ban/bootcount`.
- `docs/operations/boot-time.md`.

### Changed (Stage 2)

- The GRUB menu shows with Esc/Shift, not F12 (GRUB's hidden menu cannot react to F12, and F12 is
  the firmware boot menu on many mini PCs); no "Press F12" hint in Plymouth, which starts after
  GRUB.
- LightDM starts X without `-nocursor`; `unclutter --hide-on-touch` (the plan's `--touch` does
  not exist) hides the pointer instead.
- `kiosk.list.chroot` also has `xinput`, `python3` and `kbd`.
- Not yet active on a live ISO: `40_ban` and `update-grub` (Stage 12), fsck repair to Recovery,
  Recovery after 3 failed boots and the data partition check (Stages 10 and 12).

### Added (Stage 1, base system)

- Package lists of step 1.2: common (`base`, `firmware`, `network`, `locale`, `postgres`,
  `diag`), `pos` (`print`, `fonts`, `browser`), `server` (VM guest agents) and development
  (`dev`). `logrotate` added to `base` for step 1.5.
- Image files (step 1.3 to 1.6): hostname `ban-os`, locales `en_US.UTF-8` (default) and
  `fa_IR.UTF-8`, timezone `Asia/Tehran`, keyboard `us,ir`, persistent journald with a 200 MB cap,
  timesyncd with `ir.pool.ntp.org` and the Debian pool as fallback, `/etc/logrotate.d/adad`, Ban
  directories (`tmpfiles.d/ban.conf`), generated `/etc/ban/release`.
- Units `ban-boot-ok.service` (marker for `make test-boot`), `ban-clock-check.service`
  (`CLOCK_INVALID` in the journal and `/run/ban/clock-invalid`), `var-tmp.mount`;
  `fstrim.timer` enabled.
- Development images: user `maintenance` with full sudo and SSH.
- CI workflow `.github/workflows/build.yml` for a self-hosted runner on the build VM.
- `docs/architecture/layout.md`, `docs/operations/test-hardware.md`.
- Stage 1 acceptance passed on 2026-10-01 (development profile, QEMU + OVMF without KVM):
  both variants boot and pass `make test-boot`, `Asia/Tehran` with NTP active, PostgreSQL
  `17/main` online. ISO sizes: `pos` 803 MB (target < 1.2 GB), `server` 530 MB
  (target < 800 MB).

### Changed (Stage 1)

- No `live-config` in the image: it rewrote hostname, locale, timezone and keyboard at every
  boot and created a user with a well-known password.
- GRUB boots the default entry after 5 s (live-build's menu waited forever); kernel and systemd
  output also on the serial port. Both until Stage 2.
- PostgreSQL TLS off until Stage 3 (live-build removes the snakeoil certificate).
- QEMU loads the UEFI firmware as pflash drives (`OVMF_CODE_4M.fd` read-only plus a copy of
  `OVMF_VARS_4M.fd`); the plan's `-bios OVMF_CODE.fd` does not exist on Debian 13.
- `make test-boot` matches only the marker line, keeps the serial log in `out/`, and takes
  `BOOT_TIMEOUT` and `VM_MEM`; `make run-vm` takes `VM_MEM`.

### Added (Stage 0)

- Stage 0: repository skeleton with a README per folder; plans moved to `docs/plan/`.
- Cargo workspace with minimal crates `ban-agent` 0.1.0, `ban-event` 0.1.0 and
  `ban-api-types` 0.1.0 (`AGENT_API_VERSION`).
- `scripts/setup-build-vm.sh`: Debian 13 build VM setup (live-build, QEMU/OVMF, Rust, Node + pnpm,
  WebKitGTK, cargo-deb, tauri-cli, apt-cacher-ng).
- `Makefile` targets `debs`, `build`, `run-vm`, `test-boot`, `clean`; minimal live-build
  configuration using the local apt-cacher-ng mirror.
- live-build uses `--firmware-chroot false` so the build works offline; firmware comes only
  from the explicit `firmware.list.chroot` (Stage 1). Plan step 1.1 updated.
- Image profiles `development`, `staging`, `production`.
- Image variants `pos` (graphical POS terminal, default) and `server` (headless store server)
  in `image/variants/`: `make build VARIANT=<pos|server>`, output
  `ban-os-<version>-<profile>-<variant>-amd64.iso`, one QEMU disk per variant. The build stops
  when two package lists of different sources share a name.
- Plans updated for the `server` variant and its text UI `ban-console` (`console/`).
- Proprietary `LICENSE` (Copyright (c) 2026 Bans); referenced by all crates and their `.deb` packages.
- `VERSION` 0.1.0, `README.md`, `CONTRIBUTING.md`, `docs/architecture/build.md`.
