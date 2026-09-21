# config/

The three image profiles (plan part 1, step 0.6). Select one with `make build PROFILE=<profile>`.

| Profile | SSH | `maintenance` sudo | Ban Center devtools | Update channel | Log level | Default PIN | root |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `development` | on | full | yes | `dev` | DEBUG (*) | allowed | locked (*) |
| `staging` | off | whitelist | removed | `beta` | DEBUG | none | locked |
| `production` | off | whitelist | removed | `stable` | INFO (*) | none | locked |

(*) Not stated in the step 0.6 table; assumed. `root` is locked on every image per step 2.4.

Each profile folder holds:

- `profile.env`: build variables, sourced by `image/scripts/build-image.sh`.
- `package-lists/*.list.chroot` (optional): package lists added on top of `image/packages/`.
- override files (optional, from Stage 1): files that replace those in `image/configuration/`.

Rules: no secrets in any profile. No default PIN, password or key in `staging` and `production`;
their secrets are created on the device during provisioning (Stage 12).

**Filled in:** Stage 0 (`profile.env`). The variables are consumed from Stage 1 onward
(SSH and package lists in Stage 1, PIN in Stage 3, devtools in Stage 5, update channel in Stage 9).
