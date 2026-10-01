# image/variants/server/

The headless server variant: a store server (physical or VM) that serves the Adad database to
the POS clients of the store. No X, no Adad UI, no Ban Center; `ban-console` on tty1 (and
optionally on the serial console) is the management UI.

Content on top of the common image: `ban-console`, the VM guest agents `qemu-guest-agent`,
`open-vm-tools` and `hyperv-daemons` (each starts only on its own hypervisor), UPS monitoring
(`nut`, Stage 8), PostgreSQL tuning from the RAM size (Stage 3), `adad-db` for the database
schema instead of the Adad application.

Package lists: `server` (`qemu-guest-agent`, `open-vm-tools`, `hyperv-daemons`).

**Filled in:** Stage 0 (`variant.env`); package lists in Stage 1; `ban-console` in Stage 5.
