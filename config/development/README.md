# config/development/

Developer image. **Never install it in a store.**

Differences from production: SSH on, user `maintenance` with full sudo, devtools enabled in
Ban Center, update channel `dev`, a well-known default technician PIN is allowed.

Contents:

- `profile.env`: build variables, including `BAN_DEV_MAINTENANCE_PASSWORD`, the publicly known
  password of the `maintenance` user on development images (log in on the console or with
  `ssh maintenance@<vm>`).
- `profile.env` also holds `BAN_DEV_GRUB_PASSWORD`, the password of GRUB user `ban` on
  development ISOs (menu editing and the Maintenance and Recovery entries).
- `package-lists/dev.list.chroot`: `openssh-server htop vim strace`.
- `configuration/`: files added to the image on top of `image/configuration/` and the variant's
  files. `etc/systemd/system/ssh.service.d/ban-hostkeys.conf` generates the SSH host keys at
  boot (live-build strips them from the image).

**Filled in:** Stage 0 (`profile.env`); package list, `maintenance` user and SSH in Stage 1.
