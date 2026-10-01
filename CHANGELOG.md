# Changelog

All notable changes to Ban OS are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and Ban OS
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html). This file tracks
`OS_VERSION`; components with their own version are named explicitly.

## [Unreleased]

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
