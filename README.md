# Ban OS

Ban OS is a Debian 13 based operating system for point-of-sale devices. It boots straight into
the **Adad POS** application in a locked kiosk session and gives technicians a controlled
maintenance path instead of a desktop.

It is built in two variants from the same build and the same packages:

- **`pos`**: the POS terminal described above (graphical, kiosk, Adad, Ban Center).
- **`server`**: a headless store server: PostgreSQL for the POS clients of the store plus the
  Ban services, no X and no Adad UI, managed from `ban-console` (text UI on tty1).

Main parts:

- **Image**: Debian 13 (trixie) amd64 built with `live-build`; Xorg + Openbox + LightDM kiosk
  (`pos` variant only).
- **Ban Agent** (`agent/`): Rust daemon, the only component that performs privileged operations.
- **Ban Event** (`event/`): event and audit log (SQLite, outbox, hash chain).
- **Ban Center** (`center/`): technician panel, Tauri 2 + React, Persian / RTL (`pos`).
- **Ban Console** (`console/`): text-mode technician panel of the `server` variant and the
  Recovery UI of both.
- **Adad Launcher** (`launcher/`), **hardware layer** (`hardware/`), **updater**, **recovery**,
  **installer**.

Status: **Stage 0** (repo skeleton and build environment). See [CHANGELOG.md](CHANGELOG.md).

## Build

The build runs on a Debian 13 VM, not on Windows. Full guide:
[docs/architecture/build.md](docs/architecture/build.md).

```bash
scripts/setup-build-vm.sh          # once, on the build VM
make build PROFILE=development     # -> out/ban-os-<version>-development-pos-amd64.iso
make build VARIANT=server          # -> out/ban-os-<version>-development-server-amd64.iso
make run-vm                        # boot it in QEMU + OVMF (VARIANT=server for the server ISO)
```

Profiles: `development`, `staging`, `production`; see [config/README.md](config/README.md).
Variants: `pos`, `server`; see [image/variants/README.md](image/variants/README.md).

## Documentation

- Plans (Persian): [docs/plan/](docs/plan/). Start with
  [plan steps.md](docs/plan/plan%20steps.md), the staged roadmap.
- Architecture: [docs/architecture/](docs/architecture/)
- Conventions: [CONTRIBUTING.md](CONTRIBUTING.md)

Every folder has a `README.md` that says what belongs there and which stage fills it.

## License

Proprietary. Copyright (c) 2026 Bans, all rights reserved; see [LICENSE](LICENSE).
Third-party components keep their own licenses.
