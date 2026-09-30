# image/variants/

The two image variants (plan part 1, step 0.8). Select one with
`make build PROFILE=<profile> VARIANT=<variant>`.

| Variant | What it is | Default target | Device roles | Management UI |
| --- | --- | --- | --- | --- |
| `pos` (default) | POS terminal: LightDM autologin, kiosk session, Adad, Ban Center | `graphical.target` | Standalone / Server / Client | Ban Center (Tauri, Persian RTL) |
| `server` | headless store server: PostgreSQL + Ban services, no X, no Adad UI | `multi-user.target` | Server only | `ban-console` (text UI on tty1) |

Variants and profiles are independent: any variant builds with any profile
(`development`, `staging`, `production`). Output:
`out/ban-os-<version>-<profile>-<variant>-amd64.iso`.

Each variant folder holds:

- `variant.env`: build variables, sourced by `image/scripts/build-image.sh`.
- `package-lists/*.list.chroot` (optional): package lists added on top of `image/packages/`.
- `configuration/` (optional, from Stage 1): files added on top of `image/configuration/`.

A package list name must be unique across `image/packages/`, the variant and the profile;
the build stops on a clash.

**Filled in:** Stage 0 (`variant.env`). Package lists from Stage 1 (step 1.2), the graphical
stack of `pos` in Stage 2, `ban-console` of `server` in Stage 5.
