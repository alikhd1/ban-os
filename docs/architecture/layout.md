# Directories and partitions

Where Ban OS keeps what (plan part 1, step 1.6; partitions from plan part 3, step 10.1).
Principle (full-chat §5): **data is separate from the OS**. Everything under `/var/lib` survives an
OS update untouched.

## Directories

| Path | Content | Created by |
| --- | --- | --- |
| `/opt/adad/` | `bin/ lib/ plugins/ resources/` of the Adad application (Stage 3) | image hook |
| `/opt/ban/` | `agent/ center/ hardware/ updater/ browser/`, `boot/` (boot helpers), `kiosk/` (`pos`: `ban-session`, `apply-display`, `ban-bootfail`) | image hook, `files.list` |
| `/etc/adad/` | `config.toml` (Stage 3) | image hook |
| `/etc/ban/` | `release`; `display.toml` and `openbox/rc.xml` (`pos`, Stage 2); `*.toml` settings (Stage 4, step 4.7) | image hook, build |
| `/var/lib/adad/` | `sync/ cache/ backups/` | `tmpfiles.d/ban.conf` at boot |
| `/var/lib/ban/` | `audit.db`, `metrics.db` (Stage 4), `backups/ outbox/`; `bootcount`, `last-shutdown` (Stage 2) | `tmpfiles.d/ban.conf` at boot |
| `/var/lib/postgresql/` | PostgreSQL cluster `17/main` | `postgresql-17` package |
| `/var/log/adad/` | Adad log files, rotated by `/etc/logrotate.d/adad` | `tmpfiles.d/ban.conf` at boot |
| `/run/ban/` | `agent.sock`, `event.sock` (Stage 4); `clock-invalid` (Stage 1) and `first-boot` (Stage 2) flags | `tmpfiles.d/ban.conf` at boot |

The image hook is `image/scripts/hooks/7000-ban-system.hook.chroot`. Directories under `/var` and
`/run` come from `tmpfiles.d` so they are recreated on an empty data partition. All are owned by
root for now; the service users (`adad`, `ban-agent`, ...) take them over in Stages 2 to 4.

## Users (Stage 2, step 2.4)

| User | Variant | Shell | Groups | Login |
| --- | --- | --- | --- | --- |
| `root` | all | | | locked |
| `adad` | `pos` | `/usr/sbin/nologin` | `ban-ipc lp dialout input video` | none; LightDM autologin into the Ban session |
| `maintenance` | all | `/bin/bash` | `ban-ipc` (+ `sudo` on development) | development: known password; staging/production: locked until the PIN flow (Stage 3) and the sudo whitelist (Stage 11) |
| `ban-agent` | all | `/usr/sbin/nologin` | own group | system user for Ban Agent (Stage 4) |
| `ban-console` | `server` | `/usr/sbin/nologin` | `ban-ipc` | system user for `ban-console` (Stage 5) |

`ban-ipc` is the group that may talk to the Ban sockets in `/run/ban/` (Stage 4).

## `/etc/ban/release`

Written at build time by `image/scripts/build-image.sh`:

```
OS_VERSION=0.1.0
OS_VARIANT=pos              # or server
OS_PROFILE=development      # or staging, production
OS_BUILD_DATE=2026-10-01T09:43:00Z
AGENT_API_VERSION=0.1.0
```

`APP_VERSION` is added with the Adad package (Stage 3), `HARDWARE_API_VERSION` with
`ban-hardware` (Stage 8). `ban-clock-check` compares the clock with `OS_BUILD_DATE`.

## Temporary files and disk wear (step 1.5)

| Item | Where | Status |
| --- | --- | --- |
| `/tmp` in RAM | Debian 13 default `tmp.mount` | active |
| `/var/tmp` in RAM | `services/systemd/var-tmp.mount` | active |
| `fstrim.timer` | enabled by the image hook | active |
| journald cap | `journald.conf.d/ban.conf`: 200 MB, 1 month, compressed | active |
| logrotate | `/etc/logrotate.d/adad` | active |
| `noatime,commit=30` on root and data | `/etc/fstab` of the installed system | **Stage 12** |

The Stage 1 image is a live system: its root is a read-only squashfs with a RAM overlay and it
has no fstab entry for root or data. The mount options are written by the installer
(Stage 12, `installer/postinstall/`) together with the partitions below. For the same reason the
"persistent" journal of a live boot is lost at shutdown; it becomes persistent on an installed
system.

## Partitions of an installed system (Stage 10, step 10.1)

| Partition | Size | Mount | Notes |
| --- | --- | --- | --- |
| EFI | 512 MB | `/boot/efi` | FAT32 |
| System A | 12 GB | `/` | ext4, `noatime,commit=30` |
| System B | 12 GB | none | reserved for A/B updates after 1.0 |
| Recovery | 2 GB | none | small recovery system and factory copies of the Ban `.deb`s |
| Data | rest | `/data` | ext4, `data=ordered`, `noatime,commit=30`; bind-mounted to `/var/lib/postgresql`, `/var/lib/adad`, `/var/lib/ban`, `/var/log` |

Minimum disk: 32 GB (System A and B then 8 GB each). Same layout for both variants; a server
only has a larger Data partition.
