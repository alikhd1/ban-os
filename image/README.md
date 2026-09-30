# image/

Everything needed to build the Ban OS image.

- `live-build/`: live-build working directory.
- `packages/`: package lists common to both variants.
- `variants/`: the `pos` and `server` variants (their own package lists and files).
- `configuration/`: files copied into the root filesystem of every image.
- `scripts/`: `build-image.sh` and build hooks.

**Filled in:** Stage 0 (minimal), Stage 1 (real image).
