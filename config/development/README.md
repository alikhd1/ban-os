# config/development/

Developer image. **Never install it in a store.**

Differences from production: SSH on, user `maintenance` with full sudo, devtools enabled in
Ban Center, update channel `dev`, a well-known default technician PIN is allowed.

**Filled in:** Stage 0 (`profile.env`); package list (`openssh-server htop vim strace`) in Stage 1.
