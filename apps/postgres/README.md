# apps/postgres/

PostgreSQL 17 configuration for the POS: cluster on the data partition, Unix socket only, `peer` auth, light tuning, first-boot role/database hook.

Both variants. The `server` variant sizes the tuning from the RAM at first boot and always runs
the Server role (LAN listen, TLS, `adad_client`).

**Filled in:** Stage 3 (step 3.2); Server/Client roles in Stages 11 and 12.
