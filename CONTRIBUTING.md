# Contributing to Ban OS

Conventions from the plan (part 1, step 0.7). The plans in [docs/plan/](docs/plan/) are the
reference; if code and plan disagree, raise it instead of silently picking one.

## Working order

Work follows the stages in `docs/plan/plan steps.md`. A stage is closed only when its acceptance
criterion passes on QEMU or real hardware; then the next stage starts.

## Service and package names

Two prefixes only:

- `ban-*`: everything that belongs to the OS: `ban-agent`, `ban-event`, `ban-sync`,
  `ban-update`, `ban-hardware` (also `ban-center`, `ban-metrics`, `ban-session`, ...).
- `adad-*` / `adad`: everything that belongs to the POS application: `adad`, `adad-launcher`.

The image variants are `pos` and `server` (plan part 1, step 0.8). Both share `OS_VERSION`
and are always released together; a component that exists in only one variant says so in its
folder `README.md`.

The systemd unit, the binary, the `.deb` package and the system user of a service share the same
name (`ban-agent.service`, `/opt/ban/agent/ban-agent`, `ban-agent_<ver>_amd64.deb`, user `ban-agent`).

## Versions

Four versions, all [SemVer](https://semver.org), all **independent** of each other:

| Version | What it versions | Where it lives in this repo |
| --- | --- | --- |
| `OS_VERSION` | the Ban OS image | `VERSION` |
| `APP_VERSION` | Adad POS | the `adad-pos` repository (`/opt/adad/VERSION` on the device) |
| `AGENT_API_VERSION` | the Agent <-> Center contract | version of `crates/ban-api-types` |
| `HARDWARE_API_VERSION` | the hardware interface | defined in Stage 8 |

On the device, `/etc/ban/release` lists all of them (written at image build, from Stage 1).
Component packages (`ban-agent`, `ban-center`, ...) carry their own package version; do not use
a shared workspace version in `Cargo.toml`.

`CHANGELOG.md` follows Keep a Changelog and tracks `OS_VERSION`.

## Artifact names

| Artifact | Pattern | Example |
| --- | --- | --- |
| Image | `ban-os-<OS_VERSION>-<variant>-amd64.iso` / `.img.zst` (`server` also `.qcow2`) | `ban-os-1.0.0-pos-amd64.iso`, `ban-os-1.0.0-server-amd64.iso` |
| Build output of `make build` | `ban-os-<OS_VERSION>-<profile>-<variant>-amd64.iso` | `ban-os-0.1.0-development-pos-amd64.iso` |
| Package | `<name>_<version>_amd64.deb` | `ban-agent_1.0.0_amd64.deb` |

Build outputs go to `out/` (images) and `out/debs/` (packages); never commit them.

## Branches and tags

- `main`: stable. `develop`: integration. `feature/*`: work branches off `develop`.
  `release/*`: release preparation.
- Tags are per component: `os-v1.0.0`, `center-v1.0.0` (same scheme for other components,
  e.g. `agent-v0.2.0`).

## Code rules

- Shell: bash, `set -euo pipefail`, clean under `shellcheck`. (`image/live-build/auto/*` are
  POSIX `sh` with `set -e`, as live-build expects.)
- Line endings: LF for everything that runs on Debian or lands in the image; `.gitattributes`
  enforces it. Scripts are committed with the executable bit
  (`git update-index --chmod=+x <file>` when working from Windows).
- Rust: `cargo fmt`, `cargo clippy` clean; shared API types only in `crates/ban-api-types`.
- No secrets, keys, passwords or PINs in the repository or in `staging` / `production` profiles.
- Do not reimplement what Linux already provides (restart, dependencies and health checks are
  systemd's job).
- Every new folder gets a short `README.md`: what belongs there and which stage fills it.
