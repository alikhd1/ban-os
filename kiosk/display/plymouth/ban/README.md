# kiosk/display/plymouth/ban/

Plymouth theme `ban` of the `pos` variant (plan part 1, step 2.6), installed to
`/usr/share/plymouth/themes/ban/` and made the default by
`image/scripts/hooks/7040-ban-kiosk.hook.chroot`.

| File | What |
| --- | --- |
| `ban.plymouth`, `ban.script` | theme definition and layout script (logo centred, bar under it, "Powered by bans.ir" at the bottom, background `#101418`) |
| `logo.png` | the BAN mark (`bans-white.png` from the brand assets, 307x94). Replace it with a larger or "Ban OS" version when one exists; the script centres any size |
| `powered-by.png` | "Powered by bans.ir" rendered in Vazirmatn (OFL) at 22 px, `#9aa3ad`. Plymouth's script module cannot draw text without the pango label plugin, which would bloat the initramfs |
| `progress-bar.png`, `progress-box.png` | 1x1 pixels scaled to the bar (white, and white at 19% for the track) |
