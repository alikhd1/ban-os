# image/variants/pos/

The graphical POS variant: boots into Adad in a locked kiosk session; Ban Center for the
technician. Default variant of `make build`.

Content on top of the common image: Xorg, LightDM, Openbox, Plymouth, on-screen keyboard
(`kiosk.list.chroot`), CUPS, Chromium (`ban-browser`), fonts, Adad, `adad-launcher`,
Ban Center, `ban-hardware`. `ban-console` is installed too, as the Recovery UI only.

Package lists: `print` (CUPS), `fonts` (Vazirmatn, Noto), `browser` (Chromium); `kiosk` follows in
Stage 2.

**Filled in:** Stage 0 (`variant.env`); package lists in Stages 1 and 2.
