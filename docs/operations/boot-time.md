# Boot time

Target (plan part 1, step 2.2): **kernel to Adad < 20 s** on an Intel N100 (`pos`); kernel to the
tty1 status screen for `server`. Until Adad arrives (Stage 3) the `pos` end point is the empty
Openbox session.

## How to measure

On the device, after a normal boot:

```bash
systemd-analyze                     # firmware / loader / kernel / userspace split
systemd-analyze blame | head -20    # slowest units
systemd-analyze critical-chain graphical.target   # pos; multi-user.target for server
journalctl -b -g SYSTEM_BOOT        # duration_s = uptime when multi-user.target was reached
```

Measure on real hardware or under KVM. Software emulation (a build VM without `/dev/kvm`) is
5 to 10 times slower and says nothing about the target.

## Results

| Date | Ban OS | Variant | Hardware | Firmware + loader | Kernel | Userspace | Total to session / status | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| | | `pos` | Intel N100 | | | | | |
| | | `server` | | | | | | |
