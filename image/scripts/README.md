# image/scripts/

Build scripts and live-build hooks.

- `build-image.sh <profile>`: `lb clean` -> stage package lists -> `lb config` -> `lb build`,
  then moves the ISO to `out/ban-os-<version>-<profile>-amd64.iso`. Called by `make build`.

**Filled in:** Stage 0 (`build-image.sh`); hooks from Stage 1 onward.
