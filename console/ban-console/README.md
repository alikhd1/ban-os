# console/ban-console/

Rust + `ratatui` text UI that runs on tty1 of the `server` variant as
`ban-console@tty1.service` (optionally `ban-console@ttyS0` for IPMI serial-over-LAN), and as
the Recovery UI (`ban-recovery.target`) of both variants.

- Status screen without PIN: hostname, `device_id`, IP, role, PostgreSQL, connected clients,
  last backup, alerts.
- Behind a PIN: network, services, logs and events, backup / restore, updates, users,
  pairing code, Support Bundle, reboot / shutdown, first-boot wizard.
- English text: the Linux console cannot shape or reorder Persian script.
- Becomes a Cargo workspace member in Stage 5.

**Filled in:** Stage 5 (plan part 2, step 5.10).
