# kiosk/display/

Display handling and boot splash of the `pos` variant (plan part 1, steps 2.5 and 2.6).

| File | Installed as | What |
| --- | --- | --- |
| `apply-display` | `/opt/ban/kiosk/apply-display` | applies `display.toml` with `xrandr` and `xinput`: primary output, mode, rotation, customer display (extended, never mirrored), touch mapping and calibration matrix. Logs and skips every problem |
| `display.toml` | `/etc/ban/display.toml` | default layout: everything `auto`, customer display off. Written by Ban Center from Stage 7 |
| `plymouth/ban/` | `/usr/share/plymouth/themes/ban/` | boot splash, see its README |

**Filled in:** Stage 2; touch calibration UI in Stage 7.
