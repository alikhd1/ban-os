نقشه اجرایی تفصیلی Ban OS — بخش ۱

مراحل ۰ تا ۴: آماده‌سازی، پایه OS، Boot، محیط POS، سرویس‌ها و Ban Agent

پوشش: OS-01، OS-02، OS-03، OS-04 از «plan p1» + تصمیم‌های «full-chat»

قالب هر مرحله: هدف ← پوشش اقلام p1/p2 ← فایل‌هایی که ساخته می‌شوند ← گام‌های تفصیلی ← رویدادها ← تست‌ها ← معیار پذیرش ← خروجی.

دو Variant (گام ۰.۸): `pos` (صندوق گرافیکی) و `server` (سرور فروشگاه بدون UI گرافیکی). هر مرحله که در `server` فرق دارد، بخش «Variant server» دارد؛ بقیه برای هر دو یکسان است.

---

# مرحله ۰ — آماده‌سازی

## هدف

محیط Build، مخزن و قراردادهای پروژه پیش از نوشتن هر جزء آماده شود.

## پوشش

OS-01: «ساختار مخزن Ban OS»، «محیط تست مجازی»، «نسخه‌بندی و مستندسازی» · p1: «ساختار پیشنهادی پروژه» و پوشه `config/{development,staging,production}`.

## گام ۰.۱ — VM Build

| مورد | مقدار |
| --- | --- |
| سیستم‌عامل | Debian 13 (trixie) amd64، نصب minimal |
| منابع | ≥ ۴ core، ۸GB RAM، ۸۰GB دیسک |
| مجازی‌سازی | nested virtualization روشن (برای QEMU/KVM داخل VM)؛ بررسی با `ls /dev/kvm` |
| دسترسی | SSH از Windows؛ مخزن روی VM clone می‌شود، ویرایش با VS Code Remote-SSH |

## گام ۰.۲ — ابزارها

```
# Image
apt install live-build debootstrap squashfs-tools xorriso grub-efi-amd64-bin \
            mtools dosfstools qemu-system-x86 qemu-utils ovmf git make debhelper devscripts

# Agent / Center
curl https://sh.rustup.rs | sh            # stable toolchain
apt install nodejs npm && npm i -g pnpm
apt install libwebkit2gtk-4.1-dev libgtk-3-dev libayatana-appindicator3-dev librsvg2-dev \
            libssl-dev libsqlite3-dev libdbus-1-dev pkg-config
cargo install cargo-deb tauri-cli
```

## گام ۰.۳ — mirror محلی apt

- `apt-cacher-ng` روی VM (پورت 3142) یا mirror کامل با `apt-mirror` برای trixie + trixie-security + non-free-firmware.
- live-build فقط به این mirror اشاره می‌کند ← Build در قطعی اینترنت/فیلترینگ هم کار می‌کند و تکرارپذیر است.
- snapshot تاریخ‌دار mirror برای هر Release نگه‌داری شود (بازتولید Image قدیمی).

## گام ۰.۴ — ساختار مخزن

همان ساختار p1، با افزوده‌های این پروژه (`crates/`، `apps/`، `Cargo.toml` ریشه):

```
ban-os/
├── README.md · LICENSE · VERSION · CHANGELOG.md · CONTRIBUTING.md
├── Makefile
├── Cargo.toml                    ← workspace
├── crates/
│   └── ban-api-types/            ← قرارداد مشترک Agent ↔ Center
├── agent/ban-agent/              ← Rust
├── event/                        ← ban-event (Rust)
│   ├── audit/ · system-events/ · storage/
├── center/ban-center/            ← Tauri 2 + React
├── console/ban-console/          ← رابط متنی Variant server و Recovery (Rust + ratatui)
├── launcher/adad-launcher/       ← Python/PyQt (هم‌خانواده Adad)
├── hardware/                     ← ban-hardware + adapterها
│   ├── printer/ scanner/ cash-drawer/ customer-display/ scale/ payment-terminal/
├── updater/  client/ manifest/ verification/
├── recovery/ backup/ restore/ rollback/
├── security/ policies/ permissions/ hardening/
├── services/systemd/             ← همه unitها و قالب استاندارد
├── installer/ provisioning/ first-boot/ factory-setup/
├── image/
│   ├── live-build/               ← auto/ و config/
│   ├── packages/                 ← *.list.chroot
│   ├── variants/                 ← pos/ و server/: variant.env، package-list و فایل‌های هر Variant
│   ├── configuration/            ← فایل‌هایی که وارد / می‌شوند
│   └── scripts/                  ← hookها و build-image.sh
├── kiosk/ session/ display/ maintenance/
├── apps/                         ← برنامه‌های همراه: postgres/ browser/ tech-tools/
├── tests/ integration/ hardware/ boot/ reliability/
├── docs/ architecture/ operations/ security/ release/
└── config/ development/ staging/ production/
```

اصل p1: «برخی اجزا در ابتدا در یک مخزن؛ در صورت نیاز بعداً مستقل شوند.» مخزن `adad-pos` جداست و در Build نسخه مشخصی از `.deb` آن وارد Image می‌شود.

## گام ۰.۵ — Makefile

| هدف | کار |
| --- | --- |
| `make debs` | ساخت همه `.deb`های Ban (agent، event، center، launcher، hardware، updater) در `out/debs/` |
| `make build PROFILE=development VARIANT=pos` | `lb clean` → `lb config` → `lb build`؛ خروجی `out/ban-os-<ver>-<profile>-<variant>-amd64.iso` |
| `make run-vm` | QEMU + OVMF + دیسک مجازی ۳۲GB (یکی برای هر Variant) + صفحه 1024×768 (اندازه رایج POS) |
| `make test-boot` | بوت headless و انتظار برای نشانه موفقیت روی serial |
| `make clean` | پاک‌سازی chroot و cache |

## گام ۰.۶ — سه Profile

| Profile | تفاوت |
| --- | --- |
| `development` | SSH روشن، کاربر `maintenance` با sudo کامل، devtools در Ban Center، کانال آپدیت `dev`، PIN پیش‌فرض |
| `staging` | مثل production ولی کانال `beta` و سطح لاگ DEBUG |
| `production` | SSH خاموش، root قفل، devtools حذف، کانال `stable`، بدون هیچ Secret یا PIN پیش‌فرض |

هر Profile = یک پوشه در `config/<profile>/` شامل package-list افزوده، فایل‌های override و متغیرهای build.

## گام ۰.۷ — قراردادها

- نسخه‌ها (full-chat §35): `OS_VERSION`، `APP_VERSION`، `AGENT_API_VERSION`، `HARDWARE_API_VERSION`؛ همه SemVer؛ فایل `/etc/ban/release` روی دستگاه همه را دارد.
- نام سرویس‌ها: `ban-agent`، `ban-event`، `ban-sync`، `ban-update`، `ban-hardware`، `adad`، `adad-launcher`.
- نام Image: `ban-os-1.0.0-pos-amd64.iso` و `ban-os-1.0.0-server-amd64.iso` / `.img.zst`؛ نام بسته‌ها: `ban-agent_1.0.0_amd64.deb`.
- شاخه‌ها: `main` (پایدار)، `develop`، `feature/*`، `release/*`؛ tag = `os-v1.0.0`، `center-v1.0.0`.

## گام ۰.۸ — دو Variant: `pos` و `server`

| Variant | چیست | `default.target` | نقش‌های دستگاه | رابط تکنسین |
| --- | --- | --- | --- | --- |
| `pos` (پیش‌فرض) | صندوق فروش: LightDM autologin، Kiosk، Adad، Ban Center | `graphical.target` | Standalone / Server / Client | Ban Center |
| `server` | سرور فروشگاه بدون UI گرافیکی: PostgreSQL + سرویس‌های Ban، روی سخت‌افزار سرور یا VM | `multi-user.target` | فقط Server | `ban-console` (متنی، tty1) |

- Variant مستقل از Profile است: Profile می‌گوید Image چقدر قفل است، Variant می‌گوید Image چیست. هر ترکیبی مجاز است: `make build PROFILE=<profile> VARIANT=<pos|server>`.
- هر Variant = یک پوشه در `image/variants/<variant>/`: `variant.env` (`BAN_VARIANT`، `BAN_DEFAULT_TARGET`، `BAN_DEVICE_ROLES`)، package-list افزوده، فایل‌های افزوده (از مرحله ۱).
- package-listها از سه منبع جمع می‌شوند: `image/packages/` (مشترک) + `image/variants/<variant>/package-lists/` + `config/<profile>/package-lists/`؛ نام تکراری بین این سه = توقف Build.
- خروجی: `out/ban-os-<ver>-<profile>-<variant>-amd64.iso`؛ `make run-vm` برای هر Variant دیسک جدا دارد (`out/disk-<variant>.qcow2`).
- هر دو Variant یک `OS_VERSION` دارند و همیشه با هم منتشر می‌شوند؛ روی دستگاه `OS_VARIANT` در `/etc/ban/release` نوشته می‌شود (گام ۱.۳).
- چرا دو ISO و نه یک ISO با گزینه «بدون UI»: live-build بسته‌ها را هنگام Build نصب می‌کند؛ ISO مشترک یعنی Xorg، LightDM، Chromium و WebKitGTK روی سرور هم هستند.

## معیار پذیرش

`make build PROFILE=development` برای هر دو Variant روی VM بدون اینترنت خارجی اجرا و دو ISO (حتی خالی) تولید می‌شود.

---

# مرحله ۱ — پایه سیستم‌عامل (OS-01)

## هدف

«ساخت پایه قابل بوت و قابل توسعه Ban OS بر اساس Debian، به همراه ساختار پروژه، محیط Build، مدیریت نسخه و محیط تست.» (p1)

## پوشش اقلام OS-01

| قلم p1 | گام |
| --- | --- |
| انتخاب نسخه پایه Debian | ۱.۱ |
| ساختار مخزن | مرحله ۰ |
| تنظیمات اولیه سیستم | ۱.۳، ۱.۴، ۱.۵ |
| مدیریت پکیج‌ها | ۱.۲ |
| فرآیند Build Image | ۱.۱، ۱.۶ |
| محیط تست مجازی و سخت‌افزاری | ۱.۷ |
| نسخه‌بندی و مستندسازی | ۱.۸ |

## گام ۱.۱ — live-build config

`image/live-build/auto/config`:

```
lb config noauto \
  --distribution trixie --architectures amd64 \
  --archive-areas "main contrib non-free non-free-firmware" \
  --mirror-bootstrap http://127.0.0.1:3142/deb.debian.org/debian \
  --mirror-chroot    http://127.0.0.1:3142/deb.debian.org/debian \
  --binary-images iso-hybrid --bootloaders grub-efi \
  --debian-installer none \
  --apt-recommends false --firmware-chroot true \
  --iso-application "Ban OS" --iso-volume "BANOS" \
  "${@}"
```

ساختار (full-chat §33): `config/package-lists/` · `includes.chroot/` · `includes.binary/` · `hooks/` · `bootloaders/`. `--apt-recommends false` برای سبک‌ماندن Image حیاتی است.

## گام ۱.۲ — package-listها (`image/packages/`)

| فایل | محتوا | Variant |
| --- | --- | --- |
| `base.list.chroot` | `linux-image-amd64 systemd systemd-sysv systemd-timesyncd dbus udev sudo ca-certificates` | همه |
| `firmware.list.chroot` | `firmware-linux firmware-linux-nonfree firmware-realtek firmware-iwlwifi firmware-misc-nonfree intel-microcode amd64-microcode` | همه |
| `network.list.chroot` | `network-manager wpasupplicant iw rfkill nftables` | همه |
| `print.list.chroot` | `cups cups-filters` | `pos` |
| `locale.list.chroot` | `locales tzdata keyboard-configuration` | همه |
| `fonts.list.chroot` | `fonts-vazirmatn fonts-noto-core` (اگر `fonts-vazirmatn` در trixie نبود، فونت از `includes.chroot/usr/share/fonts/` وارد شود — مجوز OFL) | `pos` |
| `postgres.list.chroot` | `postgresql-17 postgresql-client-17` | همه |
| `browser.list.chroot` | `chromium` | `pos` |
| `diag.list.chroot` | `smartmontools usbutils pciutils lm-sensors` | همه |
| `server.list.chroot` | `qemu-guest-agent open-vm-tools hyperv-daemons` (هر کدام فقط روی hypervisor خودش فعال می‌شود؛ برای نصب سرور به‌صورت VM) | `server` |
| `dev.list.chroot` (فقط development) | `openssh-server htop vim strace` | همه |

ستون Variant: «همه» در `image/packages/`؛ `pos` و `server` در `image/variants/<variant>/package-lists/`؛ `dev.list.chroot` در `config/development/package-lists/`. فونت‌ها در `server` لازم نیستند چون کنسول متنی فارسی را رندر نمی‌کند و رسید چاپ نمی‌شود.

آنچه **نصب نمی‌شود** (اصل full-chat: «نه GNOME، نه KDE، نه Desktop کامل»): هیچ desktop environment، file manager، terminal emulator، office، avahi، bluetooth (مگر سخت‌افزار هدف لازم داشته باشد).

## گام ۱.۳ — تنظیمات اولیه (`image/configuration/` → `includes.chroot`)

| فایل | مقدار |
| --- | --- |
| `/etc/hostname` | `ban-os` (در Provisioning به `ban-<device_id>` تغییر می‌کند) |
| `/etc/locale.gen` | `fa_IR.UTF-8` و `en_US.UTF-8`؛ پیش‌فرض سیستم `en_US.UTF-8` (لاگ‌ها انگلیسی)، UI فارسی در خود برنامه‌ها |
| `/etc/timezone` | `Asia/Tehran` |
| `/etc/default/keyboard` | `XKBLAYOUT="us,ir"` `XKBOPTIONS="grp:alt_shift_toggle"` |
| `/etc/systemd/journald.conf.d/ban.conf` | `Storage=persistent` `SystemMaxUse=200M` `MaxRetentionSec=1month` `Compress=yes` |
| `/etc/ban/release` | `OS_VERSION=…`، `OS_VARIANT=pos` یا `server` و بقیه نسخه‌ها (در build پر می‌شود) |

## گام ۱.۴ — زمان

- `systemd-timesyncd` با `NTP=` سرورهای قابل دسترس در ایران + fallback؛ `/etc/systemd/timesyncd.conf.d/ban.conf`.
- unit `ban-clock-check.service` در بوت: اگر سال سیستم < سال Build ← رویداد `CLOCK_INVALID` (WARNING) و هشدار در Launcher. دلیل: باتری RTC مرده = تاریخ فاکتور غلط.

## گام ۱.۵ — دوام دیسک (SSD/eMMC ارزان)

- fstab: `noatime,commit=30` روی root و data.
- tmpfs برای `/tmp` و `/var/tmp`.
- `fstrim.timer` فعال.
- سقف journald (۱.۳) و logrotate برای `/var/log/adad`.

## گام ۱.۶ — دایرکتوری‌های Ban (full-chat §36، با نام Ban)

```
/opt/adad/            bin/ lib/ plugins/ resources/
/opt/ban/             agent/ center/ hardware/ updater/ browser/
/etc/adad/            config.toml
/etc/ban/             release · *.toml (مرحله ۴) 
/var/lib/adad/        sync/ cache/ backups/
/var/lib/ban/         audit.db · metrics.db · backups/ · outbox/
/var/lib/postgresql/  ← روی پارتیشن داده
/var/log/adad/
/run/ban/             agent.sock · event.sock
```

اصل full-chat §5: «Data را از OS جدا کن» — هرچه زیر `/var/lib` است در OS update دست‌نخورده می‌ماند.

## گام ۱.۷ — تست

- `make run-vm`: `qemu-system-x86_64 -enable-kvm -m 4096 -smp 2 -bios /usr/share/OVMF/OVMF_CODE.fd -cdrom out/*.iso -drive file=out/disk-<variant>.qcow2,if=virtio -serial stdio -vga virtio`
- `make test-boot`: بوت headless؛ سرویس `ban-boot-ok.service` بعد از `multi-user.target` رشته `BAN-BOOT-OK <version>` را روی `ttyS0` می‌نویسد؛ اسکریپت تا ۱۲۰ ثانیه منتظر می‌ماند.
- CI (self-hosted runner روی همان VM): هر push → `make debs` و سپس `make build test-boot` برای هر دو Variant (`VARIANT=pos` و `VARIANT=server`).
- فهرست سخت‌افزار تست (full-chat §32): Intel N100، AMD، mini PC، touch POS — جدول در `docs/operations/test-hardware.md`.
- سخت‌افزار تست Variant server: یک mini PC یا سرور کوچک با دو NIC، و VM روی KVM/Proxmox و حداقل یک hypervisor دیگر (VMware ESXi یا Hyper-V).

## گام ۱.۸ — مستندات

`docs/architecture/build.md` (چگونه Build کنیم)، `docs/architecture/layout.md` (دایرکتوری‌ها و پارتیشن‌ها)، `CHANGELOG.md` با قالب Keep a Changelog.

## معیار پذیرش

هر دو ISO در QEMU/UEFI بوت می‌شوند · `timedatectl` = Asia/Tehran و NTP فعال · `pg_lsclusters` = online · `make test-boot` برای هر دو Variant سبز · حجم هر ISO ثبت می‌شود (هدف: `pos` < ۱٫۲GB، `server` < ۸۰۰MB).

## خروجی

«یک Image اولیه که بوت می‌شود و به‌عنوان پایه فازهای بعدی قابل استفاده است.» (p1)

در این مرحله دو Variant فقط در package-listها فرق دارند؛ خروجی `server` تقریباً همان پایه نهایی سرور است.

---

# مرحله ۲ — Boot & Login (OS-02)

## هدف

«ایجاد فرآیند بوت اختصاصی Ban OS و آماده‌سازی ورود خودکار به محیط گرافیکی.» (p1)

## پوشش اقلام OS-02

| قلم p1 | گام |
| --- | --- |
| Bootloader | ۲.۱ |
| Kernel و پارامترهای بوت | ۲.۱ |
| systemd boot sequence | ۲.۲ |
| مدیریت Login | ۲.۴ |
| محیط گرافیکی پایه | ۲.۳ |
| مدیریت نشست کاربر | ۲.۵ |
| صفحه Boot و وضعیت راه‌اندازی | ۲.۶ |
| کنترل خطاهای هنگام بوت | ۲.۷ |

## جریان هدف (p1 «جریان کلی راه‌اندازی» + full-chat §7)

```
Power ON → UEFI → GRUB → Kernel → systemd
   ├── Hardware Init (udev) ├── NetworkManager ├── ban-event ├── ban-agent ├── postgresql
   ▼
graphical.target → LightDM (autologin adad) → Openbox → ban-session → adad-launcher → Adad POS
```

## گام ۲.۱ — GRUB و Kernel

`/etc/default/grub.d/ban.cfg`:

```
GRUB_TIMEOUT_STYLE=hidden
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR="Ban OS"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 vt.global_cursor_default=0 panic=10"
GRUB_DISABLE_RECOVERY=true
GRUB_DISABLE_OS_PROBER=true
```

سه ورودی در `/etc/grub.d/40_ban` (full-chat §15):

| ورودی | پارامتر kernel | نتیجه |
| --- | --- | --- |
| Ban OS | — | مسیر عادی POS |
| Ban OS — Maintenance | `ban.mode=maintenance` | بعد از autologin به‌جای Adad، صفحه PIN و Ban Center |
| Ban OS — Recovery | `ban.mode=recovery systemd.unit=ban-recovery.target` | محیط Recovery (مرحله ۱۰) |

- نمایش منو: نگه‌داشتن F12 (یا Esc/Shift) هنگام بوت؛ متن «Press F12 for Maintenance» در Plymouth.
- منوی GRUB با رمز محافظت می‌شود (`set superusers` + `password_pbkdf2`)؛ ورودی پیش‌فرض `--unrestricted` است. ویرایش پارامترها بدون رمز ممکن نیست (جلوگیری از `init=/bin/sh`).
- `panic=10`: kernel panic → reboot خودکار.

## گام ۲.۲ — systemd boot sequence

- `default.target = graphical.target`.
- mask: `getty@tty2..6`، `apt-daily*.timer` (آپدیت فقط از `ban-update`)، `ModemManager`، `e2scrub_all.timer`.
- `NetworkManager-wait-online` غیرفعال (بوت نباید منتظر شبکه بماند — اصل Offline-first در full-chat §8).
- هدف زمانی: kernel تا Adad < ۲۰ثانیه روی N100؛ اندازه‌گیری با `systemd-analyze blame` و ثبت در `docs/operations/boot-time.md`.

## گام ۲.۳ — محیط گرافیکی پایه

`kiosk.list.chroot`: `xserver-xorg-core xserver-xorg-input-libinput xserver-xorg-video-all xinit x11-xserver-utils lightdm openbox unclutter-xfixes onboard plymouth plymouth-themes xinput-calibrator`

چرا Xorg و نه Wayland: سازگاری PyQt فعلی Adad، `xrandr`/`xinput` برای touch و چرخش، و سازگاری بهتر RustDesk در آینده (Ban Desk).

## گام ۲.۴ — Login (full-chat §8)

`/etc/lightdm/lightdm.conf.d/50-ban.conf`:

```INI
[Seat:*]
autologin-user=adad
autologin-user-timeout=0
autologin-session=ban
user-session=ban
greeter-hide-users=true
allow-guest=false
xserver-command=X -nocursor -nolisten tcp
```

`/usr/share/xsessions/ban.desktop` → `Exec=/opt/ban/kiosk/ban-session`.

کاربران (full-chat §6):

| کاربر | shell | گروه‌ها | نقش |
| --- | --- | --- | --- |
| `root` | — | — | رمز قفل (`passwd -l`)؛ فقط از Recovery/‏sudo |
| `adad` | `/usr/sbin/nologin` | `ban-ipc` `lp` `dialout` `input` `video` | صاحب session گرافیکی؛ Adad و Ban Center زیر همین کاربر اجرا می‌شوند و هیچ‌کدام دسترسی privileged ندارند |
| `maintenance` | `/bin/bash` | `ban-ipc` `sudo` (whitelist) | ترمینال تکنسین، SSH در development |
| `ban-agent` | nologin | سیستم | اجرای Agent با capabilityهای محدود |

## گام ۲.۵ — مدیریت نشست: `ban-session`

`/opt/ban/kiosk/ban-session` (shell):

```
xset s off -dpms s noblank                 # صفحه هرگز خاموش نشود
xsetroot -solid "#101418"
/opt/ban/kiosk/apply-display               # xrandr از /etc/ban/display.toml
unclutter-xfixes --timeout 1 --touch &      # مخفی‌شدن cursor
systemctl --user import-environment DISPLAY XAUTHORITY
systemctl --user start ban-session.target   # adad-launcher / ban-center
exec openbox --config-file /etc/ban/openbox/rc.xml
```

`import-environment` همان مشکلی را حل می‌کند که full-chat §10 گفته بود: «برای Production باید Environment مربوط به Xauthority/session را صحیح مدیریت کنیم.»

`apply-display`: رزولوشن، چرخش (`xrandr --rotate`)، نقشه‌برداری touch به نمایشگر اصلی (`xinput map-to-output`)، نمایشگر دوم مشتری (extend، نه mirror)، ماتریس کالیبره. منبع: `/etc/ban/display.toml`.

## گام ۲.۶ — صفحه Boot

Plymouth theme `ban` در `kiosk/display/plymouth/`: لوگوی Ban OS، نوار پیشرفت، متن «Powered by Adad»، پس‌زمینه هم‌رنگ `xsetroot` تا انتقال Plymouth → X بدون پرش باشد. (full-chat: «کاربر اصلاً حس نمی‌کند یک Debian پشت سیستم است.»)

## گام ۲.۷ — کنترل خطای بوت

| خطا | رفتار |
| --- | --- |
| X بالا نیاید (۳ بار در ۶۰ث) | LightDM متوقف ← `ban-bootfail.service` روی tty1: متن فارسی/انگلیسی خطا، کد خطا، «برای Maintenance کلید M» (با PIN) · رویداد `GRAPHICS_FAILED` |
| fsck خطا بدهد | تعمیر خودکار (`fsck.repair=yes`)؛ اگر نشد → Recovery target |
| kernel panic | reboot بعد از ۱۰ث؛ شمارنده بوت ناموفق در `/var/lib/ban/bootcount`؛ ۳ بار پیاپی → ورودی Recovery |
| پارتیشن داده mount نشود | Launcher صفحه خطا می‌دهد، Adad اجرا نمی‌شود (هرگز روی root داده ننویسد) |

## Variant server

| گام | در `server` |
| --- | --- |
| ۲.۱ GRUB | همان تنظیمات، با دو ورودی «Ban OS» و «Recovery» (ورودی Maintenance لازم نیست چون کنسول همیشه پشت PIN است)؛ بدون `splash`؛ `console=tty0 console=ttyS0,115200n8` تا kernel و `ban-console` روی IPMI serial-over-LAN هم دیده شوند؛ GRUB با `terminal_output console serial` |
| ۲.۲ systemd | `default.target = multi-user.target`؛ همان maskها؛ `getty@tty1` در مرحله ۵ با `ban-console@tty1.service` جایگزین می‌شود؛ tty2 تا tty6 بسته |
| ۲.۳ تا ۲.۶ | ندارد: بدون Xorg، LightDM، Openbox و Plymouth |
| کاربران | `root` (قفل)، `maintenance`، `ban-agent`، `ban-console`؛ کاربر `adad` ساخته نمی‌شود |
| ۲.۷ خطای بوت | fsck، kernel panic، bootcount و پارتیشن داده مثل `pos`؛ ردیف X ندارد |

تا مرحله ۵، tty1 فقط صفحه وضعیت متنی نشان می‌دهد: `getty@tty1` با `/etc/issue` اختصاصی (نسخه Ban OS، hostname، IP با `\4`). ورود از آن فقط در Profile `development` و برای کاربر `maintenance` ممکن است.

زمان بوت: kernel تا صفحه وضعیت، ثبت در `docs/operations/boot-time.md` کنار `pos`.

معیار پذیرش server: Power on → صفحه وضعیت روی tty1 و serial، بدون ورودی دستی · هیچ بسته Xorg نصب نیست (`dpkg -l 'xserver-*'` خالی) · F12 منوی GRUB را نشان می‌دهد و ویرایش آن رمز می‌خواهد.

## رویدادها

`SYSTEM_BOOT` (با مدت بوت و دلیل reboot قبلی)، `SYSTEM_SHUTDOWN`، `SYSTEM_REBOOT`، `SYSTEM_CRASH` (بوت بعد از خاموشی ناسالم)، `GRAPHICS_FAILED`، `CLOCK_INVALID`.

## معیار پذیرش

Power on → لوگو → session خالی، بدون ورودی دستی · F12 منو را نشان می‌دهد و ویرایش آن رمز می‌خواهد · قطع عمدی درایور گرافیک → صفحه `ban-bootfail` · `Ctrl+Alt+F3` کار نمی‌کند (تکمیل در مرحله ۳).

## خروجی

«پس از روشن شدن دستگاه، سیستم بدون نیاز به ورود دستی وارد محیط تعیین‌شده Ban OS می‌شود.» (p1)

---

# مرحله ۳ — محیط POS (OS-03)

## هدف

«ایجاد محیط اختصاصی برای اجرای Adad POS به‌عنوان برنامه اصلی دستگاه، با امکان دسترسی کنترل‌شده به بخش مدیریت و تعمیرات.» (p1)

## پوشش اقلام OS-03

| قلم p1 | گام |
| --- | --- |
| Adad Launcher | ۳.۳ |
| اجرای خودکار Adad | ۳.۴ |
| محیط Kiosk | ۳.۵ |
| کنترل خروج از برنامه | ۳.۵، ۳.۷ |
| راه‌اندازی مجدد خودکار | ۳.۴ |
| مدیریت Crash نرم‌افزار | ۳.۴ |
| حالت عادی POS / حالت Maintenance | ۳.۷ |
| تفکیک دسترسی صندوق‌دار و تکنسین | ۳.۷ |

## گام ۳.۱ — `adad-dummy`

برنامه PyQt تمام‌صفحه برای تست زیرساخت پیش از آماده‌شدن بسته Adad: دکمه‌های «Crash» (exit 1)، «Hang» (حلقه بی‌نهایت — برای تست watchdog)، «اتصال DB»، «چاپ تست»، «درخواست Maintenance». بسته `adad-dummy.deb` که `Provides: adad-pos` دارد.

## گام ۳.۲ — PostgreSQL

| مورد | مقدار |
| --- | --- |
| cluster | `17/main`، data در `/var/lib/postgresql` (پارتیشن داده) |
| اتصال | فقط Unix socket: `listen_addresses = ''` (در نقش Standalone) |
| احراز هویت | `pg_hba.conf`: `local adad adad peer` — بدون رمز در فایل‌ها |
| DB و نقش | hook اولین بوت: `createuser adad` · `createdb -O adad adad` |
| tuning (۴GB RAM) | `shared_buffers=256MB` `work_mem=8MB` `max_connections=30` `wal_compression=on` `checkpoint_timeout=15min` `synchronous_commit=on` (داده مالی — خاموش نشود) |
| سلامت | `postgresql@17-main.service` با `Restart=on-failure`؛ رویدادهای `DATABASE_STARTED` / `DATABASE_ERROR` |

نقش‌های Server/Client در مرحله ۱۲ و firewall آن در مرحله ۱۱.

## گام ۳.۳ — `adad-launcher` (full-chat §11)

وظیفه (p1: «بررسی شرایط اجرا و راه‌اندازی Adad»):

| بررسی | روش | در صورت خطا |
| --- | --- | --- |
| Configuration | وجود و parse شدن `/etc/adad/config.toml` و `/etc/ban/device.toml` | خطا + Maintenance |
| Database | `pg_isready` تا ۳۰ث، سپس `SELECT 1`؛ در نقش Client اتصال به Server | Retry / Maintenance؛ پیام «اتصال به صندوق سرور برقرار نیست» |
| Storage | پارتیشن داده mount و > ۵٪ خالی | هشدار؛ زیر ۱٪ توقف |
| Hardware | پرسش از `ban-hardware` (از مرحله ۸)؛ چاپگر پیش‌فرض | **فقط هشدار** — نبودن چاپگر نباید فروش را متوقف کند |
| License / Device | وجود `device_id` و وضعیت فعال‌سازی (از مرحله ۱۲) | صفحه فعال‌سازی |
| Clock | نتیجه `ban-clock-check` | هشدار |
| Network | وضعیت NM | فقط نمایش (Offline-first) |

UI (همان طرح full-chat):

```
Ban OS
Database       ✓
Printer        ⚠  در دسترس نیست
License        ✓
Configuration  ✓
Network        ✓
در حال اجرای عدد...          [تلاش مجدد] [تعمیرات]
```

هر اجرا رویداد `LAUNCHER_CHECK` با نتیجه هر بررسی ثبت می‌کند. همین بررسی‌ها بعداً Health Check بعد از آپدیت می‌شوند (مرحله ۹).

## گام ۳.۴ — سرویس‌ها (user unit زیر session کاربر `adad`)

`~/.config/systemd/user/` از `/etc/skel` یا `/usr/lib/systemd/user/`:

```INI
# ban-session.target
[Unit]
Description=Ban OS graphical session
Wants=adad-launcher.service

# adad-launcher.service
[Unit]
Description=Adad Launcher
PartOf=ban-session.target
ConditionKernelCommandLine=!ban.mode=maintenance
Conflicts=ban-center.service
[Service]
ExecStart=/opt/ban/launcher/adad-launcher
Restart=always
RestartSec=2
WatchdogSec=60            # Launcher/Adad باید sd_notify WATCHDOG=1 بدهد → تشخیص Hang
StartLimitIntervalSec=120
StartLimitBurst=5
```

- Launcher خودش Adad را به‌صورت child اجرا و exit code را گزارش می‌کند: `ADAD_STARTED`، `ADAD_STOPPED` (کد ۰)، `ADAD_CRASHED` (کد ≠۰ یا signal)، `ADAD_RESTARTED`.
- رسیدن به StartLimit (۵ crash در ۲ دقیقه) → `OnFailure=ban-crashloop.service` ← صفحه «برنامه اجرا نمی‌شود — تماس با پشتیبانی / تعمیرات» + رویداد CRITICAL. این همان ورودی Rollback در مرحله ۹ است.
- زنجیره full-chat §4: crash برنامه → systemd · Hang برنامه → `WatchdogSec` · Hang کل سیستم → hardware watchdog (مرحله ۴).

## گام ۳.۵ — Kiosk (full-chat §12)

| مسدود شود | چگونه |
| --- | --- |
| Ctrl+Alt+F1…F12 | Xorg `Option "DontVTSwitch" "true"` در `/etc/X11/xorg.conf.d/10-ban.conf` |
| Ctrl+Alt+Backspace | `Option "DontZap" "true"` |
| Alt+Tab، Alt+F4، Super، منوی راست‌کلیک desktop | `rc.xml` با بخش `<keyboard>` و `<mouse>` خالی |
| دکوراسیون/جابه‌جایی پنجره | `rc.xml`: `<application class="*"><decor>no</decor><maximized>yes</maximized></application>` |
| SysRq | `kernel.sysrq=0` |
| Ctrl+Alt+Del | `systemctl mask ctrl-alt-del.target` |
| دکمه Power | logind: `HandlePowerKey=ignore` ← Agent رویداد را می‌گیرد و دیالوگ «خاموش شود؟» نشان می‌دهد |
| automount USB | هیچ automounter نصب نیست؛ USB storage فقط از طریق Agent (Backup/Support Bundle) |

اصل full-chat: «نه با حذف کامل قابلیت‌ها؛ آن‌ها را برای Maintenance قابل دسترس نگه دار» و «محدودیت‌ها در لایه OS، نه داخل برنامه POS».

## گام ۳.۶ — صفحه‌کلید لمسی و مرورگر

- `onboard` با layout فارسی/انگلیسی، auto-show روی فیلدهای متنی برنامه‌های Qt/GTK؛ Ban Center صفحه‌کلید درون‌برنامه‌ای خودش را دارد (مرحله ۵).
- `ban-browser <url>`: Chromium با `--kiosk --no-first-run --incognito --user-data-dir=$(mktemp -d)`؛ policy در `/etc/chromium/policies/managed/ban.json`:

```JSON
{ "URLBlocklist": ["*"],
  "URLAllowlist": ["https://help.adadsoft.ir", "https://*.ban-os.ir"],
  "DownloadRestrictions": 3, "DeveloperToolsAvailability": 2,
  "ExtensionInstallBlocklist": ["*"], "PrintingEnabled": false,
  "PasswordManagerEnabled": false, "BrowserSignin": 0, "EditBookmarksEnabled": false }
```

allowlist واقعی از `/etc/ban/browser.json` ساخته می‌شود؛ دکمه «بستن» شناور روی صفحه؛ رویداد `BROWSER_OPENED` با URL.

## گام ۳.۷ — POS Mode و Maintenance Mode

سه مسیر ورود (full-chat §13 و §37 + p1 «در صورت انتخاب حالت تعمیرات»):

| مسیر | جزئیات |
| --- | --- |
| از داخل Adad | منوی «کمک و پشتیبانی → تعمیرات» → Adad فرمان `session.request_maintenance` به Agent می‌دهد |
| حرکت مخفی | ۵ لمس گوشه بالا-چپ در ۳ث (برای وقتی Adad هنگ کرده)؛ listener سبک در `ban-session` |
| بوت | ورودی GRUB «Maintenance» |

جریان: درخواست → صفحه PIN تمام‌صفحه → تأیید PIN توسط Agent → `systemctl --user start ban-center.service` (به‌خاطر `Conflicts=`، Launcher و Adad متوقف می‌شوند) → خروج از Ban Center → Launcher دوباره بالا می‌آید.

- در این مرحله Ban Center هنوز نیست: جایگزین موقت = `xterm` با کاربر `maintenance` پشت همان PIN. در مرحله ۵ حذف می‌شود.
- گزینه «Adad روشن بماند» برای کارهای کوتاه: Ban Center روی Adad باز می‌شود بدون توقف آن (تنظیم‌پذیر؛ پیش‌فرض: توقف).
- رویدادها: `MAINTENANCE_LOGIN`، `MAINTENANCE_LOGIN_FAILED`، `MAINTENANCE_ENTERED`، `MAINTENANCE_EXITED` (با مدت).
- تفکیک دسترسی: صندوق‌دار هیچ PINی ندارد و فقط Adad را می‌بیند؛ نقش‌های کامل در مرحله ۱۱.

## گام ۳.۸ — بسته‌بندی Adad واقعی

`adad-pos_<ver>_amd64.deb`: فایل‌ها در `/opt/adad` (venv یا PyInstaller bundle)، `Depends: postgresql-client-17, ban-launcher`، `postinst` برای migration دیتابیس، بدون هیچ داده در بسته. `APP_VERSION` در `/opt/adad/VERSION`. Adad باید: `sd_notify` watchdog بدهد، با exit code معنی‌دار خارج شود، به `ban-event` رویداد بدهد (CLI یا socket).

## Variant server

از این مرحله فقط ۳.۲ (PostgreSQL) در `server` هست؛ ۳.۱ و ۳.۳ تا ۳.۸ (Launcher، Kiosk، صفحه‌کلید لمسی، مرورگر، مسیر Maintenance گرافیکی، بسته Adad) نیستند.

| مورد | `server` |
| --- | --- |
| tuning | در اولین بوت از RAM دستگاه محاسبه می‌شود (`ban-pg-tune` در `apps/postgres/`): `shared_buffers` ≈ ۲۵٪ RAM، `effective_cache_size` ≈ ۶۰٪ RAM، `max_connections=100`؛ `synchronous_commit=on` مثل `pos` |
| اتصال | تا Provisioning فقط Unix socket (مثل `pos`)؛ listen روی LAN و TLS در مراحل ۱۱ و ۱۲ |
| schema | بسته `adad-db` (از مخزن `adad-pos`): فقط schema و migrationها، بدون UI؛ `postinst` migration را با نقش مالک دیتابیس اجرا می‌کند. روی `pos` همین کار را `postinst` بسته `adad-pos` می‌کند (۳.۸). وجود و محتوای این بسته با تیم Adad قطعی می‌شود؛ اگر Adad جزء سمت سرور دیگری دارد، بسته `adad-server` |
| کاربر `adad` | کاربر Linux ساخته نمی‌شود؛ نقش دیتابیس `adad` مالک DB است و Clientها با `adad_client` وصل می‌شوند (مرحله ۱۱) |
| Maintenance | مسیر گرافیکی ندارد؛ `ban-console` (مرحله ۵) همیشه پشت PIN است. تا آن زمان فقط در Profile `development` ورود `maintenance` از tty1 |

تست server: stop کردن PostgreSQL → `postgresql@17-main` خودکار restart می‌شود و صفحه وضعیت tty1 آن را نشان می‌دهد · tuning روی VM با ۴GB و ۱۶GB RAM مقادیر متفاوت می‌دهد · `adad-db` روی دیتابیس خالی و روی دیتابیس نسخه قبل migrate می‌کند.

معیار پذیرش server (M1): بوت headless، PostgreSQL سالم با tuning درست، وضعیت آن روی tty1.

## تست‌ها (`tests/boot/` و `tests/integration/`)

kill -9 Adad → بازگشت < ۵ث · دکمه Hang → restart با watchdog < ۷۰ث · ۵ crash پیاپی → صفحه crashloop · stop کردن PostgreSQL → پیام Launcher · تمام کلیدهای ترکیبی جدول ۳.۵ با `xdotool` · PIN غلط ×۵ → قفل موقت.

## معیار پذیرش

بوت مستقیم به Adad · هیچ راه خروج بدون PIN · همه تست‌های بالا سبز.

## خروجی

«دستگاه پس از بوت مستقیماً وارد محیط POS می‌شود و کاربر عادی به امکانات سیستمی دسترسی مستقیم ندارد.» (p1) — **نقطه عطف M1**

---

# مرحله ۴ — سرویس‌ها، Ban Event، Ban Agent (OS-04)

## هدف

«طراحی و مدیریت سرویس‌های پایه Ban OS و مشخص‌کردن ارتباط آن‌ها با systemd و یکدیگر.» (p1) — به‌علاوه قرارداد API که پیش‌نیاز BC-01 است (p2: «قابلیت‌های پایه Ban Agent باید پیش از یکپارچه‌سازی گسترده آماده باشند»).

## پوشش اقلام OS-04

| قلم p1 | گام |
| --- | --- |
| سرویس اجرای Adad | مرحله ۳ |
| سرویس Ban Agent | ۴.۵ |
| سرویس مدیریت رویدادها | ۴.۲، ۴.۳ |
| سرویس بروزرسانی | اسکلت unit اینجا؛ منطق در مرحله ۹ |
| سرویس همگام‌سازی | ۴.۶ |
| سرویس‌های سخت‌افزاری | اسکلت unit اینجا؛ منطق در مرحله ۸ |
| سیاست Restart و Health Check | ۴.۱ |
| وابستگی بین سرویس‌ها | ۴.۱ |
| مدیریت Startup و Shutdown | ۴.۱ |
| وضعیت و مانیتورینگ سرویس‌ها | ۴.۴، ۴.۵ |

## گام ۴.۱ — قالب استاندارد unit و نقشه سرویس‌ها

`services/systemd/_template.service`:

```INI
[Unit]
Description=Ban <name>
After=ban-event.service
Wants=ban-event.service
[Service]
Type=notify
User=ban-<name>
ExecStart=/opt/ban/<name>/ban-<name>
Restart=on-failure
RestartSec=3
WatchdogSec=30
StartLimitIntervalSec=300
StartLimitBurst=10
# hardening پایه (تکمیل در مرحله ۱۱)
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
ReadWritePaths=/var/lib/ban /run/ban
[Install]
WantedBy=multi-user.target
```

| سرویس | نوع | After | حیاتی؟ | Health |
| --- | --- | --- | --- | --- |
| `ban-event` | system | `local-fs.target` | بله (اولین سرویس Ban) | watchdog + نوشتن آزمایشی |
| `ban-agent` | system | `ban-event` `dbus` | بله | watchdog + `agent.ping` |
| `postgresql@17-main` | system | `local-fs` | بله (Standalone/Server) | `pg_isready` |
| `ban-hardware` | system | `ban-event` `cups` | خیر | watchdog |
| `ban-sync` | system | `ban-event` `network` | خیر | watchdog |
| `ban-update` | system (timer) | `network-online` | خیر | — |
| `ban-metrics` | system (timer ۶۰ث) | `ban-event` | خیر | — |
| `adad-launcher` / `adad` | user | `ban-session.target` | بله | watchdog |
| `ban-center` | user | — (on demand) | خیر | — |
| `NetworkManager` `cups` `systemd-timesyncd` | system | استاندارد Debian | — | — |

- Shutdown: Adad ابتدا `SIGTERM` می‌گیرد و ۱۵ث فرصت بستن تراکنش دارد (`TimeoutStopSec=15`)، سپس PostgreSQL، در آخر `ban-event` (آخرین سرویس تا `SYSTEM_SHUTDOWN` ثبت شود).
- hardware watchdog: `/etc/systemd/system.conf.d/ban.conf` → `RuntimeWatchdogSec=30` `RebootWatchdogSec=2min`؛ اگر `/dev/watchdog` نبود رویداد `WATCHDOG_UNAVAILABLE` (NOTICE).
- اصل p1: «Ban OS نباید قابلیت‌های استاندارد Linux را بدون دلیل دوباره پیاده‌سازی کند.» Restart، وابستگی و health همه با systemd است، نه supervisor اختصاصی.

## گام ۴.۲ — Event Schema (full-chat «Event Schema»)

```JSON
{
  "event_id": "01K…(ULID)",
  "timestamp": "2026-09-19T10:31:22Z",
  "device_id": "BAN-8F92A1",
  "category": "SUPPORT",
  "event_type": "REMOTE_SUPPORT_STARTED",
  "severity": "INFO",
  "actor_type": "TECHNICIAN",
  "actor_id": "support-123",
  "source": "ban-agent",
  "session_id": "MS-92831",
  "metadata": { }
}
```

`actor_type`: `SYSTEM` · `LOCAL_USER` · `TECHNICIAN` · `ADMIN` · `SUPPORT_AGENT` · `CLOUD`.
`severity` (full-chat §4): `DEBUG` `INFO` `NOTICE` `WARNING` `ERROR` `CRITICAL`.
`category` (برابر دسته‌های BC-06 در p2): `SYSTEM` `APPLICATION` `HARDWARE` `NETWORK` `SECURITY` `SUPPORT` `UPDATE` `AUDIT`.

جدول (full-chat §5 + Outbox §14 + Hash chain §16):

```SQL
CREATE TABLE events (
  id          INTEGER PRIMARY KEY,
  event_id    TEXT UNIQUE NOT NULL,
  timestamp   TEXT NOT NULL,
  category    TEXT NOT NULL,
  event_type  TEXT NOT NULL,
  severity    TEXT NOT NULL,
  actor_type  TEXT, actor_id TEXT,
  source      TEXT, session_id TEXT,
  metadata    TEXT,               -- JSON
  is_audit    INTEGER NOT NULL DEFAULT 0,
  prev_hash   TEXT, hash TEXT,    -- فقط برای is_audit=1
  synced_at   TEXT, retry_count INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX ix_events_time ON events(timestamp);
CREATE INDEX ix_events_type ON events(event_type, timestamp);
CREATE INDEX ix_events_unsynced ON events(synced_at) WHERE synced_at IS NULL;
```

SQLite با `journal_mode=WAL` و `synchronous=FULL`. Hash: `hash_n = SHA256(prev_hash ‖ canonical_json(event_n))`.

## گام ۴.۳ — کاتالوگ رویدادها (`docs/architecture/events.md`)

دو نوع جدا (full-chat: «این دو را قاطی نکن»): **Audit** = چه کسی چه کرد (`is_audit=1`)؛ **System** = اتفاق فنی.

| دسته | رویدادها | Audit؟ |
| --- | --- | --- |
| Boot | `SYSTEM_BOOT` `SYSTEM_SHUTDOWN` `SYSTEM_REBOOT` `SYSTEM_CRASH` `GRAPHICS_FAILED` `CLOCK_INVALID` | — |
| Authentication | `LOCAL_LOGIN` `LOCAL_LOGOUT` `LOGIN_FAILED` `MAINTENANCE_LOGIN` `MAINTENANCE_LOGIN_FAILED` `MAINTENANCE_ENTERED` `MAINTENANCE_EXITED` `ACCOUNT_LOCKED` | ✓ |
| Remote Support (رزرو برای Ban Desk) | `REMOTE_SUPPORT_REQUESTED` `_APPROVED` `_STARTED` `_ENDED` (با duration) `_REJECTED` `_FAILED` | ✓ |
| Update | `UPDATE_CHECKED` `UPDATE_AVAILABLE` `UPDATE_DOWNLOAD_STARTED` `_DOWNLOAD_COMPLETED` `UPDATE_VERIFICATION_FAILED` `UPDATE_INSTALL_STARTED` `_INSTALL_COMPLETED` `_INSTALL_FAILED` `UPDATE_ROLLBACK` | ✓ (شروع دستی) |
| Hardware | `PRINTER_CONNECTED` `_DISCONNECTED` `PRINTER_ERROR` `PRINTER_PAPER_LOW` `SCANNER_CONNECTED` `_DISCONNECTED` `CASH_DRAWER_OPENED` `CASH_DRAWER_ERROR` `DISPLAY_CONNECTED` `_DISCONNECTED` `SCALE_*` `PAYMENT_TERMINAL_*` `USB_DEVICE_BLOCKED` | `CASH_DRAWER_OPENED` ✓ |
| Application | `ADAD_STARTED` `ADAD_STOPPED` `ADAD_CRASHED` `ADAD_RESTARTED` `LAUNCHER_CHECK` `BROWSER_OPENED` | — |
| Database | `DATABASE_STARTED` `DATABASE_ERROR` `DATABASE_BACKUP` `DATABASE_RESTORE` `DATABASE_CORRUPTION` | Backup/Restore ✓ |
| Network | `NETWORK_CONNECTED` `NETWORK_DISCONNECTED` `SYNC_STARTED` `SYNC_COMPLETED` `SYNC_FAILED` | — |
| Resource | `DISK_WARNING` `LOW_DISK` `DISK_SPACE_WARNING` `HIGH_CPU` `HIGH_TEMPERATURE` `SMART_WARNING` | — |
| Management | `CONFIG_CHANGED` `SERVICE_STARTED_BY_USER` `SERVICE_STOPPED_BY_USER` `SERVICE_RESTARTED_BY_USER` `NETWORK_CONFIG_CHANGED` `PRINTER_CONFIG_CHANGED` `TOOLS_INSTALLED` `TOOLS_REMOVED` `USER_CREATED` `ROLE_CHANGED` `FACTORY_RESET` `DEVICE_ROLE_CHANGED` `SUPPORT_BUNDLE_CREATED` | ✓ همه |

نمونه Severity (full-chat): `PRINTER_CONNECTED`→INFO · `PRINTER_PAPER_LOW`→WARNING · `DATABASE_ERROR`→ERROR · `DATABASE_CORRUPTION`→CRITICAL.

`CONFIG_CHANGED` (full-chat §11): metadata = `{key, old_value, new_value}`؛ برای کلیدهای حساس هر دو `REDACTED`.

ممنوع در metadata: رمز، token، کلید خصوصی، اطلاعات کارت بانکی، داده کامل مشتری. `ban-event` کلیدهایی با نام `password|token|secret|pin|card` را خودکار REDACT می‌کند.

## گام ۴.۴ — `ban-event`، Retention، Metrics

- ورودی: socket `/run/ban/event.sock` (گروه `ban-ipc`) + CLI `ban-event emit --type ADAD_CRASHED --severity ERROR --meta '{"exit_code":1}'`. کتابخانه کوچک Python برای Adad و Launcher.
- اصل full-chat §13: «ثبت Event نباید منتظر اینترنت بماند» — مسیر: فرستنده → `ban-event` → SQLite → ACK.
- هر رویداد هم‌زمان به journald هم می‌رود (`SYSLOG_IDENTIFIER=ban-event`) — journal جایگزین نمی‌شود (full-chat §7).
- Retention (full-chat §15)، timer شبانه: DEBUG ۳ روز · INFO ۳۰ · WARNING ۹۰ · ERROR ۱۸۰ · AUDIT ۱ سال. رویداد sync‌نشده Audit تا sync نشود پاک نمی‌شود (سقف ۲ سال).
- `ban-metrics`: هر ۶۰ث CPU، RAM، Disk، دما، load → `/var/lib/ban/metrics.db` (حلقه‌ای ۷ روز). آستانه‌ها → `HIGH_CPU` (>۹۰٪ به مدت ۵دقیقه)، `HIGH_TEMPERATURE` (>۸۵°C)، `DISK_SPACE_WARNING` (>۸۰٪)، `LOW_DISK` (>۹۵٪).

## گام ۴.۵ — `ban-agent` اسکلت

p2: «Ban Center نباید برای هر عملیات مستقیماً با دسترسی Root به Linux متصل شود. عملیات از طریق Ban Agent و با مجوزهای محدود، کنترل‌شده و قابل ثبت انجام شوند.»

| مورد | طراحی |
| --- | --- |
| Transport | Unix socket `/run/ban/agent.sock`، مالک `ban-agent:ban-ipc` مود `0660`؛ JSON-RPC 2.0، هر پیام یک خط |
| احراز هویت لایه ۱ | `SO_PEERCRED`: فقط uidهای مجاز (`adad`، `maintenance`، root؛ در Variant server `ban-console`) |
| احراز هویت لایه ۲ | `auth.login(pin)` → session token با نقش و انقضا؛ متدهای تغییردهنده token می‌خواهند. چون Adad و Ban Center هر دو زیر uid `adad` هستند، مجوز واقعی = token نه uid |
| سطح دسترسی Agent | کاربر سیستمی `ban-agent` + polkit ruleها برای systemd1 و NetworkManager + helperهای root کوچک با آرگومان ثابت (`/opt/ban/agent/helpers/*`) برای معدود کارهای root |
| ساختار | کنترلرهای p2: System · Network · Service · Hardware · Log · Update · Recovery · Permission |
| خطا | کدهای ثابت: `UNAUTHENTICATED` `FORBIDDEN` `NOT_FOUND` `INVALID_PARAMS` `BACKEND_UNAVAILABLE` `CONFLICT_STATE` `TIMEOUT` `NOT_SUPPORTED` `INTERNAL` + `message_fa`، `message_en` (برای `ban-console`) و `trace_id` (الزام p2: «خطای قابل فهم و قابل پیگیری») |
| Audit | هر متد تغییردهنده، موفق یا ناموفق، رویداد Audit با actor از token ثبت می‌کند — در یک نقطه مرکزی (middleware)، نه در هر کنترلر |
| نسخه | `agent.version` → `{agent, api, os, variant}`؛ Center در اتصال سازگاری را چک می‌کند (الزام p2: Version Compatibility) |

متدهای این مرحله (فقط‌خواندنی): `agent.ping` · `agent.version` · `auth.login` · `auth.logout` · `auth.session` · `system.info` · `services.list` · `events.query` · `session.request_maintenance`.

معادل فهرست full-chat §16 (`GET /system`، `/network`، `/services`، `/rustdesk`، `/logs`، `/hardware`، `/updates`) در مراحل ۶ تا ۹ تکمیل می‌شود؛ `support.*` برای Ban Desk رزرو است.

`crates/ban-api-types`: همه struct/enumها با `serde` + `ts-rs` → تولید `center/ban-center/src/api/types.ts` در build. یک منبع حقیقت.

## گام ۴.۶ — `ban-sync` اسکلت

Outbox (full-chat §14): خواندن `events WHERE synced_at IS NULL` به ترتیب id، دسته‌های ۱۰۰تایی، backoff نمایی، افزایش `retry_count`. تا پیش از Ban Cloud مقصد = `null` (فقط شمارش صف). وضعیت در `sync.status` → `{pending, last_success, last_error}` برای «نمایش وضعیت همگام‌سازی رویدادها» در BC-06. همگام‌سازی داده فروش کار خود Adad است، نه این سرویس.

## گام ۴.۷ — نقشه تنظیمات (p1 «دسته‌بندی تنظیمات Ban OS»)

| دسته p1 | فایل | چه کسی می‌نویسد | حداقل نقش برای تغییر |
| --- | --- | --- | --- |
| OS Configuration | `/etc/ban/os.toml` | Image / Update | Admin |
| Device Configuration | `/etc/ban/device.toml` | Provisioning | فقط نصب (read-only بعد از آن) |
| Network Configuration | NetworkManager (`/etc/NetworkManager/system-connections`) | Agent | Technician |
| Display Configuration | `/etc/ban/display.toml` | Agent | Technician |
| Hardware Configuration | `/etc/ban/hardware.toml` | Agent | Technician |
| POS Configuration | `/etc/adad/config.toml` + `/etc/ban/pos.toml` (نقش دستگاه، آدرس Server) | Adad / Agent | Manager / Admin |
| Security Configuration | `/etc/ban/security.toml` + `/var/lib/ban/users.db` | Agent | Admin |
| Update Configuration | `/etc/ban/update.toml` (کانال، پنجره زمانی) | Agent | Admin |
| Support Configuration | `/etc/ban/support.toml` (رزرو Ban Desk) | Agent | Admin |
| Recovery Configuration | `/etc/ban/recovery.toml` (زمان‌بندی و مقصد Backup) | Agent | Technician |

قاعده: هر نوشتن از طریق Agent = نوشتن اتمیک (tmp + rename) + نسخه قبلی در `/var/lib/ban/config-history/` + رویداد `CONFIG_CHANGED`. پایه «بازیابی تنظیمات» در OS-07.

## Variant server

همه این مرحله مشترک است؛ فقط این تفاوت‌ها:

- جدول ۴.۱: `adad-launcher`، `adad` و `ban-center` در `server` نیستند؛ `ban-hardware` هم نیست (پایش UPS مرحله ۸ در Agent است)؛ به‌جایش `ban-console@tty1` (system، `Restart=always`، تنها رابط محلی). `postgresql@17-main` همیشه حیاتی است.
- Agent: `OS_VARIANT` را از `/etc/ban/release` می‌خواند و در `agent.version` برمی‌گرداند. متدهایی که در یک Variant معنی ندارند (`display.*`، `hardware.*`، `session.request_maintenance` در `server`) کد `NOT_SUPPORTED` می‌دهند؛ این تصمیم در همان middleware مرکزی گرفته می‌شود، نه در هر کنترلر.
- نقشه ۴.۷: `display.toml` و `hardware.toml` در `server` نیستند؛ `pos.toml` همیشه `role = "server"` دارد.
- رویدادها: کاتالوگ مشترک است؛ `ADAD_*`، `LAUNCHER_CHECK`، `BROWSER_OPENED`، `GRAPHICS_FAILED` و رویدادهای سخت‌افزار POS در `server` تولید نمی‌شوند.
- تست: همه تست‌های این مرحله روی هر دو Variant؛ + متد `display.*` روی `server` → `NOT_SUPPORTED`.

## تست‌ها

unit test برای hash chain و redaction · integration: `ban-event emit` → `events.query` از socket · uid غیرمجاز → رد اتصال · متد تغییردهنده بدون token → `UNAUTHENTICATED` و ثبت رویداد · kill هر سرویس → restart و رویداد · قطع برق VM حین نوشتن رویداد → audit.db سالم.

## معیار پذیرش

`ban-agent` از socket پاسخ می‌دهد · crash کردن Adad در `audit.db` دیده می‌شود · `agent-api.md` نسخه 0.1 منتشر و typeهای TypeScript تولید می‌شوند.

## خروجی

«سرویس‌های Ban OS ساختار مشخص، چرخه حیات قابل کنترل و رفتار پایدار در برابر خطا دارند.» (p1)
