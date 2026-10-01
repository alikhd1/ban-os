# kiosk/maintenance/

Entry to Maintenance mode and the boot failure screen.

| File | Installed as | What |
| --- | --- | --- |
| `ban-bootfail` | `/opt/ban/kiosk/ban-bootfail` | error screen on tty1 (`E-GFX-01`) when LightDM failed 3 times in 60 s (`lightdm.service` `OnFailure=`); records `GRAPHICS_FAILED`; `M` opens the console login of `maintenance` |

The screen is English only: the Linux console cannot shape or reorder Persian script.

**Filled in:** Stage 2 (`ban-bootfail`); Stage 3 (step 3.7): hidden gesture, PIN dialog and the
temporary restricted terminal, which also replaces the plain login of `ban-bootfail`. Ban Center
replaces the terminal in Stage 5.
