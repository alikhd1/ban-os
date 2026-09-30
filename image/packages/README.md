# image/packages/

Package lists (`*.list.chroot`) common to all profiles and both variants (`pos`, `server`).
`image/scripts/build-image.sh` stages them into `image/live-build/config/package-lists/`,
together with the lists of the selected variant (`image/variants/<variant>/package-lists/`) and
profile (`config/<profile>/package-lists/`).

Only what both variants need belongs here. Graphical, printing, browser and font packages go to
`image/variants/pos/package-lists/`.

**Filled in:** Stage 1 (step 1.2); `kiosk.list.chroot` goes to the `pos` variant in Stage 2.
