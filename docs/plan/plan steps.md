نقشه اجرایی گام‌به‌گام Ban OS

محور اول (سیستم‌عامل) + محور سوم (Ban Center)

این سند مکمل «plan p1» و «plan p2» است. آن دو سند مشخص می‌کنند چه چیزی باید ساخته شود؛ این سند مشخص می‌کند **به چه ترتیبی و با چه گام‌هایی**. فازهای OS-xx و BC-xx بر اساس وابستگی واقعی در ۱۴ مرحله اجرایی (مرحله ۰ تا ۱۳) ترکیب شده‌اند. هر مرحله شامل هدف، گام‌ها، معیار پذیرش و خروجی است.

محور دوم (Ban Desk) فعلاً در اولویت نیست؛ فقط جای اتصال آن در معماری حفظ می‌شود.

این فایل فهرست و نمای کلی است. جزئیات کامل هر مرحله (کانفیگ‌ها، schemaها، متدهای Agent، صفحه‌ها، رویدادها، تست‌ها و تطبیق قلم‌به‌قلم با p1 و p2) در سه فایل زیر است:

| فایل | مراحل | فازها |
| --- | --- | --- |
| `plan steps - part 1 (stage 0-4).md` | ۰ تا ۴ | OS-01، OS-02، OS-03، OS-04 |
| `plan steps - part 2 (stage 5-7).md` | ۵ تا ۷ | BC-01، BC-02، BC-03، BC-04، BC-06 |
| `plan steps - part 3 (stage 8-13).md` | ۸ تا ۱۳ | OS-05…OS-10، BC-05، BC-07، BC-08، BC-09، BC-12 |

تصمیم‌های فنی ثابت

| بخش | انتخاب |
| --- | --- |
| Base | Debian 13 (trixie) amd64، ساخت Image با `live-build` |
| محیط Build | ماشین مجازی/سرور Debian 13 (کد از Windows ویرایش می‌شود، Build و تست روی VM) |
| گرافیک | Xorg + Openbox + LightDM (autologin کاربر `adad`) |
| کاربران سیستم | `root` (قفل)، `adad` (POS، بدون shell)، `maintenance` (تکنسین) |
| Adad POS | همان برنامه PyQt فعلی، بسته‌بندی‌شده به `.deb` در `/opt/adad` |
| دیتابیس Adad | PostgreSQL 17 (نسخه Debian 13) — نقش دستگاه: Standalone / Server / Client |
| Ban Agent | daemon به زبان Rust (tokio، `zbus` برای D-Bus، `rusqlite`)، IPC روی Unix Domain Socket در `/run/ban/agent.sock`، JSON-RPC |
| Ban Center | Tauri 2 (هسته Rust + WebKitGTK 4.1) با React + TypeScript + Vite، فارسی و RTL، فونت Vazirmatn |
| قرارداد مشترک | crate `ban-api-types` بین Agent و هسته Tauri؛ typeهای TypeScript از همان تولید می‌شوند (`ts-rs` یا `specta`) |
| Event / Audit | SQLite در `/var/lib/ban/audit.db` + Outbox + Hash chain؛ journald سر جای خود می‌ماند |
| مسیرها | `/opt/adad` · `/opt/ban` · `/etc/ban` · `/var/lib/adad` · `/var/lib/ban` · `/var/log/adad` |
| بسته‌بندی | همه اجزا `.deb`؛ بروزرسانی گام اول = مخزن apt امضاشده، گام دوم (بعد از 1.0) = A/B |
| نسخه‌ها | `OS_VERSION`، `APP_VERSION`، `AGENT_API_VERSION`، `HARDWARE_API_VERSION` مستقل از هم |
| مرورگر | Chromium فقط از طریق wrapper قفل‌شده `ban-browser` |
| ابزارهای تکنسین | اختیاری؛ در Image نیستند و از Ban Center قابل نصب‌اند |
| تست | QEMU/KVM + OVMF روی VM، سپس سخت‌افزار واقعی (Intel N100، mini PC، touch POS) |

فهرست مراحل

| مرحله | عنوان | فازهای پوشش‌داده‌شده |
| --- | --- | --- |
| ۰ | آماده‌سازی | پیش‌نیاز OS-01 |
| ۱ | پایه سیستم‌عامل | OS-01 |
| ۲ | Boot & Login | OS-02 |
| ۳ | محیط POS | OS-03 |
| ۴ | سرویس‌ها، Ban Agent و Ban Event | OS-04 |
| ۵ | پایه Ban Center | BC-01 |
| ۶ | System، Services، Logs | BC-02، BC-04، BC-06 |
| ۷ | شبکه و تنظیمات | BC-03 |
| ۸ | سخت‌افزار | OS-05، BC-05 |
| ۹ | بروزرسانی | OS-06، BC-07 |
| ۱۰ | Recovery و Backup | OS-07، BC-08 |
| ۱۱ | امنیت و دسترسی | OS-08، BC-09 |
| ۱۲ | نصب‌کننده و Provisioning | OS-09 |
| ۱۳ | انتشار Production | OS-10، BC-12 |

مرحله ۰ — آماده‌سازی
هدف

آماده‌کردن محیط Build، مخزن کد و قراردادهای پروژه، پیش از نوشتن هر جزء.

گام‌ها

۱. ساخت VM Debian 13 برای Build: حداقل ۴ core، ۸GB RAM، ۸۰GB دیسک، nested virtualization فعال.

۲. نصب ابزار Image: `live-build`، `qemu-system-x86`، `ovmf`، `git`، `make`، `debhelper`.

۳. نصب ابزار Agent و Center: `rustup` (stable)، Node.js LTS و pnpm، `libwebkit2gtk-4.1-dev`، `libgtk-3-dev`، `cargo-deb`.

۴. راه‌اندازی mirror محلی apt (مثلاً `apt-cacher-ng` یا mirror کامل) تا Build به اینترنت آزاد وابسته نباشد و در شرایط فیلترینگ/تحریم هم کار کند.

۵. `git init` مخزن `ban-os` با ساختار p1؛ فقط پوشه‌های لازم فعلی: `image/` `launcher/` `kiosk/` `services/` `agent/` `center/` `event/` `crates/` `docs/` `tests/` `config/`.

۶. ایجاد Cargo workspace در ریشه: `agent/ban-agent`، `event/ban-event`، `center/ban-center/src-tauri`، `crates/ban-api-types`.

۷. فایل‌های `VERSION`، `CHANGELOG.md`، `README.md` و `Makefile` با هدف‌های `build`، `run-vm`، `test`، `clean`.

۸. تعریف سه گونه Image در `config/`: `development` (SSH باز، ابزار دیباگ)، `staging`، `production`.

۹. قراردادها: پیشوند سرویس‌ها `ban-*` و `adad-*`، SemVer، نام شاخه‌ها، قالب commit.

معیار پذیرش

`make build` روی VM بدون خطا اجرا می‌شود، حتی اگر خروجی هنوز یک Image خالی باشد.

خروجی

مخزن و محیط Build آماده، بدون وابستگی به اینترنت خارجی.

مرحله ۱ — پایه سیستم‌عامل (OS-01)
هدف

ساخت اولین Image قابل بوت Debian که پایه تمام مراحل بعد باشد.

گام‌ها

۱. `lb config` برای trixie / amd64 / UEFI با mirror محلی.

۲. package-listها در `image/packages/`: پایه (systemd، NetworkManager، CUPS، udev)، فارسی (locale `fa_IR.UTF-8`، فونت Vazirmatn، چیدمان صفحه‌کلید fa/en)، دیتابیس (PostgreSQL 17)، مرورگر (Chromium).

۳. `includes.chroot` برای hostname، locale، timezone `Asia/Tehran`، journald persistent.

۴. همگام‌سازی زمان: `systemd-timesyncd` با سرورهای NTP قابل دسترس + بررسی سلامت RTC در بوت (زمان غلط = فاکتور غلط).

۵. کاهش فرسایش SSD/eMMC: سقف حجم journald، `noatime`، tmpfs برای `/tmp` و cacheها.

۶. هدف `make run-vm`: بوت ISO در QEMU + OVMF.

۷. CI حداقلی از همین مرحله: build خودکار + تست بوت خودکار در QEMU (رسیدن به login prompt = موفق).

۸. مستند `docs/architecture/build.md`.

معیار پذیرش

ISO در QEMU با UEFI بوت می‌شود، ساعت و locale درست است، PostgreSQL بالا می‌آید.

خروجی

یک Image اولیه که بوت می‌شود و CI آن را در هر commit می‌سازد و تست می‌کند.

مرحله ۲ — Boot & Login (OS-02)
هدف

بوت اختصاصی Ban OS و ورود خودکار به محیط گرافیکی، بدون دخالت کاربر.

گام‌ها

۱. GRUB: منوی مخفی با timeout کوتاه، پارامترهای `quiet splash`. ورودی‌ها: «Ban OS»، «Maintenance»، «Recovery». نمایش منو با نگه‌داشتن F12 هنگام بوت.

۲. Plymouth theme با لوگوی Ban OS.

۳. نصب Xorg + Openbox + LightDM؛ ساخت کاربر `adad`؛ autologin به session `openbox`.

۴. غیرفعال‌کردن screen blanking و DPMS؛ مخفی‌کردن cursor در حالت touch.

۵. نمایشگر: تنظیم رزولوشن، چرخش صفحه، شناسایی نمایشگر دوم (مشتری) با `xrandr`؛ ذخیره در `/etc/ban/display.toml`.

۶. رفتار خطای بوت: اگر X بالا نیامد → صفحه خطای ساده روی console + ثبت در journal + امکان ورود به Maintenance.

معیار پذیرش

Power on → لوگو → دسکتاپ خالی Openbox، بدون هیچ ورودی دستی، زیر حدود ۲۰ ثانیه در VM.

خروجی

دستگاه پس از روشن شدن خودکار وارد session گرافیکی کاربر `adad` می‌شود.

مرحله ۳ — محیط POS (OS-03)
هدف

اجرای Adad به‌عنوان برنامه اصلی دستگاه در محیط Kiosk، با مسیر کنترل‌شده به Maintenance.

گام‌ها

۱. برنامه جایگزین `adad-dummy` (PyQt تمام‌صفحه با دکمه Crash و دکمه اتصال به DB) تا Adad واقعی بسته‌بندی شود.

۲. پیکربندی PostgreSQL: cluster روی پارتیشن داده، فقط Unix socket، احراز هویت `peer` برای کاربر `adad`، tuning سبک برای RAM کم.

۳. `adad-launcher`: بررسی Configuration، Database (`pg_isready` + اتصال)، Hardware، License/Device → اجرای Adad. در خطا: صفحه «Retry / Maintenance».

۴. `adad.service` به‌صورت systemd user unit زیر session کاربر `adad` با `Restart=always`، `RestartSec=2` و `StartLimit`.

۵. Kiosk: `rc.xml` Openbox بدون keybinding، منو و دکوراسیون؛ غیرفعال‌سازی VT switch و Ctrl+Alt+Backspace در Xorg؛ بدون راست‌کلیک.

۶. صفحه‌کلید لمسی روی صفحه برای دستگاه‌های بدون کیبورد.

۷. `ban-browser`: wrapper Chromium با `--kiosk` و policyهای مدیریت‌شده؛ allowlist دامنه‌ها در `/etc/ban/browser.json`؛ بدون دانلود، devtools، extension و `file://`؛ پروفایل موقتی.

۸. ورود به Maintenance: حرکت/کلید مخفی داخل Adad یا ورودی GRUB → دیالوگ PIN → (موقت) ترمینال محدود؛ در مرحله ۵ با Ban Center جایگزین می‌شود.

۹. بسته‌بندی Adad واقعی به `.deb` و جایگزینی dummy.

معیار پذیرش

بوت مستقیم به Adad؛ kill کردن Adad → بازگشت در کمتر از ۵ ثانیه؛ هیچ راه خروجی بدون PIN وجود ندارد؛ توقف PostgreSQL → Launcher پیام واضح می‌دهد.

خروجی

نقطه عطف M1: دستگاه پس از بوت مستقیماً وارد Adad می‌شود.

مرحله ۴ — سرویس‌ها، Ban Agent و Ban Event (OS-04)
هدف

الگوی استاندارد سرویس‌ها و دو ستون اصلی کنترل Ban OS: ثبت رویداد و Agent. قرارداد API این مرحله پیش‌نیاز کل Ban Center است.

گام‌ها

۱. قالب استاندارد unit در `services/systemd/`: hardening پایه، `Restart`، `WatchdogSec`، وابستگی‌ها، ترتیب Startup و Shutdown.

۲. کاتالوگ رویدادها در `docs/architecture/events.md`: همه Event Typeهای full-chat (Boot، Authentication، Remote Support، Update، Hardware، Application، Database، Network، Config)، Severity (DEBUG تا CRITICAL)، قاعده REDACTED برای Secretها.

۳. `ban-event`: سرویس ثبت رویداد، جدول `events` با ستون‌های Outbox (`synced_at`، `retry_count`)، CLI `ban-event emit` برای اسکریپت‌ها و Adad.

۴. سیاست Retention محلی: DEBUG سه روز، INFO سی روز، WARNING نود روز، ERROR صد و هشتاد روز، AUDIT یک سال؛ پاک‌سازی زمان‌بندی‌شده.

۵. Metrics: نمونه‌برداری دوره‌ای CPU، RAM، Disk و دما و نگهداری کوتاه‌مدت برای نمودارها.

۶. `crates/ban-api-types`: تعریف typeهای درخواست/پاسخ/خطا و نسخه API.

۷. `ban-agent` اسکلت: socket، احراز هویت peer با `SO_PEERCRED` و گروه `ban-admin`، متدهای فقط‌خواندنی `system.info`، `services.list`، `events.query`.

۸. `ban-sync` اسکلت: خواندن Outbox و صف محلی؛ مقصد Cloud بعد از 1.0 وصل می‌شود.

۹. نقشه ۱۰ دسته تنظیمات p1 به فایل‌ها: `/etc/ban/{os,device,network,display,hardware,pos,security,update,support,recovery}.toml` و سطح دسترسی هرکدام.

۱۰. hardware watchdog + رویدادهای `SYSTEM_BOOT`، `SYSTEM_SHUTDOWN`، `ADAD_STARTED`، `ADAD_CRASHED`، `ADAD_RESTARTED`.

۱۱. مستند قرارداد `docs/architecture/agent-api.md` (نسخه‌دار).

معیار پذیرش

`ban-agent` از طریق socket پاسخ می‌دهد؛ کاربر غیرمجاز رد می‌شود؛ crash کردن Adad در `audit.db` دیده می‌شود.

خروجی

سرویس‌های Ban OS چرخه حیات مشخص دارند و قرارداد Agent برای Ban Center آماده است.

مرحله ۵ — پایه Ban Center (BC-01)
هدف

نسخه اولیه Ban Center که به Ban Agent وصل می‌شود و اسکلت پنل را نمایش می‌دهد.

گام‌ها

۱. پروژه Tauri 2 در `center/ban-center`:

```
ban-center/
├── src-tauri/          (Rust)
│   ├── agent_client/
│   ├── commands/
│   ├── session/
│   └── permissions/
├── src/                (React + TypeScript)
│   ├── shell/
│   ├── pages/
│   │   ├── dashboard/  system/    network/   services/
│   │   ├── hardware/   logs/      updates/   recovery/
│   │   └── users/      support/   settings/
│   ├── components/
│   ├── i18n/
│   └── theme/
├── tests/
└── packaging/
```

لایه‌بندی p2 (domain / application / infrastructure) حفظ می‌شود؛ فقط ساختار Python آن با این ساختار جایگزین می‌شود.

۲. `agent_client` در هسته Rust: اتصال به socket، timeout، reconnect، تبدیل خطا به پیام قابل فهم.

۳. مرز امنیتی: فرانت‌اند فقط از طریق Tauri commands صحبت می‌کند. WebView هیچ دسترسی مستقیم به socket، فایل یا shell ندارد؛ capabilities حداقلی، CSP سخت، بدون بارگذاری محتوای remote.

۴. Shell برنامه: Sidebar راست‌به‌چپ، Navigation، theme، فونت Vazirmatn، اندازه مناسب touch، تاریخ جلالی، صفحه‌کلید لمسی درون‌برنامه‌ای برای PIN و رمز Wi-Fi.

۵. حالت kiosk پنجره: fullscreen، بدون decoration؛ غیرفعال‌کردن context menu، devtools و zoom در build production.

۶. ورود با PIN تکنسین و مدیریت session؛ جایگزین ترمینال موقت مرحله ۳.

۷. صفحه Remote Support به‌صورت placeholder (برای Ban Desk در آینده).

۸. بسته `.deb` + افزودن `libwebkit2gtk-4.1-0` و `libgtk-3-0` به Image.

۹. سنجش RAM و زمان بازشدن روی ضعیف‌ترین سخت‌افزار هدف.

معیار پذیرش

Maintenance → PIN → Ban Center باز می‌شود و وضعیت اتصال به Agent را نشان می‌دهد؛ قطع Agent → پیام خطای واضح و اتصال مجدد خودکار؛ خروج → بازگشت به Adad.

خروجی

اسکلت Ban Center روی Image، متصل به Ban Agent.

مرحله ۶ — System، Services، Logs (BC-02، BC-04، BC-06)
هدف

سه بخش پرکاربرد پنل؛ ابتدا فقط‌خواندنی، سپس عملیات.

گام‌ها

۱. Agent `system.*` (از `/proc` و crate `sysinfo`): CPU، RAM، Disk، دما، Uptime، Kernel، اطلاعات دستگاه → صفحات Dashboard و System.

۲. صفحه Storage: تفکیک Database / Logs / Cache / System، هشدار بالای ۸۰٪ و رویداد `DISK_SPACE_WARNING`.

۳. Agent `services.*` روی D-Bus systemd: list و status؛ سپس start / stop / restart فقط برای whitelist سرویس‌ها → صفحه Services (شامل PostgreSQL و CUPS).

۴. Agent `logs.query` (journald) و `events.query` (audit.db) → Log Viewer با فیلتر نوع، شدت، بازه زمانی، جست‌وجو و Export.

۵. هر عملیات تغییردهنده = یک رویداد Audit با actor و نتیجه.

۶. دکمه Support Bundle: خروجی لاگ + رویداد + اطلاعات سیستم روی USB (جایگزین موقت پشتیبانی از راه دور).

۷. صفحه «ابزارهای اختیاری»: نصب/حذف `ban-tech-tools` (ترمینال، ویرایشگر، مدیر فایل، htop، `psql`) از طریق Agent با whitelist بسته‌ها؛ فقط نقش Technician؛ رویداد `TOOLS_INSTALLED` / `TOOLS_REMOVED`. (مخزن آن در مرحله ۹ کامل می‌شود؛ تا آن زمان از USB امضاشده.)

معیار پذیرش

Restart یک سرویس از UI انجام و در Audit ثبت می‌شود؛ Support Bundle روی USB ساخته می‌شود.

خروجی

تکنسین وضعیت دستگاه، سرویس‌ها و لاگ‌ها را بدون ترمینال می‌بیند.

مرحله ۷ — شبکه و تنظیمات (BC-03)
هدف

مدیریت شبکه و تنظیمات پایه دستگاه از Ban Center، با NetworkManager به‌عنوان Backend.

گام‌ها

۱. Agent `network.*` روی D-Bus NetworkManager: وضعیت، Ethernet (DHCP / Static)، Wi-Fi (scan / connect / disconnect / forget).

۲. صفحات Overview، Ethernet، Wi-Fi، IP Configuration، Diagnostics (ping gateway، تست DNS، تست اینترنت).

۳. محافظ تغییر IP: تأیید کاربر + rollback خودکار اگر اتصال طی چند ثانیه برنگشت.

۴. صفحه Settings: تاریخ / ساعت / منطقه زمانی، نمایشگر / رزولوشن / چرخش / کالیبره touch، صدا، وضعیت Firewall (فقط نمایش).

۵. نمایش نقش دستگاه (Standalone / Server / Client) و آدرس Server دیتابیس؛ تغییر آن فقط با نقش Admin.

معیار پذیرش

تنظیم Static IP و اتصال به Wi-Fi رمزدار فقط با touch و بدون ترمینال؛ IP اشتباه → بازگشت خودکار.

خروجی

نقطه عطف M2: Ban Center برای کارهای روزمره تکنسین قابل استفاده است.

مرحله ۸ — سخت‌افزار (OS-05، BC-05)
هدف

لایه استاندارد سخت‌افزار تا Adad و Ban Center به جزئیات برند تجهیزات وابسته نباشند.

گام‌ها

۱. `ban-hardware` service + رابط استاندارد Printer / Scanner / CashDrawer / CustomerDisplay / Scale / PaymentTerminal با الگوی Adapter.

۲. دور اول Adapterها: چاپگر ESC/POS (USB و Network)، کشوی پول از طریق چاپگر، بارکدخوان HID.

۳. چاپ فارسی: رندر رسید به تصویر و ارسال raster به چاپگر (نه codepage) تا روی همه برندها درست چاپ شود.

۴. قوانین udev برای نام پایدار (`/dev/ban-printer`، `/dev/ban-scale`، …) و رویدادهای connect / disconnect.

۵. `/etc/ban/hardware.toml` + متدهای `hardware.*` در Agent.

۶. صفحات Hardware در Ban Center با Test Print، Open Drawer، Scan Test، تست پورت.

۷. اتصال Adad به همین رابط، نه مستقیم به دستگاه.

۸. دور دوم Adapterها: نمایشگر مشتری، ترازو، کارت‌خوان / پایانه پرداخت.

۹. فهرست سخت‌افزارهای سازگار (HCL) در `docs/operations/hardware-compatibility.md`.

معیار پذیرش

روی سخت‌افزار واقعی: تست چاپ فارسی و باز شدن کشو، هم از Ban Center و هم از Adad؛ جدا و وصل کردن چاپگر در Audit ثبت می‌شود.

خروجی

یک رابط استاندارد سخت‌افزار با نسخه مستقل (`HARDWARE_API_VERSION`).

مرحله ۹ — بروزرسانی (OS-06، BC-07)
هدف

بروزرسانی کنترل‌شده و امضاشده اجزا؛ گام اول به‌صورت بسته‌ای.

گام‌ها

۱. مخزن apt خصوصی امضاشده (`reprepro` یا `aptly`) با کانال‌های `stable` و `beta`؛ کلید خصوصی فقط روی سرور Release.

۲. `ban-update`: manifest، بررسی نسخه، دانلود، تأیید امضا (نه فقط SHA256)، نصب در پنجره زمانی مجاز، رویدادهای `UPDATE_*`.

۳. تفکیک Application Update (Adad) از OS Update (پکیج‌های سیستم، Agent، Center، Hardware).

۴. Health check بعد از بروزرسانی؛ سه crash پیاپی Adad → بازگشت به بسته قبلی و رویداد `UPDATE_ROLLBACK`.

۵. سازگاری PostgreSQL در OS Update (`pg_upgradecluster` برای تغییر نسخه major).

۶. meta-package `ban-tech-tools` در مخزن.

۷. صفحات Updates: Current Versions، Available، History، Settings.

معیار پذیرش

انتشار نسخه جدید dummy → VM خودکار بروزرسانی می‌شود؛ بسته دست‌کاری‌شده رد و رویداد `UPDATE_VERIFICATION_FAILED` ثبت می‌شود.

خروجی

سیستم بروزرسانی قابل کنترل و قابل نظارت، آماده ارتقا به A/B.

مرحله ۱۰ — Recovery و Backup (OS-07، BC-08)
هدف

بازگشت دستگاه به وضعیت عملیاتی پس از خطاهای رایج، بدون از دست رفتن داده فروشگاه.

گام‌ها

۱. پارتیشن‌بندی نهایی: EFI / root / داده جدا (`/var/lib`)؛ چیدمان سازگار با A/B آینده.

۲. بررسی root فقط‌خواندنی (overlay / immutable) به‌عنوان پیش‌نیاز A/B و مقاومت در برابر قطع برق.

۳. Backup زمان‌بندی‌شده: `pg_dump` (فقط روی Standalone و Server) + تنظیمات `/etc/ban` → `/var/lib/ban/backups` و مقصد USB؛ verify با restore آزمایشی.

۴. Restore دیتابیس و تنظیمات؛ Factory Reset با احراز هویت مجدد + تأیید صریح + هشدار از دست رفتن داده.

۵. ورودی Recovery در GRUB: تعمیر فایل‌سیستم، Reset تنظیمات، Restore، Rollback.

۶. پایش دیسک: SMART، فضای کم → رویداد و اجرای Retention.

۷. صفحات Backup & Recovery در Ban Center؛ جلوگیری از عملیات ناسازگار با وضعیت دستگاه.

معیار پذیرش

قطع برق حین فروش و حین بروزرسانی در VM → سیستم سالم بالا می‌آید؛ Restore از Backup روی دستگاه تازه کار می‌کند.

خروجی

نقطه عطف M3: دستگاه آماده نصب آزمایشی در یک فروشگاه واقعی.

مرحله ۱۱ — امنیت و دسترسی (OS-08، BC-09)
هدف

مدل دسترسی مشخص و قابل حسابرسی برای دستگاهی که در محیط عمومی فروشگاه قرار دارد.

گام‌ها

۱. نقش‌ها (POS Operator، Store Manager، Technician، System Administrator) و جدول مجوز در Agent؛ Support Agent برای آینده رزرو می‌شود.

۲. PIN هش‌شده، قفل پس از تلاش ناموفق، session timeout، احراز هویت مجدد برای عملیات حساس، دسترسی آفلاین و اضطراری.

۳. root قفل؛ عملیات privileged فقط از طریق Agent (polkit / whitelist).

۴. nftables با پیش‌فرض deny ورودی؛ در نقش Server فقط پورت 5432 برای subnet فروشگاه، `pg_hba` با `scram-sha-256` و TLS.

۵. سیاست USB (USBGuard / منع USB storage برای Operator)، حذف سرویس‌های غیرضروری، hardening unitها (`ProtectSystem`، `NoNewPrivileges`، …).

۶. Secrets بیرون از Image و فقط در Provisioning؛ Hash chain برای رویدادهای Audit.

۷. صفحات Users & Access: Users، Roles، Permissions، Sessions.

۸. چک‌لیست `docs/security/hardening.md`.

معیار پذیرش

چک‌لیست hardening پاس می‌شود؛ Operator به هیچ عملیات حساسی دسترسی ندارد؛ دست‌کاری audit.db با Hash chain قابل تشخیص است.

خروجی

Ban OS با مدل دسترسی کنترل‌شده. (Secure Boot و TPM بعد از 1.0.)

مرحله ۱۲ — نصب‌کننده و Provisioning (OS-09)
هدف

نصب Ban OS روی دستگاه واقعی با حداقل دخالت دستی.

گام‌ها

۱. ISO نصب unattended: انتخاب دیسک → پارتیشن‌بندی → کپی سیستم → GRUB UEFI.

۲. First-boot wizard: زبان، شبکه، نمایشگر و کالیبره touch، Store ID / Terminal ID، Admin PIN.

۳. انتخاب نقش دستگاه: Standalone / Server / Client. در Client، PostgreSQL محلی غیرفعال و آدرس Server در `/etc/ban/pos.toml` ثبت می‌شود.

۴. Device Identity: تولید keypair روی خود دستگاه؛ `device_id` (مثل `BAN-8F92A1`) در `/etc/ban/device.toml`.

۵. Activation حداقلی: یک endpoint ثبت دستگاه (public key + Store / Terminal + License). این تنها جزء سمت سرور پیش از 1.0 است.

۶. حالت‌های نصب: کارخانه‌ای، تکنسین، Recovery Installation، توسعه‌ای.

معیار پذیرش

از USB تا Adad آماده فروش در کمتر از ۱۵ دقیقه؛ نصب Server + Client در یک شبکه محلی کار می‌کند.

خروجی

فرآیند استاندارد تولید Image و نصب روی دستگاه‌های مختلف.

مرحله ۱۳ — انتشار Production (OS-10، BC-12)
هدف

آماده‌سازی نسخه 1.0 برای نصب روی دستگاه مشتریان.

گام‌ها

۱. ماتریس تست: بوت، Crash و Recovery، بروزرسانی، امنیت، عملکرد، خاموش / روشن، قطع و وصل شبکه، قطع برق، soak test ۷۲ ساعته، سخت‌افزارهای هدف.

۲. تست Ban Center: ارتباط با Agent، مجوزها، عملیات حساس، خطاهای شبکه، خوانایی و کاربردپذیری touch، Maintenance Mode، ثبت رویدادها.

۳. CI کامل: build → تست بوت QEMU → امضا → انتشار در کانال `beta` → `stable`.

۴. Release Notes، سازگاری نسخه Ban OS / Agent / Center، سیاست پشتیبانی نسخه‌ها.

۵. مستندات تکنسین و پشتیبانی؛ فرآیند گزارش خطا و hotfix.

خروجی

نقطه عطف M4: Ban OS 1.0.0 + Ban Center 1.0.0.

وابستگی مراحل

```
۰ → ۱ → ۲ → ۳ → ۴ → ۵
                      │
          ┌───────────┼───────────┐
          ▼           ▼           │
          ۶           ۷           │   (۶ و ۷ موازی)
          └─────┬─────┘           │
                ▼                 │
          ┌─────┴─────┐           │
          ▼           ▼           │
          ۸           ۹           │   (۸ و ۹ موازی)
          └─────┬─────┘           │
                ▼                 │
               ۱۰ → ۱۱ → ۱۲ → ۱۳ ◄┘
```

نقاط عطف

| نقطه عطف | پایان مرحله | نتیجه |
| --- | --- | --- |
| M1 | ۳ | بوت مستقیم به Adad |
| M2 | ۷ | Ban Center قابل استفاده برای تکنسین |
| M3 | ۱۰ | دستگاه آزمایشی در فروشگاه واقعی |
| M4 | ۱۳ | نسخه Production |

بعد از 1.0

این موارد آگاهانه بیرون از محدوده فعلی هستند و فقط جای اتصالشان حفظ شده است:

BC-10 — Ban Cloud Integration (مقصد `ban-sync`)

BC-11 — Fleet Management

محور Ban Desk — BD-01 تا BD-08 (صفحه Remote Support فعلاً placeholder است)

A/B Update و root فقط‌خواندنی کامل

Secure Boot و TPM

اصل اجرایی

هر مرحله باید با معیار پذیرش خودش روی QEMU یا سخت‌افزار واقعی بسته شود، بعد مرحله بعد شروع شود. هر وقت گفتی «مرحله N را بفرست»، جزئیات اجرایی همان مرحله (فایل‌ها، دستورها و کانفیگ‌ها) را باز می‌کنم.
