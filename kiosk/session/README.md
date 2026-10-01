# kiosk/session/

The graphical session of the `pos` variant (plan part 1, steps 2.4 and 2.5). Installed by
`image/variants/pos/files.list`.

| File | Installed as | What |
| --- | --- | --- |
| `ban-session` | `/opt/ban/kiosk/ban-session` | screen never blanks, root colour `#101418`, `apply-display`, `unclutter`, starts the user target `ban-session.target`, then `exec openbox` |
| `ban.desktop` | `/usr/share/xsessions/ban.desktop` | the `ban` session LightDM logs into |
| `lightdm/50-ban.conf` | `/etc/lightdm/lightdm.conf.d/50-ban.conf` | autologin of `adad` into `ban`, no greeter, no guest, X without TCP |
| `openbox/rc.xml` | `/etc/ban/openbox/rc.xml` | one desktop, no menus, no key or mouse bindings |

The pointer is not disabled in X (`-nocursor`); `unclutter --hide-on-touch` hides it when idle or
touched, so devices with a mouse stay usable.

**Filled in:** Stage 2; kiosk lock-down (Xorg `DontVTSwitch`/`DontZap`, window rules in `rc.xml`)
in Stage 3 (step 3.5).
