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

## 4. Build

```bash
make build PROFILE=development
```

`PROFILE` is `development` (default), `staging` or `production`; see `config/README.md`.
The target runs `image/scripts/build-image.sh`: `lb clean` -> stage package lists from
`image/packages/` and `config/<profile>/package-lists/` -> `lb config` -> `lb build` (with sudo).

Output: `out/ban-os-<version>-<profile>-amd64.iso`; `<version>` comes from the `VERSION` file.
The full log is `image/live-build/build.log`.

Other targets:

| Target | What it does |
| --- | --- |
| `make debs` | builds the Ban `.deb` packages into `out/debs/` (currently `ban-agent`, `ban-event`) |
| `make run-vm` | boots the ISO in QEMU + OVMF with a 32 GB virtual disk (`out/disk.qcow2`) and a 1024x768 screen |
| `make test-boot` | headless boot; waits 120 s for `BAN-BOOT-OK <version>` on the serial port |
| `make clean` | `lb clean --purge`: removes the chroot and the live-build cache (keeps `out/`) |

## 5. Boot the image

```bash
make run-vm
```

Over SSH there is no display; either use X forwarding or a VNC display:

```bash
make run-vm QEMU_EXTRA="-display vnc=:1"
```

then connect a VNC client to `<vm>:5901`. The serial console is on the terminal.

In Stage 0 the image is a bare Debian live system: it boots to a login prompt and nothing more.
`make test-boot` times out until Stage 1 adds `ban-boot-ok.service`.

## Troubleshooting

- `apt mirror ... is not reachable`: `systemctl status apt-cacher-ng`.
- `OVMF firmware not found`: check `ls /usr/share/OVMF/` and pass `OVMF_CODE=<file>` to make.
- Build fails at a download while offline: the package is not in the cache yet; build once online.
- Scripts fail with `\r: command not found`: the repo was checked out with CRLF. Clone on the VM;
  `.gitattributes` forces LF.
