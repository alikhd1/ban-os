نقشه اجرایی گام‌به‌گام Ban OS

محور اول (سیستم‌عامل) + محور سوم (Ban Center)

این سند مکمل «plan p1» و «plan p2» است. آن دو سند مشخص می‌کنند چه چیزی باید ساخته شود؛ این سند مشخص می‌کند **به چه ترتیبی و با چه گام‌هایی**. فازهای OS-xx و BC-xx بر اساس وابستگی واقعی در ۱۴ مرحله اجرایی (مرحله ۰ تا ۱۳) ترکیب شده‌اند. هر مرحله شامل هدف، گام‌ها، معیار پذیرش و خروجی است.

محور دوم (Ban Desk) فعلاً در اولویت نیست؛ فقط جای اتصال آن در معماری حفظ می‌شود.

Ban OS در دو گونه (Variant) ساخته می‌شود: `pos` (صندوق فروش گرافیکی، محدوده اصلی این سند) و `server` (سرور فروشگاه بدون رابط گرافیکی). هر دو از یک pipeline، یک مخزن بسته و یک `OS_VERSION` ساخته می‌شوند و فقط در لایه رابط کاربری و چند بسته فرق دارند. خلاصه در بخش «دو Variant» پایین آمده است؛ در هر مرحله، کار Variant server زیر عنوان «Variant server» است.

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
| Variant | `pos`: صندوق گرافیکی (Kiosk + Adad + Ban Center) · `server`: سرور فروشگاه بدون UI گرافیکی (PostgreSQL + سرویس‌های Ban + `ban-console`)؛ یک pipeline، دو ISO، `OS_VERSION` مشترک |
| محیط Build | ماشین مجازی/سرور Debian 13 (کد از Windows ویرایش می‌شود، Build و تست روی VM) |
| گرافیک | Xorg + Openbox + LightDM (autologin کاربر `adad`)؛ فقط Variant `pos` |
| کاربران سیستم | `root` (قفل)، `adad` (POS، بدون shell)، `maintenance` (تکنسین)؛ Variant `server` کاربر `adad` ندارد و `ban-console` دارد |
| Adad POS | همان برنامه PyQt فعلی، بسته‌بندی‌شده به `.deb` در `/opt/adad`؛ فقط Variant `pos` (روی `server` فقط `adad-db`) |
| دیتابیس Adad | PostgreSQL 17 (نسخه Debian 13) — نقش دستگاه: Standalone / Server / Client؛ Variant `server` همیشه نقش Server |
| Ban Agent | daemon به زبان Rust (tokio، `zbus` برای D-Bus، `rusqlite`)، IPC روی Unix Domain Socket در `/run/ban/agent.sock`، JSON-RPC |
| Ban Center | Tauri 2 (هسته Rust + WebKitGTK 4.1) با React + TypeScript + Vite، فارسی و RTL، فونت Vazirmatn؛ فقط Variant `pos` |
| Ban Console | Variant `server` و رابط Recovery هر دو Variant: Rust + `ratatui`، متنی و انگلیسی روی tty1، کلاینت همان socket Agent و `ban-api-types` |
| قرارداد مشترک | crate `ban-api-types` بین Agent و هسته Tauri؛ typeهای TypeScript از همان تولید می‌شوند (`ts-rs` یا `specta`)؛ `ban-console` همان crate را مستقیم در Rust استفاده می‌کند |
| Event / Audit | SQLite در `/var/lib/ban/audit.db` + Outbox + Hash chain؛ journald سر جای خود می‌ماند |
| مسیرها | `/opt/adad` · `/opt/ban` · `/etc/ban` · `/var/lib/adad` · `/var/lib/ban` · `/var/log/adad` |
| بسته‌بندی | همه اجزا `.deb`؛ بروزرسانی گام اول = مخزن apt امضاشده، گام دوم (بعد از 1.0) = A/B؛ هر Variant یک meta-package: `ban-os-pos` / `ban-os-server` |
| نسخه‌ها | `OS_VERSION`، `APP_VERSION`، `AGENT_API_VERSION`، `HARDWARE_API_VERSION` مستقل از هم |
| مرورگر | Chromium فقط از طریق wrapper قفل‌شده `ban-browser` |
| ابزارهای تکنسین | اختیاری؛ در Image نیستند و از Ban Center قابل نصب‌اند (در `server`: `ban-tech-tools-cli` از `ban-console`) |
| تست | QEMU/KVM + OVMF روی VM، سپس سخت‌افزار واقعی (Intel N100، mini PC، touch POS)؛ هر دو Variant، `server` روی سخت‌افزار سرور و VM هم |

دو Variant: pos و server

| مورد | `pos` | `server` |
| --- | --- | --- |
| کاربرد | صندوق فروش (touch، چاپگر، کشو) | سرور فروشگاه (mini PC، سرور یا VM) که دیتابیس Adad را به صندوق‌های Client می‌دهد |
| target پیش‌فرض | `graphical.target` | `multi-user.target` |
| نقش دستگاه | Standalone / Server / Client | فقط Server |
| رابط تکنسین | Ban Center (Tauri، فارسی، touch) | `ban-console` (متنی، انگلیسی، صفحه‌کلید) |
| Adad | برنامه کامل + `adad-launcher` | بدون UI؛ فقط schema و migration دیتابیس (`adad-db`) |
| سخت‌افزار | لایه کامل `ban-hardware` | فقط UPS (`nut`) |
| meta-package | `ban-os-pos` | `ban-os-server` |
| مشترک | پایه Debian، شبکه، PostgreSQL 17، Ban Agent، Ban Event، `ban-sync`، `ban-update`، Backup و Recovery، امنیت، نصب‌کننده، مخزن apt | همان |

نقش Server روی صندوق `pos` هم باقی می‌ماند (فروشگاه کوچک بدون سرور جدا)؛ Variant `server` برای فروشگاهی است که سرور جدا دارد.

چرا دو ISO و نه یک ISO با گزینه «بدون UI»: live-build بسته‌ها را هنگام Build نصب می‌کند؛ ISO مشترک یعنی Xorg، LightDM، Chromium و WebKitGTK روی سرور هم هستند (حجم، سطح حمله، آپدیت بی‌مورد). با دو ISO از یک pipeline، تفاوت فقط در package-listها و meta-package است و آپدیت هیچ‌وقت UI گرافیکی را روی سرور نمی‌آورد.

Build: محور Variant مستقل از Profile است (شش ترکیب): `make build PROFILE=<profile> VARIANT=<pos|server>` → `ban-os-<ver>-<profile>-<variant>-amd64.iso`. تنظیمات هر Variant در `image/variants/<variant>/`.

مدیریت سرور بدون UI: `ban-console` کلاینت همان socket Agent با همان `ban-api-types` است؛ Agent همچنان تنها جزء privileged می‌ماند و مرز امنیتی تغییر نمی‌کند. متن‌ها انگلیسی‌اند چون کنسول لینوکس شکل‌دهی و راست‌به‌چپ فارسی را ندارد. دسترسی در 1.0 فقط محلی است: صفحه‌کلید و مانیتور، کنسول VM یا IPMI serial-over-LAN. مدیریت از راه دور یعنی باز کردن Agent روی شبکه، و به بعد از 1.0 موکول می‌شود.

موارد باز (با تیم Adad):

- migration دیتابیس روی `server`: در `pos` این کار با `postinst` بسته `adad-pos` انجام می‌شود؛ روی `server` که Adad ندارد، بسته جدای `adad-db` (فقط schema و migration، بدون UI) از مخزن `adad-pos` پیشنهاد می‌شود.
- اگر Adad غیر از PostgreSQL جزء سمت سرور دیگری دارد (سرویس، API، sync)، بسته `adad-server` فقط روی Variant server نصب می‌شود.
- نوع License سرور در Activation (مرحله ۱۲).

فهرست مراحل

| مرحله | عنوان | فازهای پوشش‌داده‌شده | Variant server |
| --- | --- | --- | --- |
| ۰ | آماده‌سازی | پیش‌نیاز OS-01 | مشترک |
| ۱ | پایه سیستم‌عامل | OS-01 | مشترک |
| ۲ | Boot & Login | OS-02 | بوت متنی، بدون session گرافیکی |
| ۳ | محیط POS | OS-03 | فقط PostgreSQL |
| ۴ | سرویس‌ها، Ban Agent و Ban Event | OS-04 | مشترک |
| ۵ | پایه Ban Center | BC-01 | `ban-console` به‌جای Ban Center |
| ۶ | System، Services، Logs | BC-02، BC-04، BC-06 | در `ban-console` |
| ۷ | شبکه و تنظیمات | BC-03 | در `ban-console`، بدون نمایشگر و touch |
| ۸ | سخت‌افزار | OS-05، BC-05 | فقط UPS |
| ۹ | بروزرسانی | OS-06، BC-07 | مشترک + ترتیب آپدیت Server و Client |
| ۱۰ | Recovery و Backup | OS-07، BC-08 | مشترک |
| ۱۱ | امنیت و دسترسی | OS-08، BC-09 | مشترک |
| ۱۲ | نصب‌کننده و Provisioning | OS-09 | wizard متنی، نقش ثابت Server |
| ۱۳ | انتشار Production | OS-10، BC-12 | مشترک، ماتریس تست برای هر دو |

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

۱۰. تعریف دو Variant در `image/variants/`: `pos` و `server`؛ محور `VARIANT` در `make build` مستقل از Profile؛ نام خروجی `ban-os-<ver>-<profile>-<variant>-amd64.iso`.

معیار پذیرش

`make build` برای هر دو Variant روی VM بدون خطا اجرا می‌شود، حتی اگر خروجی هنوز یک Image خالی باشد.

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

۹. تقسیم package-listها: مشترک در `image/packages/`، مخصوص هر Variant در `image/variants/<variant>/package-lists/` (گرافیک، چاپ، فونت و مرورگر فقط `pos`)؛ CI هر دو Variant را می‌سازد و تست بوت می‌کند.

معیار پذیرش

هر دو ISO (`pos` و `server`) در QEMU با UEFI بوت می‌شوند، ساعت و locale درست است، PostgreSQL بالا می‌آید.

خروجی

یک Image اولیه که بوت می‌شود و CI آن را در هر commit می‌سازد و تست می‌کند. خروجی این مرحله در عمل پایه Variant server است؛ دو Variant از مرحله ۲ از هم جدا می‌شوند.

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

Variant server

بدون Xorg، LightDM و Plymouth؛ `default.target = multi-user.target`. GRUB با ورودی‌های «Ban OS» و «Recovery» و خروجی kernel روی `tty0` و `ttyS0` (برای IPMI serial-over-LAN). tty1 تا مرحله ۵ فقط صفحه وضعیت متنی (نسخه، hostname، IP) نشان می‌دهد؛ tty2 تا tty6 بسته‌اند. معیار: Power on → صفحه وضعیت روی tty1، بدون هیچ ورودی دستی.

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

Variant server

فقط گام ۲ (PostgreSQL)، با tuning بر اساس RAM دستگاه در اولین بوت؛ Launcher، Kiosk، صفحه‌کلید لمسی و مرورگر ندارد. schema دیتابیس Adad با بسته `adad-db` ساخته و migrate می‌شود (بخش «دو Variant»). معیار: بوت headless، PostgreSQL سالم و وضعیت آن روی tty1.

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

Variant server

این مرحله کاملاً مشترک است. Agent مقدار `OS_VARIANT` را از `/etc/ban/release` می‌خواند؛ متدهایی که در یک Variant معنی ندارند (نمایشگر، سخت‌افزار POS، session گرافیکی) خطای `NOT_SUPPORTED` برمی‌گردانند. کاربر `ban-console` هم در فهرست uidهای مجاز `SO_PEERCRED` است.

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

۱۰. Variant server — `ban-console`: رابط متنی (Rust + `ratatui`) روی tty1 و به‌طور اختیاری `ttyS0`، کلاینت همان socket Agent با `ban-api-types`؛ صفحه وضعیت بدون PIN، منوی مدیریت پشت همان PIN و session؛ متن انگلیسی. صفحه‌هایش هم‌پای Ban Center در مراحل ۶ تا ۱۲ اضافه می‌شوند.

معیار پذیرش

Maintenance → PIN → Ban Center باز می‌شود و وضعیت اتصال به Agent را نشان می‌دهد؛ قطع Agent → پیام خطای واضح و اتصال مجدد خودکار؛ خروج → بازگشت به Adad. در server: صفحه وضعیت روی tty1 → PIN → منوی `ban-console`؛ قطع Agent → پیام خطا و اتصال مجدد خودکار.

خروجی

اسکلت Ban Center روی Image، متصل به Ban Agent؛ اسکلت `ban-console` روی Variant server.

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

Variant server

همین قابلیت‌ها در `ban-console`: Dashboard متنی، Services (بدون Adad و CUPS)، Logs و Events، Support Bundle روی USB. ابزارهای اختیاری = `ban-tech-tools-cli` (فقط ابزارهای متنی).

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

Variant server

Ethernet، IP، DNS و Diagnostics در `ban-console` با همان rollback خودکار؛ تاریخ و ساعت؛ بدون نمایشگر، touch و صدا. برای سرور IP ثابت لازم است، چون Clientها به این آدرس وصل می‌شوند (wizard مرحله ۱۲). معیار: تنظیم Static IP فقط با صفحه‌کلید از `ban-console`؛ IP اشتباه → بازگشت خودکار. نقطه عطف M2 برای server: `ban-console` برای کارهای روزمره تکنسین قابل استفاده است.

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

Variant server

این مرحله را ندارد، جز پایش UPS با `nut`: رویداد قطع برق و خاموشی تمیز پیش از تمام شدن باتری (برای `pos` هم اختیاری).

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

Variant server

meta-package `ban-os-server` به‌جای `ban-os-pos`؛ Health check بدون Adad و چاپگر (PostgreSQL، اتصال TLS روی LAN، سرویس‌های Ban). پیش‌شرط نصب: پنجره زمانی و نبود تراکنش باز از Clientها، چون restart PostgreSQL همه صندوق‌ها را قطع می‌کند. ترتیب در فروشگاه چندصندوقه: اول Server (schema با `adad-db`)، بعد Clientها.

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

Variant server

همان پارتیشن‌بندی، Backup و Recovery؛ روی سرور Backup شبانه اجباری است و هشدار از ۲۴ ساعت (به‌جای ۴۸) شروع می‌شود، چون تنها نسخه داده فروشگاه آنجاست. رابط Recovery هر دو Variant همان `ban-console` در حالت recovery است (بدون X). آزمایش میدانی سرور به جفت‌سازی مرحله ۱۲ نیاز دارد و در Pilot مرحله ۱۳ انجام می‌شود.

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

Variant server

همان مدل؛ firewall همیشه قاعده نقش Server را دارد (5432 فقط از subnet فروشگاه)؛ SSH در production مثل `pos` نصب نیست؛ فهرست unitهای مجاز برای هر Variant جداست.

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

Variant server

همان نصب‌کننده با ISO خودش؛ wizard در `ban-console` بدون صفحه‌های نمایشگر، touch و سخت‌افزار و با نقش ثابت Server؛ کد جفت‌سازی به‌صورت QR متنی روی کنسول. خروجی اضافه: `.qcow2` برای نصب به‌صورت VM. معیار: نصب server (فیزیکی و VM) + دو Client `pos` در یک LAN و فروش هم‌زمان.

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

Variant server

ماتریس تست برای هر دو Variant؛ تست‌های مخصوص server: آپدیت و restart سرور حین فروش Clientها، قطع برق سرور، soak با چند Client هم‌زمان. هر دو ISO با یک `OS_VERSION` منتشر می‌شوند.

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

Variant server وابستگی‌ها را تغییر نمی‌دهد: `ban-console` در مرحله ۵ کنار Ban Center شروع می‌شود و در هر مرحله بعد صفحه‌های همان مرحله را می‌گیرد.

نقاط عطف

| نقطه عطف | پایان مرحله | نتیجه | Variant server |
| --- | --- | --- | --- |
| M1 | ۳ | بوت مستقیم به Adad | بوت headless، PostgreSQL سالم، وضعیت روی tty1 |
| M2 | ۷ | Ban Center قابل استفاده برای تکنسین | `ban-console` برای کارهای روزمره |
| M3 | ۱۰ | دستگاه آزمایشی در فروشگاه واقعی | — (سرور در فروشگاه به جفت‌سازی مرحله ۱۲ نیاز دارد؛ در Pilot مرحله ۱۳) |
| M4 | ۱۳ | نسخه Production | ISO و img هر دو Variant |

بعد از 1.0

این موارد آگاهانه بیرون از محدوده فعلی هستند و فقط جای اتصالشان حفظ شده است:

BC-10 — Ban Cloud Integration (مقصد `ban-sync`)

BC-11 — Fleet Management

محور Ban Desk — BD-01 تا BD-08 (صفحه Remote Support فعلاً placeholder است)

A/B Update و root فقط‌خواندنی کامل

Secure Boot و TPM

مدیریت Variant server از راه دور: Agent روی شبکه با mTLS، از Ban Center یک صندوق یا از Ban Cloud

Variant server: RAID نرم‌افزاری (mdadm)، WAL archiving و PITR، replica دوم

اصل اجرایی

هر مرحله باید با معیار پذیرش خودش روی QEMU یا سخت‌افزار واقعی بسته شود، بعد مرحله بعد شروع شود. هر وقت گفتی «مرحله N را بفرست»، جزئیات اجرایی همان مرحله (فایل‌ها، دستورها و کانفیگ‌ها) را باز می‌کنم.
