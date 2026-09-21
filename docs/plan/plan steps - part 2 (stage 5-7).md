نقشه اجرایی تفصیلی Ban OS — بخش ۲

مراحل ۵ تا ۷: پایه Ban Center، System / Services / Logs، شبکه و تنظیمات

پوشش: BC-01، BC-02، BC-03، BC-04، BC-06 از «plan p2» + صفحه‌های طراحی‌شده در «full-chat»

اصل حاکم (p2): «Ban Center باید به‌عنوان Control Plane سیستم‌عامل عمل کند، نه جایگزینی برای سرویس‌های استاندارد Linux.» و جدول full-chat §15:

| قابلیت | Backend | Ban Center |
| --- | --- | --- |
| Network / Wi-Fi | NetworkManager | UI |
| Services | systemd | UI |
| Logs | journald | UI |
| Printer | CUPS | UI |
| USB | udev | UI |
| Storage، CPU/RAM | ابزارهای Linux، `/proc` | UI |
| Updates | Ban Update Service | UI |
| Audit | Ban Event Service | UI |
| Firewall | nftables | UI |
| Remote | RustDesk (بعداً) | UI |

---

# الزامات مشترک همه صفحه‌ها (p2 «الزامات مشترک تمام فازها»)

این ده الزام یک‌بار در مرحله ۵ به‌صورت زیرساخت ساخته می‌شوند و هر صفحه بعدی فقط از آن استفاده می‌کند:

| الزام p2 | پیاده‌سازی |
| --- | --- |
| Role-Based Access Control | هر Tauri command و هر متد Agent یک `permission` دارد؛ کامپوننت `<Can permission="services.restart">` دکمه را پنهان/غیرفعال می‌کند؛ تصمیم نهایی همیشه در Agent |
| Auditability | middleware مرکزی Agent (مرحله ۴)؛ UI بعد از هر عملیات `event_id` را در toast نشان می‌دهد |
| Least Privilege | WebView بدون دسترسی OS؛ هسته Tauri بدون root؛ فقط Agent helperها root |
| Error Handling | کامپوننت واحد خطا: پیام فارسی + کد + `trace_id` + دکمه «کپی جزئیات» |
| Offline Tolerance | هیچ صفحه‌ای به اینترنت وابسته نیست؛ بخش‌های Cloud حالت «آفلاین — آخرین وضعیت در …» دارند |
| Consistency | هیچ state خوش‌بینانه؛ بعد از هر عملیات وضعیت واقعی دوباره از Agent خوانده می‌شود؛ polling ۲–۵ث روی صفحه فعال + subscription رویدادها |
| Confirmation | دیالوگ سه‌سطحی: ساده / با تایپ نام عملیات / با احراز هویت مجدد PIN |
| Observability | نوار پایین: وضعیت اتصال Agent، نسخه‌ها، `device_id`، ساعت |
| Localization | فارسی RTL پیش‌فرض + انگلیسی؛ اعداد فارسی در متن و لاتین در IP/نسخه؛ تاریخ جلالی با tooltip میلادی |
| Version Compatibility | در اتصال: مقایسه `AGENT_API_VERSION`؛ ناسازگار → صفحه «نسخه‌ها هم‌خوان نیستند — بروزرسانی لازم است» |

---

# مرحله ۵ — پایه Ban Center (BC-01)

## هدف

«ایجاد ساختار اولیه برنامه مدیریتی و زیرساخت ارتباطی آن با Ban Agent.» (p2)

## پوشش اقلام BC-01

| قلم p2 | گام |
| --- | --- |
| انتخاب فناوری رابط کاربری | ۵.۱ |
| ساختار پروژه Ban Center | ۵.۲ |
| معماری صفحات و Navigation | ۵.۵ |
| ارتباط با Ban Agent | ۵.۳ |
| مدیریت وضعیت برنامه | ۵.۴ |
| مدیریت خطاهای ارتباطی | ۵.۳ |
| مدل دسترسی اولیه | ۵.۶ |
| طراحی قالب بصری Ban OS | ۵.۷ |
| مدیریت تنظیمات برنامه | ۵.۸ |
| ساختار تست | ۵.۹ |

## گام ۵.۱ — فناوری

Tauri 2 (هسته Rust + WebKitGTK 4.1) · React 18 + TypeScript + Vite · مسیریابی `react-router` · داده: `@tanstack/react-query` (polling و cache) · state سبک: `zustand` · استایل: Tailwind با پلاگین RTL (logical properties) · کامپوننت‌ها: Radix UI primitives · نمودار: `recharts` · i18n: `i18next` · تاریخ جلالی: `date-fns-jalali` · فونت Vazirmatn داخل bundle (بدون CDN — دستگاه ممکن است آفلاین باشد).

## گام ۵.۲ — ساختار پروژه

ساختار p2 با همان لایه‌ها، منطبق بر Tauri:

```
center/ban-center/
├── package.json · vite.config.ts · VERSION
├── src-tauri/                         ← «infrastructure» + «app» در p2
│   ├── tauri.conf.json · capabilities/default.json
│   └── src/
│       ├── main.rs · bootstrap.rs
│       ├── agent_client/              ← ban-agent-client، ipc، serialization
│       ├── commands/                  ← یک فایل برای هر حوزه: system network services …
│       ├── session/ · permissions/ · config/ · error.rs
├── src/
│   ├── app/            bootstrap · router · providers
│   ├── domain/         devices services events updates permissions   ← typeها از ban-api-types
│   ├── application/    hookهای هر حوزه: useSystem useNetwork useServices …
│   ├── ui/
│   │   ├── shell/ navigation/
│   │   ├── dashboard/ system/ network/ services/ hardware/ logs/
│   │   ├── updates/ recovery/ users/ support/ settings/
│   │   └── components/   Button Card StatusDot DataTable ConfirmDialog PinPad OnScreenKeyboard ErrorPanel Can
│   ├── resources/      icons themes fonts translations(fa.json en.json)
├── tests/ unit/ integration/ ui/
└── packaging/ desktop-entry/ systemd/(ban-center.service) deb/
```

## گام ۵.۳ — ارتباط با Agent و خطاهای ارتباطی

- `agent_client` (tokio `UnixStream`): یک اتصال پایدار، درخواست‌های هم‌زمان با `id`، timeout پیش‌فرض ۵ث (عملیات طولانی مثل Backup: job-based → `job.status(id)` با درصد پیشرفت).
- reconnect با backoff (۰٫۵ث → ۸ث)؛ وضعیت اتصال به فرانت‌اند event می‌شود.
- subscription: `events.subscribe` → رویدادهای زنده برای Dashboard و Log Viewer.
- حالت‌های UI: `connected` · `reconnecting` (نوار زرد، داده‌ها خاکستری و «آخرین بروزرسانی …») · `agent_down` (صفحه کامل: وضعیت `ban-agent.service` + دکمه «تلاش برای راه‌اندازی مجدد» از طریق helper محدود) · `incompatible`.
- مرز امنیتی: `capabilities/default.json` فقط commandهای خود برنامه؛ پلاگین‌های `shell`، `fs`، `http` نصب نمی‌شوند؛ CSP = `default-src 'self'`؛ بدون `dangerousRemoteDomainIpcAccess`؛ همه ورودی‌ها در Rust دوباره validate می‌شوند.

## گام ۵.۴ — مدیریت وضعیت

| نوع state | جا |
| --- | --- |
| داده دستگاه (منبع حقیقت = Agent) | react-query با `staleTime` کوتاه؛ هرگز در localStorage |
| session (نقش، انقضا) | هسته Rust؛ فرانت‌اند فقط نقش و زمان باقی‌مانده را می‌بیند، نه token |
| UI (زبان، theme، آخرین صفحه) | `~/.config/ban-center/ui.json` |

## گام ۵.۵ — صفحات و Navigation (p2 «ساختار پیشنهادی صفحات»)

Sidebar راست با ۱۱ بخش؛ هر بخش تب‌های داخلی. نقشه کامل و مرحله ساخت:

| بخش | زیرصفحه‌ها (p2) | مرحله |
| --- | --- | --- |
| Dashboard | System Overview · Device Health · Service Status · Network Status · Recent Events | ۶ |
| System | Overview · Performance · Storage · Processes · Device Information | ۶ |
| Network | Overview · Ethernet · Wi-Fi · IP Configuration · Diagnostics | ۷ |
| Services | All Services · Ban Services · Adad Services · Service Details | ۶ |
| Hardware | Overview · Printers · Barcode Scanner · Cash Drawer · Customer Display · Scale · Payment Terminal | ۸ |
| Logs & Audit | System · Application · Security · Support · Update · Audit | ۶ |
| Updates | Current Versions · Available Updates · Update History · Update Settings | ۹ |
| Backup & Recovery | Backup Status · Create Backup · Restore · Recovery | ۱۰ |
| Users & Access | Users · Roles · Permissions · Sessions | ۱۱ |
| Remote Support | Ban Desk Status · Connection Status · Active Session · Support History | placeholder («به‌زودی») + دکمه Support Bundle |
| Settings | General · Security · Cloud · Maintenance (+ Date & Time · Display · Sound · Optional Tools در مرحله ۶ و ۷) | ۷ |

در این مرحله همه مسیرها با صفحه خالی «در دست ساخت» وجود دارند تا Navigation کامل تست شود.

## گام ۵.۶ — مدل دسترسی اولیه

- صفحه PIN تمام‌صفحه (کامپوننت `PinPad`، دکمه‌های ≥ ۶۴px): `auth.login(pin)` → نقش. در این مرحله دو نقش: `Technician` و `Admin`؛ پنج نقش کامل p2 در مرحله ۱۱.
- PIN اولیه: در production هیچ PIN پیش‌فرضی نیست؛ در First-boot wizard ساخته می‌شود (مرحله ۱۲). تا آن زمان فقط Profile `development` PIN ثابت دارد.
- ۵ تلاش ناموفق → قفل ۵ دقیقه‌ای (تصاعدی) + `MAINTENANCE_LOGIN_FAILED` / `ACCOUNT_LOCKED`.
- session: انقضای بی‌کاری ۱۰ دقیقه → بازگشت به صفحه PIN؛ «خروج» → `auth.logout` → `MAINTENANCE_EXITED` → Adad دوباره بالا می‌آید.
- جایگزینی xterm موقت مرحله ۳ با Ban Center.

## گام ۵.۷ — قالب بصری Ban OS

- design tokens در `theme/tokens.css`: رنگ‌های برند، وضعیت‌ها (● سبز Running/Connected · ● زرد Warning · ● قرمز Error · ○ خاکستری Unknown — همان نشانه‌های طرح‌های full-chat)، شعاع، فاصله‌ها.
- هدف‌های touch ≥ ۴۸px، فونت پایه ۱۶–۱۸px، کنتراست بالا (نور فروشگاه)، بدون hover-only.
- حداقل رزولوشن پشتیبانی‌شده: 1024×768؛ تست روی 1366×768 و 1920×1080 و حالت عمودی.
- پنجره: `fullscreen: true`، `decorations: false`؛ در production: بدون context menu، devtools، zoom، text-selection روی عناصر کنترلی، drag تصویر.
- `OnScreenKeyboard`: فارسی/انگلیسی/عدد، خودکار روی focus فیلدها (PIN، رمز Wi-Fi، IP).

## گام ۵.۸ — تنظیمات برنامه

`/etc/ban/center.toml`: زبان پیش‌فرض، timeout بی‌کاری، رفتار Adad هنگام Maintenance (توقف/ادامه)، بازه polling، مسیر socket. فقط‌خواندنی برای برنامه؛ تغییر از طریق Agent.

## گام ۵.۹ — تست و بسته‌بندی

- Rust: unit test برای `agent_client` با Agent ساختگی (mock socket)؛ React: Vitest + Testing Library؛ UI: Playwright روی build وب با Agent mock؛ integration واقعی در VM (`tests/integration/center/`).
- `mock-agent`: یک binary کوچک در workspace که همان API را با داده ساختگی پاسخ می‌دهد ← توسعه UI روی Windows بدون VM ممکن می‌شود.
- بسته: `ban-center_<ver>_amd64.deb` (Tauri bundler)، `Depends: libwebkit2gtk-4.1-0, libgtk-3-0, ban-agent (>= x)`؛ نصب در `/opt/ban/center`؛ user unit `ban-center.service` با `Conflicts=adad-launcher.service`.
- سنجش روی ضعیف‌ترین سخت‌افزار هدف: زمان باز شدن (هدف < ۳ث)، RAM (هدف < ۳۰۰MB). اگر WebKitGTK روی GPU قدیمی مشکل داشت: `WEBKIT_DISABLE_COMPOSITING_MODE=1`.

## معیار پذیرش

Maintenance → PIN → Ban Center با Navigation کامل · stop کردن `ban-agent` → حالت `agent_down` و بازگشت خودکار · خروج → Adad · نسخه ناسازگار Agent → صفحه incompatible.

## خروجی

«یک نسخه اولیه از Ban Center که می‌تواند به Ban Agent متصل شود و ساختار اصلی پنل را نمایش دهد.» (p2)

---

# مرحله ۶ — System، Services، Logs (BC-02، BC-04، BC-06)

ترتیب داخلی: اول همه‌چیز فقط‌خواندنی (۶.۱ تا ۶.۴)، سپس عملیات (۶.۵ به بعد).

## ۶.۱ — BC-02 System Management

هدف (p2): «ارائه نمای کلی از وضعیت سیستم‌عامل و منابع سخت‌افزاری دستگاه.»

پوشش همه ۱۴ قلم p2:

| قلم p2 | متد Agent | منبع |
| --- | --- | --- |
| وضعیت CPU | `system.cpu` | `/proc/stat`، `sysinfo` — درصد کل و هر core، load |
| وضعیت RAM | `system.memory` | `/proc/meminfo` |
| فضای ذخیره‌سازی | `system.storage` | `statvfs` هر پارتیشن + `du` زمان‌بندی‌شده مسیرهای Ban |
| دمای سیستم | `system.temperature` | `/sys/class/hwmon`، `/sys/class/thermal` |
| مدت زمان روشن بودن | `system.info.uptime` | `/proc/uptime` |
| وضعیت بوت | `system.boot` | `systemd-analyze` + آخرین `SYSTEM_BOOT`/`SYSTEM_CRASH` + bootcount |
| وضعیت سیستم‌عامل | `system.info.os` | `/etc/ban/release`، `systemctl is-system-running` (running/degraded) |
| اطلاعات Kernel | `system.info.kernel` | `uname` |
| اطلاعات دستگاه | `system.device` | DMI (`/sys/class/dmi/id`): سازنده، مدل، سریال · CPU model · RAM · دیسک · `device_id`، Store/Terminal |
| وضعیت اتصال برق | `system.power` | `/sys/class/power_supply` (AC/باتری/UPS اگر باشد؛ وگرنه «نامشخص») |
| وضعیت نمایشگر | `system.displays` | `xrandr --query` از session: خروجی‌ها، رزولوشن، چرخش، touch device |
| وضعیت عملکرد سیستم | `system.metrics(range)` | `metrics.db` (مرحله ۴) — نمودار ۱ساعت/۲۴ساعت/۷روز |
| فرآیندهای فعال | `system.processes` | `/proc` — ۲۰ فرآیند برتر CPU/RAM؛ فقط نمایش (kill فقط برای Admin و فقط فرآیندهای غیرسیستمی) |
| هشدارهای سیستمی | `system.alerts` | رویدادهای WARNING+ بازنشده + واحدهای failed + آستانه‌ها |

صفحات (p2): **System Overview** · **Device Information** · **Resource Usage** · **Performance** · **System Health**.

Device Information (طرح full-chat):

```
Ban OS       1.2.0          Kernel       6.x
Adad         5.2.1          Architecture x86_64
Agent / API  1.0.0 / 1.0    Uptime       3d 12h
CPU          Intel N100     RAM 8 GB     Disk 128 GB
Device ID    BAN-8F92A1     Store 1024 · Terminal 03
```

**Dashboard** (طرح full-chat §1): کارت‌های CPU / Memory / Disk / Temperature + وضعیت Network، Internet، Adad، PostgreSQL، (RustDesk: «غیرفعال») + «Recent Events» زنده (۱۰ رویداد آخر INFO+). هر کارت به صفحه تفصیلی لینک است. یک «نشان سلامت کلی» (سالم / نیاز به توجه / بحرانی) از `system.alerts`.

**Storage** (طرح full-chat §11): کل / استفاده‌شده / آزاد + تفکیک Database · Logs · Cache · Backups · System؛ هشدار > ۸۰٪ (`DISK_SPACE_WARNING`)؛ دکمه «پاک‌سازی Cache و لاگ‌های قدیمی» (Technician، با تأیید).

خروجی (p2): «مدیر یا تکنسین وضعیت کلی دستگاه را از یک صفحه مشاهده و مشکلات اولیه را شناسایی کند.»

## ۶.۲ — BC-04 Service Management

هدف (p2): «مشاهده و مدیریت سرویس‌های Ban OS و سرویس‌های موردنیاز POS.»

سرویس‌های هدف (p2): Adad POS · Adad Launcher · Ban Agent · Ban Event · Ban Sync · Ban Update · Ban Desk (رزرو) · CUPS · NetworkManager · + PostgreSQL · Ban Hardware · Ban Metrics · timesyncd.

فهرست در `/etc/ban/services.toml` (نه کشف خودکار همه unitهای سیستم):

```TOML
[[service]]
unit = "postgresql@17-main.service"
title_fa = "پایگاه داده"
group = "adad"            # ban | adad | system
scope = "system"          # system | user
critical = true
allow = ["restart"]       # start stop restart enable disable
min_role = "technician"
```

| قابلیت p2 | متد | جزئیات |
| --- | --- | --- |
| مشاهده وضعیت سرویس | `services.list` / `services.get` | D-Bus `org.freedesktop.systemd1`: ActiveState، SubState، Result |
| زمان آخرین اجرا | همان | `ActiveEnterTimestamp`، تعداد restart (`NRestarts`) |
| مشاهده خطاهای سرویس | `services.logs(unit, n)` | journal همان unit، فقط priority ≤ err + ۵۰ خط آخر |
| شروع / توقف / Restart | `services.start|stop|restart` | فقط اگر در `allow`؛ سرویس user از طریق session bus کاربر `adad` |
| فعال/غیرفعال بودن Startup | `services.set_enabled` | فقط Admin |
| مشاهده وابستگی‌ها | `services.get.deps` | `Requires` / `Wants` / `After` — نمایش درختی ساده |
| وضعیت Health Check | `services.get.health` | watchdog + probe اختصاصی (`pg_isready`، `agent.ping`، …) |
| ثبت عملیات مدیریتی | middleware | `SERVICE_*_BY_USER` با actor |

کنترل دسترسی (p2): «توقف Adad، تغییر Startup یا Restart سرویس‌های حیاتی نیازمند سطح دسترسی مناسب»:

| عملیات | نقش | تأیید |
| --- | --- | --- |
| Restart سرویس غیرحیاتی (CUPS، ban-sync) | Technician | ساده |
| Restart سرویس حیاتی (Adad، PostgreSQL، NetworkManager) | Technician | تایپی + هشدار «فروش در حال انجام قطع می‌شود» |
| Stop سرویس حیاتی، تغییر Startup | Admin | احراز هویت مجدد |
| Restart `ban-agent` | Admin | UI اعلام قطع موقت می‌کند و خودکار وصل می‌شود |
| `ban-event` | هیچ‌کس (فقط نمایش) | — |

صفحات: All Services · Ban Services · Adad Services · Service Details (وضعیت، زمان‌ها، وابستگی‌ها، health، لاگ اخیر، دکمه‌ها).

خروجی (p2): «تکنسین وضعیت سرویس‌ها را بررسی و عملیات مجاز را از طریق رابط کنترل‌شده انجام دهد.»

## ۶.۳ — BC-06 Logs & Audit

هدف (p2): «یک مرکز مشاهده و بررسی رویدادهای سیستم، نرم‌افزار، امنیت و عملیات مدیریتی.»

منابع (full-chat §7): System Logs ← journald · Application Logs ← `/var/log/adad` + journal واحد adad · Audit و بقیه ← Ban Event DB.

| دسته p2 | منبع | فیلتر |
| --- | --- | --- |
| System Logs | journald | `_TRANSPORT=kernel`، unitهای سیستم |
| Application Logs | journald + فایل‌های Adad | `adad*`، `ban-center` |
| Hardware Logs | events | `category=HARDWARE` |
| Network Logs | events + journal NetworkManager | `category=NETWORK` |
| Security Logs | events | `category=SECURITY` — حداقل نقش: Admin |
| Support Logs | events | `category=SUPPORT` (تا Ban Desk: Support Bundleها) |
| Update Logs | events | `category=UPDATE` |
| Audit Logs | events | `is_audit=1` — حداقل نقش: Manager (فقط خواندن) |

| قابلیت p2 | پیاده‌سازی |
| --- | --- |
| فهرست رویدادها | `DataTable` مجازی‌سازی‌شده؛ صفحه‌بندی cursor-based (`events.query{before_id, limit}`) |
| جست‌وجو | متن در `event_type`/`metadata`/`actor_id`؛ برای journal: `--grep` |
| فیلتر نوع / شدت / بازه زمانی | چیپ‌های دسته، حداقل Severity، «امروز / ۲۴ساعت / ۷روز / بازه دلخواه (تقویم جلالی)» |
| جزئیات رویداد | پنل کناری: همه فیلدها + metadata قالب‌بندی‌شده + رویدادهای هم‌`session_id` |
| شناسه دستگاه / عامل | ستون actor با آیکون نقش؛ `device_id` در جزئیات و در Export |
| خروجی گرفتن | `logs.export{filter, format: jsonl|csv}` → USB (از طریق Agent، نه WebView) → `LOG_EXPORTED` (Audit) |
| گزارش خطاهای مهم | تب «مهم‌ها»: ERROR و CRITICAL هفت روز اخیر، گروه‌بندی بر اساس نوع با شمارش |
| وضعیت همگام‌سازی | ستون ✓/⏳ از `synced_at` + خلاصه `sync.status` بالای صفحه |
| محدودسازی رویدادهای حساس | فیلتر نقش در Agent (نه UI) |
| صحت Audit | دکمه «بررسی زنجیره» → `events.verify_chain` → سالم / اولین ردیف ناسازگار |

حالت «زنده» (tail) با `events.subscribe` و `logs.follow`. نمای خط زمانی دستگاه مثل طرح full-chat §9 (`10:41 Sync completed · 10:32 System boot · 09:57 Adad crashed …`) در Dashboard و در Audit.

متدها: `events.query` · `events.get` · `events.subscribe` · `events.verify_chain` · `logs.query` (پوشش `journalctl -o json` با فیلترهای whitelist‌شده؛ هیچ آرگومان آزاد) · `logs.follow` · `logs.export` · `sync.status`.

خروجی (p2): «یک Log Viewer و Audit Viewer یکپارچه…»

## ۶.۴ — Support Bundle

تا Ban Desk ساخته نشده، این مهم‌ترین ابزار پشتیبانی است. `support.create_bundle{target: usb|local}` →

```
ban-support-BAN-8F92A1-14050629-1042.tar.zst
├── manifest.json        (device_id، نسخه‌ها، زمان، سازنده)
├── system.json          (system.info، device، storage، displays، power)
├── services.json · network.json (بدون رمز Wi-Fi) · hardware.json
├── events.jsonl         (۳۰ روز)
├── journal.txt          (۷ روز، priority ≤ info)
├── adad-logs/ · config/ (همه *.toml با REDACT کلیدهای حساس)
└── metrics.json
```

بدون dump دیتابیس و بدون داده مشتری. رویداد `SUPPORT_BUNDLE_CREATED`. دکمه در صفحه Remote Support و Dashboard.

## ۶.۵ — ابزارهای اختیاری تکنسین

تصمیم: ابزارها در Image نیستند و تکنسین در صورت نیاز نصب می‌کند.

| مورد | جزئیات |
| --- | --- |
| بسته | meta-package `ban-tech-tools`: `xterm` `nano` `pcmanfm` `htop` `postgresql-client` (psql) `tcpdump` `nmap`؛ pgAdmin جدا و اختیاری (`ban-tech-pgadmin`) |
| صفحه | Settings → Optional Tools: فهرست، وضعیت نصب، حجم، نصب/حذف |
| متد | `tools.list` · `tools.install(name)` · `tools.remove(name)` — فقط نام‌های whitelist در `/etc/ban/tools.toml`؛ هرگز apt آزاد |
| منبع | مخزن apt Ban (مرحله ۹)؛ تا آن زمان و برای دستگاه آفلاین: فایل `.banpkg` امضاشده روی USB |
| اجرا | فقط داخل Maintenance، از منوی «ابزارها» در Ban Center؛ ترمینال با کاربر `maintenance`؛ هر اجرا → `TOOL_LAUNCHED` |
| نقش | نصب/حذف: Technician · ترمینال: Technician با احراز هویت مجدد |
| پاک‌سازی | گزینه «حذف خودکار ابزارها هنگام خروج از Maintenance» (پیش‌فرض روشن در production) |
| رویداد | `TOOLS_INSTALLED` · `TOOLS_REMOVED` |

## تست‌های مرحله ۶

داده هر کارت Dashboard با مقدار واقعی (`free`، `df`، `sensors`) مقایسه می‌شود · Restart CUPS از UI → وضعیت واقعی + رویداد Audit با actor درست · Technician نمی‌تواند Adad را Stop کند (`FORBIDDEN` + رویداد) · Export روی USB · دست‌کاری دستی یک ردیف audit.db → «بررسی زنجیره» خطا می‌دهد · ۱۰۰هزار رویداد → جدول روان می‌ماند.

## معیار پذیرش

تکنسین بدون ترمینال می‌تواند: سلامت دستگاه را ببیند، سرویس را Restart کند، علت یک crash را در لاگ پیدا کند، Support Bundle بسازد.

---

# مرحله ۷ — شبکه و تنظیمات (BC-03)

## هدف

«مدیریت تنظیمات شبکه از طریق رابط اختصاصی Ban Center، با استفاده از NetworkManager به‌عنوان سرویس زیرساختی.» (p2) — مرز مسئولیت (p2): «Ban Center رابط کاربری شبکه است؛ NetworkManager وظیفه مدیریت واقعی را بر عهده دارد.»

تفکیک full-chat §14: Linux مسئول NetworkManager، DHCP، Wi-Fi، Ethernet، DNS، routing · Ban Center مسئول Display، Configure، Test، Diagnose.

## پوشش همه ۱۵ قلم p2

| قلم p2 | متد Agent (روی D-Bus `org.freedesktop.NetworkManager` با `zbus`) |
| --- | --- |
| Ethernet | `network.devices` / `network.device(id)` |
| Wi-Fi | `network.wifi.scan` · `network.wifi.list` |
| DHCP | `network.set_ipv4{method: "auto"}` |
| Static IP، Gateway، DNS | `network.set_ipv4{method:"manual", address, prefix, gateway, dns[]}` |
| اتصال و قطع شبکه | `network.connect(id)` · `network.disconnect(id)` |
| مدیریت شبکه‌های Wi-Fi | `network.wifi.connect{ssid, psk, hidden}` · `network.wifi.forget(ssid)` · `network.wifi.set_autoconnect` |
| مشاهده IP و MAC | `network.device(id)` |
| بررسی اتصال اینترنت | `network.diag.internet` (NM connectivity check + HTTPS به endpoint خودمان) |
| تست DNS | `network.diag.dns(host)` |
| تست Gateway | `network.diag.gateway` (ping ×۴: loss و latency) |
| وضعیت اتصال به Ban Cloud | `network.diag.cloud` — تا مرحله Cloud: «پیکربندی نشده» |
| وضعیت اتصال به سرویس‌های موردنیاز | `network.diag.endpoints` — فهرست در `/etc/ban/endpoints.toml`: مخزن آپدیت، NTP، سرور Adad، (در نقش Client) صندوق Server پورت 5432 |
| تنظیمات شبکه در Maintenance | همه متدهای تغییردهنده فقط با session نقش Technician+ |

## صفحات (p2) و طرح‌ها (full-chat §3)

**Network Overview**

```
Ethernet   ● Connected     192.168.1.25/24   MAC 00:1A:…
Wi-Fi      ○ Disconnected
Gateway    192.168.1.1     DNS 192.168.1.1, 1.1.1.1
Internet   ● Connected     Ban Cloud  — پیکربندی نشده
نقش دستگاه: Server (۲ صندوق Client متصل)
```

**Ethernet Settings / IP Configuration**: انتخاب `[DHCP ▼ | Static]`، فیلدهای IP / Prefix / Gateway / DNS با اعتبارسنجی در لحظه و صفحه‌کلید عددی، دکمه Apply.

**Wi-Fi Settings**: فهرست شبکه‌ها با قدرت سیگنال و قفل · Connect (رمز با صفحه‌کلید لمسی، دکمه نمایش رمز) · Disconnect · Forget · Configure (IP دستی برای هر شبکه) · شبکه مخفی.

**Connection Diagnostics**: دکمه «اجرای همه تست‌ها» → چک‌لیست مرحله‌ای: لینک فیزیکی ← IP ← Gateway ← DNS ← اینترنت ← سرویس‌های Ban؛ هر ردیف ✓/✗ با راهنمای فارسی («کابل شبکه را بررسی کنید»). نتیجه قابل افزودن به Support Bundle.

**Cloud Connectivity**: placeholder تا BC-10.

## محافظ تغییر شبکه (rollback خودکار)

۱. Agent نسخه فعلی connection را نگه می‌دارد. ۲. تنظیم جدید اعمال می‌شود (NM checkpoint: `CheckpointCreate` با `rollback_timeout=30`). ۳. UI شمارش معکوس «اتصال برقرار است؟ [تأیید]» نشان می‌دهد و هم‌زمان Gateway را تست می‌کند. ۴. تأیید → `CheckpointDestroy`؛ بدون تأیید یا تست ناموفق → NM خودکار به قبل برمی‌گردد. ۵. `NETWORK_CONFIG_CHANGED` با old/new (رمز Wi-Fi همیشه REDACTED) و نتیجه (`applied` / `rolled_back`).

اهمیت: در آینده که پشتیبانی از راه دور می‌آید، IP اشتباه = از دست رفتن دستگاه؛ و همین حالا در نقش Client = قطع اتصال به صندوق Server.

## نقش دستگاه در شبکه (PostgreSQL)

- نمایش نقش فعلی Standalone / Server / Client (از `/etc/ban/pos.toml`).
- Server: هشدار اگر IP روی DHCP است («IP ثابت توصیه می‌شود چون صندوق‌های دیگر به این آدرس وصل می‌شوند»)؛ نمایش Clientهای متصل (`pg_stat_activity`).
- Client: آدرس Server + تست اتصال 5432 + تأخیر.
- تغییر نقش: `device.set_role` — فقط Admin، احراز هویت مجدد، رویداد `DEVICE_ROLE_CHANGED`؛ جزئیات فنی در مراحل ۱۱ و ۱۲.

## صفحه Settings (پاسخ full-chat: «Network، Wi-Fi، ساعت، نمایشگر، صدا… را از صفر نساز؛ Ban Center فقط Control Panel باشد»)

| زیرصفحه | محتوا | Backend |
| --- | --- | --- |
| General | زبان، نام نمایشی دستگاه، Store/Terminal (فقط نمایش) | `center.toml`، `device.toml` |
| Date & Time | ساعت فعلی (جلالی + میلادی)، منطقه زمانی، وضعیت NTP، تنظیم دستی اگر NTP در دسترس نیست (Admin)، وضعیت RTC | `org.freedesktop.timedate1` |
| Display | رزولوشن، چرخش ۰/۹۰/۱۸۰/۲۷۰، روشنایی (اگر backlight باشد)، انتخاب نمایشگر اصلی/مشتری، **کالیبره touch** (اجرای `xinput_calibrator` و ذخیره ماتریس)، تست touch (صفحه نقاشی) — با همان الگوی «تأیید در ۱۵ث یا بازگشت» | `display.toml` + `apply-display` |
| Sound | میزان صدا، صدای بوق اسکن/خطا، تست | ALSA / PipeWire |
| Security | وضعیت Firewall (`nft list ruleset` خلاصه — فقط نمایش)، سیاست USB (نمایش)، زمان قفل session | مرحله ۱۱ |
| Maintenance | رفتار Adad هنگام Maintenance، حذف خودکار ابزارها، Reboot / Shutdown (با تأیید و رویداد) | `center.toml`، logind |
| Optional Tools | مرحله ۶.۵ | — |
| Cloud | placeholder | — |

## تست‌های مرحله ۷

DHCP ↔ Static و برگشت · IP اشتباه عمدی → rollback در ۳۰ث · Wi-Fi با رمز فارسی/نمادها از صفحه‌کلید لمسی · شبکه مخفی · کشیدن کابل → Overview در < ۳ث بروز و `NETWORK_DISCONNECTED` ثبت می‌شود · Diagnostics با DNS خراب → تشخیص درست مرحله خرابی · چرخش صفحه + کالیبره touch روی دستگاه واقعی · Operator/Manager به تغییر شبکه دسترسی ندارد.

## معیار پذیرش

تنظیم Static IP و اتصال به Wi-Fi رمزدار فقط با touch و بدون ترمینال؛ تنظیم اشتباه خودکار برمی‌گردد.

## خروجی

«تکنسین بتواند تنظیمات شبکه و مشکلات اتصال را بدون نیاز به استفاده مستقیم از ترمینال مدیریت کند.» (p2) — **نقطه عطف M2**
