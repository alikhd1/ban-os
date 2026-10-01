# Test hardware

Devices Ban OS is tested on (plan part 1, step 1.7; full-chat §32). Fill in model, BIOS/UEFI
version and the last Ban OS version that passed when a device joins the test pool.

## pos variant

| Class | Example | Model | Firmware | Last passing version | Notes |
| --- | --- | --- | --- | --- | --- |
| Intel N100 mini PC | | | | | weakest target CPU; boot-time and RAM measurements (Stages 2, 5) |
| AMD mini PC | | | | | |
| Generic mini PC | | | | | |
| Touch POS terminal | | | | | touch calibration, customer display (Stages 2, 8) |

## server variant

| Class | Example | Model | Firmware | Last passing version | Notes |
| --- | --- | --- | --- | --- | --- |
| Mini PC or small server, two NICs | | | | | store server on real hardware |
| VM on KVM / Proxmox | | | | | `qemu-guest-agent` |
| VM on VMware ESXi or Hyper-V | | | | | `open-vm-tools` / `hyperv-daemons` |

## Virtual

| Environment | Notes |
| --- | --- |
| QEMU + OVMF on the build VM (`make run-vm`, `make test-boot`) | every build; without `/dev/kvm` it runs in software emulation |
