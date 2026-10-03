# Building Ban OS

Code is edited on Windows; **everything here runs on a Debian 13 build VM**. Nothing in the
build works on Windows except `cargo check`.

## 1. Prepare the VM (step 0.1)

| Item | Value |
| --- | --- |
| OS | Debian 13 (trixie) amd64, minimal install |
| Resources | at least 4 cores, 8 GB RAM, 80 GB disk |
| Virtualization | nested virtualization enabled on the hypervisor; check with `ls /dev/kvm` |
| Access | SSH from Windows; clone the repo **on the VM** and edit with VS Code Remote-SSH |

Create a normal user with sudo rights. On a minimal install, as root:

```bash
apt install sudo git && usermod -aG sudo <user>
```

Clone the repo on the VM's own filesystem (not a Windows share: live-build needs real Unix
permissions, device nodes and LF line endings).

## 2. Run the setup script (steps 0.2 and 0.3)

As the build user, not root:

```bash
scripts/setup-build-vm.sh
```

It is idempotent and installs:

- image tools: `live-build`, `debootstrap`, `squashfs-tools`, `xorriso`, `grub-efi-amd64-bin`,
  `mtools`, `dosfstools`, QEMU, OVMF, `git`, `make`, `debhelper`, `devscripts`;
- Agent / Center tools: rustup (stable), Node.js + pnpm, WebKitGTK 4.1 and GTK 3 dev libraries,
  `cargo-deb`, `tauri-cli`;
- `apt-cacher-ng` on port 3142, enabled at boot.

It warns if `/dev/kvm` is missing and adds the user to the `kvm` group. Open a new shell
afterwards so `~/.cargo/bin` and the group change apply.

If `static.rust-lang.org` is not reachable, export `RUSTUP_DIST_SERVER` and
`RUSTUP_UPDATE_ROOT` to a reachable mirror before running the script.

## 3. The local apt mirror

live-build only talks to `http://127.0.0.1:3142` (`image/live-build/auto/config`), for the
Debian archive and the security archive. Set `BAN_APT_CACHE` to use a full mirror instead.

apt-cacher-ng is a cache, not a mirror:

- The **first** build needs internet to fill the cache. Later builds are served from the cache.
- For a build with the internet fully disconnected, put `Offlinemode: 1` into
  `/etc/apt-cacher-ng/zz-ban.conf` and restart `apt-cacher-ng`, otherwise it tries to
  revalidate index files upstream and the build fails. Remove the line to refresh the cache.
- For each release, keep a dated copy of `/var/cache/apt-cacher-ng` so an old image can be
  rebuilt (step 0.3).

### Testing an offline build (Stage 0 acceptance)

Deleting the default route is not enough: the DHCP client adds it back on lease renewal.
Block outgoing traffic with nftables instead (loopback, which apt-cacher-ng uses, and open
connections such as the SSH session stay allowed):

```bash
sudo nft add table inet offline
sudo nft add chain inet offline out '{ type filter hook output priority 0; }'
sudo nft add rule inet offline out oif lo accept
sudo nft add rule inet offline out ct state established accept
sudo nft add rule inet offline out drop
curl -sI --max-time 5 http://deb.debian.org || echo "offline OK"
```

With `Offlinemode: 1` set, build each variant. Afterwards remove the table
(`sudo nft delete table inet offline`) and the `Offlinemode` line.

If apt reports `503` for `InRelease` files, apt-cacher-ng tried to go upstream: `Offlinemode`
is not set or apt-cacher-ng was not restarted. apt then falls back to stale indexes and fails
later on a package version that was never cached.

## 4. Build

```bash
make build PROFILE=development VARIANT=pos
```

Two independent choices:

- `PROFILE` is `development` (default), `staging` or `production`: how the image is locked
  down; see `config/README.md`.
- `VARIANT` is `pos` (default) or `server`: what the image is (graphical POS terminal or
  headless store server); see `image/variants/README.md`.

The target runs `image/scripts/build-image.sh <profile> <variant>`:

1. `lb clean`.
2. Stage package lists from `image/packages/`, `image/variants/<variant>/package-lists/` and
   `config/<profile>/package-lists/` into `image/live-build/config/package-lists/`. A name clash
   between them stops the build.
3. Stage the image files into `config/includes.chroot_after_packages/`: `image/configuration/`,
   then `image/variants/<variant>/configuration/`, then `config/<profile>/configuration/` (a later
   source replaces a file of an earlier one), the units from `services/systemd/`, and the
   generated `/etc/ban/release`.
4. Stage `config/ban/build.env` (profile and variant variables; read by the hooks, not copied
   into the image) and the hooks from `image/scripts/hooks/` into `config/hooks/normal/`.
5. `lb config`, then `lb build` (with sudo).

Everything staged under `image/live-build/config/` is generated and git-ignored; edit the
sources instead.

Output: `out/ban-os-<version>-<profile>-<variant>-amd64.iso`; `<version>` comes from the
`VERSION` file. The full log is `out/build-<profile>-<variant>.log`. The two variants share the
live-build working directory, so build them one after the other, not in parallel.

Other targets:

| Target | What it does |
| --- | --- |
| `make debs` | builds the Ban `.deb` packages into `out/debs/` (currently `ban-agent`, `ban-event`) |
| `make run-vm` | boots the ISO in QEMU + OVMF with a 32 GB virtual disk (`out/disk-<variant>.qcow2`) and a 1024x768 screen |
| `make test-boot` | headless boot; waits `BOOT_TIMEOUT` (120 s) for `BAN-BOOT-OK <version>` on the serial port; full serial output in `out/boot-<profile>-<variant>.log` |
| `make clean` | `lb clean --purge`: removes the chroot and the live-build cache (keeps `out/`) |

## 5. Boot the image

```bash
make run-vm                    # pos
make run-vm VARIANT=server     # server
```

`run-vm` and `test-boot` take the same `PROFILE` and `VARIANT` as `build` to find the ISO.

Over SSH there is no display; show the guest's screen on a password-protected VNC display:

```bash
make run-vm VNC=1
```

The first run creates a random 8-character password in `~/.config/ban-os/vnc-password` on the
build VM (VNC allows no more); every run prints it. Connect a VNC client to port 5901 of the build
VM, e.g. from a Mac through an SSH tunnel:

```bash
ssh -p 2222 -L 5901:127.0.0.1:5901 vboxuser@127.0.0.1
```

and then `vnc://localhost:5901` in Finder > Go > Connect to Server. The serial console stays on
the terminal that runs `make run-vm`, and port 2223 of the build VM is forwarded to the guest's
SSH (`GUEST_SSH_PORT`).

### Boot menu

The GRUB menu is hidden and boots "Ban OS" after 1 second. Press **Esc** (or F4, or hold Shift
where the firmware reports it) right after power-on to show it. Entries:

| Entry | `pos` | `server` | Needs the GRUB password |
| --- | --- | --- | --- |
| Ban OS | ✓ | ✓ | no |
| Ban OS - Maintenance (`ban.mode=maintenance`) | ✓ | | yes |
| Ban OS - Recovery (`ban.mode=recovery`, placeholder until Stage 10) | ✓ | ✓ | yes |

Editing an entry (`e`) or the GRUB command line (`c`) asks for user `ban` and the password. On
development ISOs that is `BAN_DEV_GRUB_PASSWORD` in `config/development/profile.env`; staging and
production ISOs get a random password at every build that is not stored anywhere, so their menu
cannot be edited (the installed system gets its own password at provisioning, Stage 12).

`pos` boots quietly with the Plymouth splash and only the boot marker reaches the serial port.
`server` has no splash and sends GRUB, the kernel and a login prompt to the serial port as well
(IPMI serial-over-LAN).

### Logging in

Only **development** images have a login: user `maintenance` with full sudo, on the console or
over SSH. Its password is `BAN_DEV_MAINTENANCE_PASSWORD` in `config/development/profile.env`.
staging and production images have no login user before Stage 2; root is locked on all images.

`make run-vm` forwards port 2223 of the build VM to the guest's SSH, so from a second session
on the build VM:

```bash
ssh -p 2223 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null maintenance@127.0.0.1
```

A live guest creates new SSH host keys at every boot, so its key is not stored; otherwise SSH
refuses the next boot with "REMOTE HOST IDENTIFICATION HAS CHANGED".

### Without KVM

Software emulation boots several times slower and the guest needs RAM the build VM may not have:

```bash
make test-boot VARIANT=pos BOOT_TIMEOUT=900 VM_MEM=2048
```

### Stage 1 acceptance

On a development image of each variant (`timedatectl` and `pg_lsclusters` as `maintenance`):

| Check | Expected |
| --- | --- |
| `make test-boot VARIANT=pos` and `VARIANT=server` | `test-boot: OK` |
| `timedatectl` | `Time zone: Asia/Tehran`, `NTP service: active` |
| `pg_lsclusters` | `17 main ... online` |
| `ls -lh out/*.iso` | record the sizes; target `pos` < 1.2 GB, `server` < 800 MB |

Stage 1 adds packages, so build once **online** to fill the apt-cacher-ng cache before an
offline re-test.

### Stage 2 acceptance

The `pos` checks need a screen: `make run-vm VARIANT=pos VNC=1` and a VNC client (see
"Boot the image"). Without KVM every boot takes minutes, so the "< 20 s" target can only be
measured on real hardware or KVM (`docs/operations/boot-time.md`).

| Check | `pos` | `server` |
| --- | --- | --- |
| Power on, no input | Ban splash, then the empty Ban session (dark `#101418` screen) | status screen on tty1 and on the serial port |
| Esc at power-on | GRUB menu with 3 entries | GRUB menu with 2 entries, also on serial |
| `e` on an entry | asks for user `ban` and password | same |
| X fails 3 times in 60 s | `ban-bootfail` screen on tty1 (`E-GFX-01`), `GRAPHICS_FAILED` in the journal | (no X) |
| `Ctrl+Alt+F3` | nothing to log in to (tty2..6 closed; VT switching itself is blocked in Stage 3) | same |
| `dpkg -l 'xserver-*'` | installed | **no packages** |
| `journalctl -b -g SYSTEM_BOOT` | one `SYSTEM_BOOT` line | same |

To provoke the `ban-bootfail` screen on a development `pos` guest (SSH or VNC):

```bash
printf '[Seat:*]
xserver-command=/bin/false
' | sudo tee /etc/lightdm/lightdm.conf.d/99-break.conf
sudo systemctl restart lightdm
```

LightDM then fails three times within a minute and tty1 shows the error screen. Remove the file
and reboot to undo it (the live system forgets it anyway).

## 6. CI

`.github/workflows/build.yml` runs on every push on a self-hosted GitHub Actions runner on the
build VM: shellcheck, `make debs`, then `make build test-boot` for `pos` and `server`. Build
logs and serial logs are uploaded as the `logs` artifact.

One-time setup on the build VM:

1. GitHub repository > Settings > Actions > Runners > New self-hosted runner (Linux, x64).
   Follow the download and `./config.sh` steps shown there and add the label `ban-build`.
2. Install it as a service running as the build user: `sudo ./svc.sh install <user>` and
   `sudo ./svc.sh start`.
3. The build calls `sudo lb`, `sudo mv` and `sudo chown`. CI cannot type a password, so allow
   them without one: `sudo visudo -f /etc/sudoers.d/ban-ci` with
   `<user> ALL=(root) NOPASSWD: /usr/bin/lb, /usr/bin/mv, /usr/bin/chown`. This is effectively
   root for that user; acceptable on a dedicated build VM only.
4. Without KVM, set the repository variables `BOOT_TIMEOUT` (e.g. `900`) and `VM_MEM` (e.g.
   `2048`) under Settings > Secrets and variables > Actions > Variables.

## Troubleshooting

- `apt mirror ... is not reachable`: `systemctl status apt-cacher-ng`.
- `OVMF firmware not found`: check `ls /usr/share/OVMF/` and pass `OVMF_CODE=<file>` (and
  `OVMF_VARS_TEMPLATE=<file>`) to make. QEMU gets the firmware as two pflash drives, read-only
  code and a writable copy of the UEFI variable store (`out/ovmf-vars-<variant>.fd` for
  `run-vm`, a fresh temporary copy for every `test-boot`); `-bios` cannot load the split
  4 MB build that Debian 13 ships.
- Build fails at a download while offline: the package is not in the cache yet; build once online.
- Scripts fail with `\r: command not found`: the repo was checked out with CRLF. Clone on the VM;
  `.gitattributes` forces LF.
