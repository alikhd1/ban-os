# agent/ban-agent/

Rust daemon (tokio, zbus, rusqlite). JSON-RPC over the Unix socket `/run/ban/agent.sock`, peer authentication, controllers (System, Network, Service, Hardware, Log, Update, Recovery, Permission) and root helpers.

**Filled in:** Stage 4 (skeleton, read-only methods); extended in Stages 6 to 11. Stage 0 only prints its version.
