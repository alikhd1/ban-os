# Changelog

All notable changes to Ban OS are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and Ban OS
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html). This file tracks
`OS_VERSION`; components with their own version are named explicitly.

## [Unreleased]

### Added

- Stage 0: repository skeleton with a README per folder; plans moved to `docs/plan/`.
- Cargo workspace with minimal crates `ban-agent` 0.1.0, `ban-event` 0.1.0 and
  `ban-api-types` 0.1.0 (`AGENT_API_VERSION`).
- `scripts/setup-build-vm.sh`: Debian 13 build VM setup (live-build, QEMU/OVMF, Rust, Node + pnpm,
  WebKitGTK, cargo-deb, tauri-cli, apt-cacher-ng).
- `Makefile` targets `debs`, `build`, `run-vm`, `test-boot`, `clean`; minimal live-build
  configuration using the local apt-cacher-ng mirror.
- Image profiles `development`, `staging`, `production`.
- `VERSION` 0.1.0, `README.md`, `CONTRIBUTING.md`, `docs/architecture/build.md`.
