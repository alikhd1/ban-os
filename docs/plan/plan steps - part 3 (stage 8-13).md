نقشه اجرایی تفصیلی Ban OS — بخش ۳

مراحل ۸ تا ۱۳: سخت‌افزار، بروزرسانی، Recovery، امنیت، نصب‌کننده، انتشار

پوشش: OS-05 تا OS-10 از «plan p1» · BC-05، BC-07، BC-08، BC-09، BC-12 از «plan p2» · جزئیات «full-chat»

---

# مرحله ۸ — سخت‌افزار (OS-05 + BC-05)

## هدف

«ایجاد لایه استاندارد برای شناسایی، پیکربندی و تعامل با تجهیزات مختلف پایانه فروش، بدون وابستگی مستقیم برنامه Adad به جزئیات هر سخت‌افزار.» (p1) + «مشاهده، پیکربندی و تست تجهیزات متصل» (p2)

## معماری (full-chat §23 و §25)

```
Adad POS ─┐                         ┌─ Printer adapter ── CUPS / ESC-POS raw ── USB · Network · Serial
          ├─ Hardware API ─ ban-hardware ─┼─ CashDrawer ── از طریق چاپگر (RJ11) یا مستقل
Ban Center ─ ban-agent ─┘           ├─ Scanner ── HID (evdev) · Serial
                                    ├─ CustomerDisplay ── Serial VFD · نمایشگر دوم X
                                    ├─ Scale ── Serial / USB-Serial
                                    └─ PaymentTerminal ── Serial / TCP
```

`ban-hardware` = سرویس Rust با socket `/run/ban/hardware.sock` و `HARDWARE_API_VERSION` مستقل (full-chat §35). دلیل (full-chat): «این بهتر از این است که کل منطق سخت‌افزار داخل UI باشد.»

## پوشش اقلام OS-05

| قلم p1 | گام |
| --- | --- |
| شناسایی سخت‌افزار | ۸.۱ |
| مدیریت اتصال و قطع اتصال | ۸.۱ |
| تنظیمات دستگاه‌ها / Hardware Configuration | ۸.۲ |
| تست سخت‌افزار | ۸.۶ |
| مدیریت خطا | ۸.۳ |
| لایه Driver/Adapter | ۸.۳، ۸.۴، ۸.۵ |
| ثبت رویدادهای سخت‌افزاری | ۸.۱، ۸.۳ |
| سازگاری با مدل‌های مختلف | ۸.۷ |

سخت‌افزارهای هدف p1: صفحه لمسی (مرحله ۲ و ۷) · چاپگر رسید · بارکدخوان · کشوی پول · نمایشگر مشتری · ترازو · کارت‌خوان · پورت‌های USB و Serial · تجهیزات شبکه · تجهیزات اختصاصی تولیدکنندگان.

## گام ۸.۱ — شناسایی و hotplug (full-chat §24)

- `ban-hardware` به udev monitor گوش می‌دهد (subsystemهای `usb`، `tty`، `input`، `usbmisc`، `drm`).
- ruleها در `/etc/udev/rules.d/70-ban-*.rules` با Vendor ID / Product ID / Serial → symlink پایدار تا «`/dev/ttyUSB0` وابستگی شکننده‌ای نباشد»:

```
SUBSYSTEM=="usbmisc", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5743", SYMLINK+="ban-printer", GROUP="lp", TAG+="ban"
SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", ATTRS{serial}=="…", SYMLINK+="ban-scale", GROUP="dialout", TAG+="ban"
```

- ruleهای عمومی از پایگاه `hardware/db/devices.toml` (VID:PID → نوع و adapter پیشنهادی) تولید می‌شوند؛ rule اختصاصی هر دستگاه وقتی تکنسین در Ban Center دستگاه را «اختصاص» می‌دهد نوشته می‌شود.
- هر اتصال/قطع → `*_CONNECTED` / `*_DISCONNECTED`؛ دستگاه ناشناخته → `USB_DEVICE_UNKNOWN` (NOTICE).

## گام ۸.۲ — `/etc/ban/hardware.toml`

```TOML
[printer.receipt]
adapter = "escpos"          # escpos | cups
connection = "usb"          # usb | network | serial
device = "/dev/ban-printer" # یا host = "192.168.1.50:9100"
width_dots = 576            # 80mm=576 · 58mm=384
cut = true
default = true

[cash_drawer.main]
adapter = "via-printer"
printer = "receipt"
pin = 2

[scanner.main]
adapter = "hid"
suffix = "enter"

[customer_display.main]
adapter = "second-screen"   # second-screen | vfd-serial

[scale.main]
adapter = "generic-serial"
device = "/dev/ban-scale"
baud = 9600
protocol = "…"
```

نوشتن فقط از طریق Agent (`CONFIG_CHANGED` / `PRINTER_CONFIG_CHANGED`).

## گام ۸.۳ — رابط استاندارد و مدیریت خطا

طرح full-chat (`class ReceiptPrinter` با پیاده‌سازی‌های Epson / XPrinter / Zebra / GenericESC) به trait تبدیل می‌شود:

| دستگاه | متدهای API |
| --- | --- |
| Printer | `printer.list` · `printer.status` (ready / offline / paper_low / paper_out / cover_open / error) · `printer.print_receipt{doc}` · `printer.print_raw` · `printer.test` · `printer.cut` |
| CashDrawer | `drawer.open{reason}` · `drawer.status` (اگر سنسور دارد) |
| Scanner | `scanner.list` · `scanner.subscribe` (برای تست؛ در حالت عادی HID مستقیم به Adad تایپ می‌کند) |
| CustomerDisplay | `cdisplay.show{lines|view}` · `cdisplay.clear` · `cdisplay.test` |
| Scale | `scale.read` → `{weight, unit, stable}` · `scale.tare` · `scale.zero` |
| PaymentTerminal | `payment.status` · `payment.test_link` — فقط تست ارتباط؛ تراکنش بانکی در Adad و طبق پروتکل PSP می‌ماند و هیچ داده کارتی وارد لاگ نمی‌شود |

خطاها: کدهای ثابت (`DEVICE_NOT_FOUND` `DEVICE_BUSY` `PAPER_OUT` `TIMEOUT` `IO_ERROR`) + پیام فارسی؛ صف چاپ با retry؛ خطا → `PRINTER_ERROR` با شمارنده؛ هیچ خطای سخت‌افزاری نباید Adad را متوقف کند (چاپ ناموفق = هشدار + امکان چاپ مجدد).

## گام ۸.۴ — دور اول Adapterها

| Adapter | جزئیات |
| --- | --- |
| چاپگر ESC/POS USB/Network/Serial | ارسال raw به `/dev/usb/lp*`، TCP 9100 یا tty؛ خواندن وضعیت با `DLE EOT`؛ CUPS فقط برای چاپگرهای غیر ESC/POS (A4، لیبل) |
| **چاپ فارسی** | رسید در `ban-hardware` از یک مدل ساده (خط، جدول، بارکد، QR، لوگو) با shaping و BiDi درست و فونت Vazirmatn به bitmap رندر و با `GS v 0` ارسال می‌شود. دلیل: codepage فارسی بین برندها ناسازگار است و حروف جدا/برعکس چاپ می‌شوند. هزینه: چاپ کمی کندتر — با cache لوگو و سرصفحه جبران می‌شود |
| کشوی پول | فرمان `ESC p m t1 t2` از طریق چاپگر (full-chat: «معمولاً از طریق Printer RJ11/RJ12») → `CASH_DRAWER_OPENED` با actor و reason (Audit) |
| بارکدخوان HID | نیاز به driver ندارد (full-chat: «USB HID Keyboard»)؛ فقط شناسایی، نام‌گذاری و تست؛ نکته: layout صفحه‌کلید فارسی نباید خروجی اسکنر را خراب کند ← اسکنر با evdev grab اختیاری یا اجبار layout انگلیسی برای آن device |
| صفحه لمسی | libinput؛ کالیبره و نقشه به نمایشگر (مرحله ۷) |

## گام ۸.۵ — دور دوم Adapterها

نمایشگر مشتری (نمایشگر دوم X با یک پنجره ساده تمام‌صفحه؛ VFD سریال ۲×۲۰) · ترازو (پروتکل‌های رایج سریال؛ خواندن پایدار) · پایانه پرداخت (فقط link test) · RFID (در full-chat آمده؛ به‌صورت HID مثل اسکنر). هر adapter جدید = یک فایل در `hardware/<type>/` + یک ردیف در `devices.toml` + تست.

## گام ۸.۶ — BC-05 صفحات Hardware

پوشش اقلام p2:

| قلم p2 | UI |
| --- | --- |
| فهرست تجهیزات شناسایی‌شده | Hardware Overview: کارت هر دستگاه + «دستگاه‌های USB/Serial دیگر» (p2: USB Devices، Serial Devices) |
| وضعیت اتصال | ● Ready / ● Warning / ● Offline زنده از رویدادها |
| مدل و شناسه سخت‌افزار | VID:PID، سازنده، سریال، مسیر `/dev/ban-*` |
| تنظیمات تجهیزات | فرم هر نوع (عرض کاغذ، cut، baud، suffix، …) |
| انتخاب پورت و رابط ارتباطی | USB / Network / Serial + انتخاب پورت از فهرست شناسایی‌شده؛ چاپگر شبکه: IP + تست 9100 |
| تست عملیاتی | جدول پایین |
| بررسی خطاهای اتصال | آخرین خطا + راهنمای فارسی |
| مدیریت Driver و Adapter | انتخاب adapter از فهرست؛ «تشخیص خودکار» بر اساس `devices.toml` |
| ذخیره تنظیمات | `hardware.set_config` با تأیید |
| تاریخچه خطاها | رویدادهای `category=HARDWARE` همان دستگاه |

طرح صفحه چاپگر (full-chat §9):

```
Receipt Printer      Status: ● Ready
Model: XPrinter XP-Q200     Connection: USB     Device: /dev/ban-printer
Last Print: 14:31           Errors (7d): 2
[Test Print]  [Open Drawer]  [Settings]
```

تست‌های نمونه (p2):

| تست | روش |
| --- | --- |
| تست چاپ | رسید نمونه: فارسی، اعداد، جدول، بارکد، QR، لوگو، cut |
| تست بارکدخوان | صفحه «اسکن کنید»: کد، نوع، زمان؛ تشخیص خرابی layout |
| تست کشوی پول | باز کردن + (اگر سنسور) تأیید باز شدن |
| تست نمایشگر مشتری | الگوی تست + متن فارسی |
| تست ارتباط با ترازو | وزن زنده + پایداری |
| تست پورت ارتباطی | loopback / خواندن خام ۱۰ث از پورت |
| تست وضعیت کارت‌خوان | link test |

نقش‌ها: مشاهده = Manager؛ تست = Technician (باز کردن کشو = Audit)؛ تغییر تنظیمات = Technician.

## گام ۸.۷ — اتصال Adad و سازگاری

- کتابخانه Python `ban_hardware` برای Adad (client همان socket)؛ Adad دیگر مستقیم به دستگاه وصل نمی‌شود (خروجی p1: «بدون اینکه منطق هر برند مستقیماً در هسته برنامه قرار بگیرد»).
- `docs/operations/hardware-compatibility.md`: جدول برند/مدل/اتصال/وضعیت (تست‌شده، کار می‌کند، مشکل‌دار) — با هر نصب واقعی بروز می‌شود.
- `tests/hardware/`: چک‌لیست دستی + تست خودکار با دستگاه مجازی (pty برای سریال، فایل برای lp).

## معیار پذیرش

روی سخت‌افزار واقعی: چاپ فارسی درست و باز شدن کشو، هم از Ban Center هم از Adad · کشیدن کابل چاپگر حین فروش → Adad ادامه می‌دهد، رویداد ثبت و بعد از اتصال چاپ مجدد ممکن است · جابه‌جایی پورت USB → دستگاه همچنان شناخته می‌شود.

---

# مرحله ۹ — بروزرسانی (OS-06 + BC-07)

## هدف

«ایجاد سیستم کنترل‌شده برای بروزرسانی اجزای Ban OS و نرم‌افزار Adad، با قابلیت بررسی نسخه، اعتبارسنجی و مدیریت خطا.» (p1) — p1: «ابتدا با بروزرسانی بسته‌ها آغاز شود و در مرحله بعد به Image-based یا A/B توسعه پیدا کند.» full-chat §39: «فعلاً سراغ A/B نرو.»

## انواع بروزرسانی (p1) و دو مسیر (full-chat §18)

| نوع p1 | مسیر | بسته |
| --- | --- | --- |
| Adad POS | Application Update | `adad-pos` |
| Ban Agent / Ban Center / سرویس‌های سخت‌افزاری | OS Update (component) | `ban-agent` `ban-center` `ban-hardware` … |
| پکیج‌های سیستم‌عامل | OS Update (security) | مخزن Debian آینه‌شده و **تأییدشده** توسط ما، نه مستقیم از Debian |
| بروزرسانی کامل OS Image | بعد از 1.0 (A/B) | — |
| تنظیمات و سیاست‌ها (p2) | `ban-policy` | فایل‌های پیش‌فرض `/usr/share/ban/` |

## پوشش اقلام OS-06

| قلم p1 | گام |
| --- | --- |
| Version Management | ۹.۱ |
| Update Manifest | ۹.۲ |
| مخزن بروزرسانی | ۹.۱ |
| امضای دیجیتال / اعتبارسنجی بسته‌ها | ۹.۳ |
| زمان‌بندی بروزرسانی | ۹.۴ |
| وضعیت پیشرفت | ۹.۴ |
| ثبت تاریخچه | ۹.۴ |
| مدیریت خطا / Rollback | ۹.۵ |

## گام ۹.۱ — مخزن و نسخه‌ها

- `aptly` روی سرور Release: مخزن‌های `ban` (بسته‌های ما) و `debian-approved` (snapshot آینه Debian که روی staging تست شده).
- کانال‌ها: `dev` → `beta` → `stable`؛ انتشار = promote همان snapshot (هیچ build مجددی بین کانال‌ها نیست).
- روی دستگاه: `/etc/apt/sources.list.d/ban.sources` با `Signed-By: /usr/share/keyrings/ban-archive.gpg`؛ هیچ مخزن دیگری فعال نیست؛ `apt-daily` خاموش (مرحله ۲).
- `ban-os-release` = meta-package که نسخه دقیق همه اجزا را pin می‌کند ← «Ban OS 1.4.3» یعنی مجموعه‌ای مشخص و تست‌شده، نه هر ترکیبی.

## گام ۹.۲ — Manifest (full-chat §16)

`https://update.<domain>/<channel>/manifest.json` + `manifest.json.sig`:

```JSON
{
  "channel": "stable",
  "generated_at": "2026-10-01T08:00:00Z",
  "os":   { "version": "1.4.3", "min_from": "1.3.0", "reboot": true,  "notes_fa": "…", "size": 184000000 },
  "adad": { "version": "5.2.2", "min_os": "1.4.0",  "reboot": false, "notes_fa": "…", "size": 62000000 },
  "components": { "ban-agent": "1.4.3", "ban-center": "1.4.3", "ban-hardware": "2.1.0" },
  "rollout": { "percent": 25 },
  "architecture": "amd64"
}
```

`rollout.percent` + hash از `device_id` → انتشار تدریجی بدون نیاز به Fleet.

## گام ۹.۳ — امضا (full-chat §17: «هرگز فقط SHA256 کافی نیست»)

- دو لایه: (۱) امضای Ed25519 روی manifest (کلید عمومی در Image: `/usr/share/ban/keys/update.pub`)؛ (۲) امضای GPG مخزن apt روی بسته‌ها.
- کلید خصوصی فقط روی سرور Release/CI (ترجیحاً توکن سخت‌افزاری)؛ کلید دوم پشتیبان برای چرخش کلید؛ رویه چرخش در `docs/security/key-rotation.md`.
- امضای نامعتبر → توقف + `UPDATE_VERIFICATION_FAILED` (ERROR، Audit).
- نصب آفلاین: فایل `.banpkg` (tar + manifest + امضا) روی USB با همان اعتبارسنجی — برای فروشگاه‌های بدون اینترنت و برای `ban-tech-tools`.

## گام ۹.۴ — `ban-update`

جریان (full-chat §16): Check → Download → Verify → Install → Health → Commit.

| مرحله | جزئیات | رویداد |
| --- | --- | --- |
| Check | timer روزانه با jitter + دستی | `UPDATE_CHECKED` / `UPDATE_AVAILABLE` |
| Download | در پس‌زمینه، resume‌پذیر، محدودیت پهنای باند، بررسی فضای آزاد (۲× حجم) | `UPDATE_DOWNLOAD_STARTED` / `_COMPLETED` |
| Verify | امضای manifest + امضای apt | — |
| پیش‌شرط نصب | داخل پنجره زمانی (`/etc/ban/update.toml`، پیش‌فرض ۰۲:۰۰–۰۵:۰۰) · Adad اعلام کند فاکتور باز ندارد (`adad.can_update`) · برق AC · Backup تازه (< ۲۴ساعت، وگرنه اول Backup) | — |
| Install | نگه‌داشتن `.deb`های فعلی در `/var/cache/ban/rollback/<ver>/` → `apt-get install` غیرتعاملی → اگر `reboot=true` صفحه «در حال بروزرسانی — دستگاه را خاموش نکنید» | `UPDATE_INSTALL_STARTED` |
| Health (full-chat §20) | همان بررسی‌های Launcher: Database ✓ Adad ✓ Network ✓ Printer ✓ Configuration ✓ + ۱۰ دقیقه پایداری | `UPDATE_INSTALL_COMPLETED` |
| تاریخچه | جدول `update_history` در `/var/lib/ban/update.db`: از/به نسخه، زمان، مدت، نتیجه، آغازگر | — |

پیشرفت: `update.status` → `{phase, percent, message_fa}` برای UI و صفحه تمام‌صفحه حین نصب. PostgreSQL: تغییر major فقط همراه OS Update صریح با `pg_upgradecluster` و بعد از Backup اجباری.

## گام ۹.۵ — مدیریت خطا و Rollback

| وضعیت | واکنش |
| --- | --- |
| دانلود ناقص / شبکه قطع | resume؛ بعد از N بار → `UPDATE_INSTALL_FAILED`؛ فروش تحت تأثیر نیست |
| `dpkg` نیمه‌کاره (قطع برق) | unit اول بوت `ban-update-recover`: `dpkg --configure -a` سپس ادامه یا rollback |
| Health ناموفق، یا «Adad سه بار crash کرد» (full-chat §20)، یا crashloop مرحله ۳ | نصب `.deb`های قبلی با `--allow-downgrades` → `UPDATE_ROLLBACK` (CRITICAL) + علامت «نسخه X روی این دستگاه مسدود» تا دوباره تلاش نشود |
| migration دیتابیس Adad برگشت‌ناپذیر | Backup پیش از آپدیت مبنای بازگشت است؛ قرارداد با تیم Adad: migrationها backward-compatible یک نسخه |

Rollback کامل سطح OS (A/B، full-chat §19) بعد از 1.0؛ چیدمان پارتیشن از مرحله ۱۰ برایش آماده است.

## گام ۹.۶ — BC-07 صفحات Updates

اجزای تحت مدیریت (p2): Ban OS · Adad POS · Ban Center · Ban Agent · Hardware Layer · سرویس‌های سیستم · تنظیمات و سیاست‌ها.

| قلم p2 | UI |
| --- | --- |
| مشاهده نسخه فعلی | Current Versions — جدول همه اجزا (طرح full-chat §10: `Ban OS Current 1.4.2 Latest 1.4.3`) |
| بررسی نسخه جدید | `[Check for Updates]` → `update.check` |
| Release Notes | `notes_fa` از manifest |
| وضعیت بروزرسانی | نوار مرحله‌ای Download → Verify → Install → Health |
| شروع بروزرسانی | «اکنون نصب شود» — Technician، تأیید تایپی، بررسی پیش‌شرط‌ها با توضیح هر مانع |
| زمان‌بندی | Update Settings: پنجره زمانی، خودکار/دستی، کانال (فقط Admin) |
| تاریخچه | Update History (طرح full-chat: `5.2.1 Success · 5.1.8 Rollback`) |
| اعتبارسنجی بسته‌ها | نمایش نتیجه امضا و اثر انگشت کلید |
| نمایش خطا | پیام فارسی + لینک به Update Logs |
| Rollback | «بازگشت به نسخه قبلی» — Admin، احراز هویت مجدد، فقط اگر بسته‌های قبلی موجود است |
| وضعیت دستگاه هنگام بروزرسانی | صفحه تمام‌صفحه قفل روی POS |
| نصب از USB | انتخاب `.banpkg` و اعتبارسنجی |

متدها: `update.status` `update.check` `update.download` `update.install` `update.schedule` `update.history` `update.rollback` `update.install_offline` `update.settings.get|set`.

## معیار پذیرش

انتشار نسخه جدید dummy → VM در پنجره زمانی خودکار آپدیت می‌شود · بسته/manifest دست‌کاری‌شده رد می‌شود · نسخه عمداً خراب Adad → rollback خودکار · قطع برق وسط `dpkg` → بوت بعدی سالم.

---

# مرحله ۱۰ — Recovery و Backup (OS-07 + BC-08)

## هدف

«افزایش پایداری دستگاه‌های POS و ایجاد راهکارهای بازیابی در برابر خرابی نرم‌افزار، سیستم‌عامل، دیسک یا بروزرسانی ناموفق.» (p1)

## پوشش اقلام OS-07

| قلم p1 | کجا |
| --- | --- |
| تشخیص خرابی هنگام بوت | مرحله ۲.۷ + گام ۱۰.۴ |
| بازیابی سرویس‌ها | مرحله ۴.۱ |
| مدیریت Crash | مرحله ۳.۴ |
| بازیابی تنظیمات | ۱۰.۳ |
| Backup و Restore | ۱۰.۲، ۱۰.۳ |
| Recovery Mode | ۱۰.۴ |
| Rollback بروزرسانی | مرحله ۹.۵ |
| بررسی سلامت دیسک | ۱۰.۵ |
| مدیریت کمبود فضا | ۱۰.۵ |
| ثبت رخدادهای بحرانی | ۱۰.۶ |
| Factory Reset با دسترسی محدود | ۱۰.۳ |

## گام ۱۰.۱ — پارتیشن‌بندی نهایی (full-chat §4)

| پارتیشن | اندازه | mount | توضیح |
| --- | --- | --- | --- |
| EFI | 512MB | `/boot/efi` | FAT32 |
| System A | 12GB | `/` | ext4 |
| System B | 12GB | — | رزرو A/B؛ در 1.0 خالی و بدون mount |
| Recovery | 2GB | — | سیستم کوچک Recovery + نسخه کارخانه‌ای `.deb`های Ban |
| Data | باقی‌مانده | `/data` | ext4 با `data=ordered`؛ bind mount به `/var/lib/postgresql`، `/var/lib/adad`، `/var/lib/ban`، `/var/log` |

حداقل دیسک پشتیبانی‌شده: 32GB (در آن صورت A/B هر کدام 8GB). full-chat گفته بود «برای نسخه اول لازم نیست A/B واقعی»: پارتیشن B فقط رزرو می‌شود چون تغییر جدول پارتیشن روی دستگاه نصب‌شده در آینده عملاً ناممکن است.

root فقط‌خواندنی (نکته immutable در full-chat): در این مرحله **ارزیابی و آماده‌سازی** — همه مسیرهای نوشتنی به `/data` یا tmpfs منتقل شده‌اند (مراحل ۱ و ۴)؛ یک build آزمایشی با root `ro` + overlay برای `/etc` ساخته و سازگاری apt/آپدیت سنجیده می‌شود. نتیجه تصمیم می‌گیرد که در 1.0 روشن شود یا همراه A/B.

## گام ۱۰.۲ — Backup

| مورد (p2: DB، تنظیمات، اطلاعات دستگاه) | روش |
| --- | --- |
| دیتابیس | `pg_dump -Fc adad` (فقط نقش Standalone/Server)؛ در نقش Client چیزی برای Backup نیست جز تنظیمات |
| تنظیمات | `/etc/ban` `/etc/adad` NetworkManager connections (رمزها داخل بسته رمزنگاری‌شده می‌مانند) |
| اطلاعات دستگاه | `device.toml`، نسخه‌ها، `hardware.toml` — **بدون کلید خصوصی دستگاه** |
| قالب | `ban-backup-<device_id>-<تاریخ>.tar.zst.enc` رمزنگاری با age/AES و کلید مشتق از رمز Backup (تعیین در wizard) + `manifest.json` با SHA256 هر جزء |
| مقصد (p2: انتخاب مقصد) | محلی `/data/ban/backups` · USB · (بعد از Cloud) سرور |
| زمان‌بندی | شبانه + قبل از هر آپدیت + دستی؛ نگهداری: ۷ روزانه + ۴ هفتگی؛ حذف خودکار قدیمی‌ها در کمبود فضا |
| بررسی صحت (p2) | هر Backup: checksum + `pg_restore --list`؛ هفتگی: restore آزمایشی در DB موقت `adad_verify` و شمارش جداول |
| رویداد | `DATABASE_BACKUP` با حجم، مدت، نتیجه، مقصد |

هشدار Dashboard اگر آخرین Backup موفق > ۴۸ساعت.

## گام ۱۰.۳ — Restore، بازیابی تنظیمات، Factory Reset

| عملیات | جزئیات | کنترل‌ها (p2 «کنترل‌های ضروری») |
| --- | --- | --- |
| بازیابی تنظیمات | از `/var/lib/ban/config-history/` (مرحله ۴.۷): نمایش diff و بازگشت هر فایل به نسخه قبل؛ یا از Backup | Technician + تأیید |
| بازیابی دیتابیس | توقف Adad → Backup اضطراری وضعیت فعلی → `pg_restore` در DB جدید → جابه‌جایی نام → اجرای Adad → Health | Admin + احراز هویت مجدد + تأیید تایپی + هشدار «فروش‌های بعد از تاریخ Backup از بین می‌رود» |
| Restore روی دستگاه تازه | در First-boot wizard (مرحله ۱۲): «بازیابی از Backup» از USB | رمز Backup |
| Factory Reset | سه سطح: (۱) فقط تنظیمات Ban (۲) + داده Adad (۳) کامل از پارتیشن Recovery. پیش از آن Backup اجباری روی USB مگر Admin صریحاً رد کند | فقط Admin، احراز هویت مجدد، تایپ `device_id`، ثبت `FACTORY_RESET` پیش از اجرا و sync فوری اگر آنلاین |
| جلوگیری از عملیات ناسازگار (p2) | Agent ماشین حالت دارد: حین Update یا Backup، Restore ممنوع (`CONFLICT_STATE`)؛ در نقش Client، Restore DB غیرفعال؛ فضای ناکافی → رد با توضیح | — |

## گام ۱۰.۴ — Recovery Mode (full-chat §15)

ورودی GRUB «Recovery» → `ban-recovery.target`: سیستم حداقلی، بدون Adad، با رابط متنی/گرافیکی ساده (نسخه سبک Ban Center با همان Agent در حالت recovery) پشت PIN مدیر:

```
Repair filesystem        fsck روی root و data
Reset configuration      بازگشت /etc/ban به پیش‌فرض
Restore backup           از USB یا محلی
Rollback update          نصب بسته‌های قبلی
Reinstall Ban packages   از پارتیشن Recovery
Factory reset
Export support bundle    روی USB
```

ورود خودکار به Recovery: ۳ بوت ناموفق پیاپی (bootcount مرحله ۲.۷) — شمارنده وقتی `BAN-BOOT-OK` ثبت شود صفر می‌شود.

## گام ۱۰.۵ — دیسک و فضا

- `smartd` + خواندن دوره‌ای SMART/eMMC life → `SMART_WARNING`؛ نمایش «سلامت دیسک» در System Health.
- آستانه‌ها: ۸۰٪ `DISK_SPACE_WARNING` → ۹۰٪ پاک‌سازی خودکار (cache، بسته‌های rollback قدیمی، Backupهای مازاد، Retention زودتر DEBUG/INFO) → ۹۵٪ `LOW_DISK` (CRITICAL) و هشدار روی Launcher.
- PostgreSQL: autovacuum + `VACUUM` هفتگی در پنجره شب.

## گام ۱۰.۶ — رخدادهای بحرانی و قطع برق

- رویدادهای CRITICAL با `fsync` فوری و کپی در `/data/ban/critical.log` (متنی ساده، برای وقتی DB باز نمی‌شود).
- مقاومت در برابر قطع برق: ext4 journal، `synchronous_commit=on` در PostgreSQL، SQLite WAL + `synchronous=FULL` برای audit.db، نوشتن اتمیک تنظیمات.
- `tests/reliability/power-cut.sh`: ۲۰۰ بار kill ناگهانی VM در نقاط تصادفی (حین فروش dummy، Backup، آپدیت، نوشتن تنظیمات) → هر بار بوت سالم + DB سازگار + hash chain معتبر.

## گام ۱۰.۷ — BC-08 صفحات Backup & Recovery

| قلم p2 | UI |
| --- | --- |
| وضعیت Backup / تاریخ آخرین پشتیبان | Backup Status: آخرین موفق، بعدی، حجم، مقصد، نتیجه verify |
| Backup دیتابیس / تنظیمات / اطلاعات دستگاه | Create Backup: انتخاب اجزا و مقصد، پیشرفت job |
| انتخاب مقصد | محلی / USB (فهرست USBهای متصل و فضای آزاد) |
| بازیابی تنظیمات / دیتابیس | Restore: فهرست Backupها با تاریخ جلالی، نسخه Adad زمان Backup، هشدار ناسازگاری نسخه |
| وضعیت فضای ذخیره‌سازی | نوار فضا + سهم Backupها |
| Recovery Mode | دکمه «راه‌اندازی مجدد در Recovery» |
| Factory Reset | Recovery → سه سطح، با کنترل‌های بالا |
| بررسی صحت Backup | «Verify» دستی برای هر فایل |
| تاریخچه عملیات بازیابی | رویدادهای `DATABASE_RESTORE` `FACTORY_RESET` `CONFIG_RESTORED` |

متدها: `backup.list` `backup.create` `backup.verify` `backup.delete` `backup.settings` `restore.config` `restore.database` `recovery.reboot_to` `recovery.factory_reset` `job.status`.

## معیار پذیرش

تست قطع برق ۲۰۰ دور سبز · Restore یک Backup روی دستگاه تازه‌نصب → Adad با همان داده · دیسک پر مصنوعی → پاک‌سازی خودکار و ادامه فروش · ۳ بوت خراب → Recovery خودکار. — **نقطه عطف M3: دستگاه آزمایشی در فروشگاه واقعی**

---

# مرحله ۱۱ — امنیت و دسترسی (OS-08 + BC-09)

## هدف

«ایجاد مدل امنیتی مناسب برای دستگاه‌های تجاری که در محیط فروشگاه در دسترس افراد مختلف قرار دارند.» (p1) + «مدیریت کاربران، نقش‌ها و سطح دسترسی» (p2)

## پوشش اقلام OS-08

| قلم p1 | گام |
| --- | --- |
| تفکیک کاربران و نقش‌ها | ۱۱.۱ |
| محدودسازی دسترسی به محیط Linux | مرحله ۳.۵ + ۱۱.۳ |
| دسترسی مدیریتی و Maintenance | ۱۱.۲ |
| مدیریت مجوز فایل‌ها | ۱۱.۳ |
| کنترل دسترسی سرویس‌ها | ۱۱.۳ |
| امنیت ارتباطات شبکه | ۱۱.۴ |
| مدیریت کلیدها و Secrets | ۱۱.۵ |
| امضای بسته‌ها و بروزرسانی‌ها | مرحله ۹.۳ |
| محافظت از تنظیمات و اطلاعات محلی | ۱۱.۵ |
| ثبت رویدادهای امنیتی | ۱۱.۶ |
| سیاست‌های Firewall | ۱۱.۴ |
| امنیت USB و تجهیزات جانبی | ۱۱.۷ |
| سخت‌سازی سرویس‌های غیرضروری | ۱۱.۳ |

## گام ۱۱.۱ — نقش‌ها (p2) و ماتریس مجوز

| مجوز | POS Operator | Store Manager | Technician | Support Agent (رزرو) | System Administrator |
| --- | --- | --- | --- | --- | --- |
| استفاده از Adad | ✓ | ✓ | ✓ | — | ✓ |
| ورود به Ban Center | — | ✓ | ✓ | با مجوز محلی | ✓ |
| Dashboard / System / Storage | — | مشاهده | ✓ | مشاهده | ✓ |
| Network | — | مشاهده | تغییر | مشاهده | تغییر |
| Services | — | مشاهده | Restart | مشاهده | همه |
| Hardware | — | مشاهده | تست و تنظیم | تست | همه |
| Logs / Audit / Security logs | — | Logs + Audit | Logs + Audit | Logs | همه |
| Updates | — | مشاهده | نصب | — | + کانال و Rollback |
| Backup / Restore DB / Factory Reset | — | Backup | Backup + بازیابی تنظیمات | — | همه |
| Users & Access | — | — | — | — | ✓ |
| ابزارهای اختیاری / ترمینال | — | — | ✓ (احراز هویت مجدد) | — | ✓ |
| Reboot / Shutdown | از Adad | ✓ | ✓ | — | ✓ |

تعریف در `security/permissions/roles.toml` → تولید هم برای Agent هم برای typeهای UI. کاربران Ban در `/var/lib/ban/users.db` (جدا از کاربران Linux): نام، نقش، PIN با Argon2id، وضعیت، انقضا. کاربران Adad (صندوق‌دارها) مال خود Adad‌اند؛ `LOCAL_LOGIN` را Adad به `ban-event` گزارش می‌کند.

## گام ۱۱.۲ — اقلام BC-09

| قلم p2 | پیاده‌سازی |
| --- | --- |
| مدیریت کاربران | ساخت/غیرفعال/حذف، بازنشانی PIN؛ آخرین Admin قابل حذف نیست |
| نقش‌ها و مجوزها | نمایش ماتریس؛ در 1.0 نقش‌ها ثابت‌اند |
| ورود به Maintenance Mode | مرحله ۳.۷ با PIN شخصی هر کاربر (نه PIN مشترک) → actor واقعی در Audit |
| احراز هویت مجدد | عملیات سطح ۳، با اعتبار ۲ دقیقه |
| مدیریت Session | فهرست sessionهای فعال، پایان دادن؛ یک session هم‌زمان برای هر کاربر |
| محدودیت زمانی دسترسی | بی‌کاری ۱۰دقیقه؛ سقف ۴ساعت؛ حساب موقت تکنسین با تاریخ انقضا |
| ثبت ورود و خروج / عملیات حساس | رویدادهای Authentication و Management |
| دسترسی آفلاین | همه احراز هویت محلی است و هرگز به Cloud وابسته نیست |
| دسترسی اضطراری | «کد اضطراری»: دستگاه challenge (مبتنی بر `device_id` + شمارنده) نشان می‌دهد؛ پشتیبانی با کلید خصوصی شرکت پاسخ یک‌بارمصرف می‌سازد؛ دستگاه با کلید عمومی داخل Image تأیید می‌کند → session یک‌ساعته Admin + `EMERGENCY_ACCESS_USED` (CRITICAL). بدون رمز ثابت جهانی |
| PIN | حداقل ۶ رقم برای Technician/Admin، ۴ برای Manager؛ منع PINهای ساده؛ قفل تصاعدی ۵دقیقه → ۱ساعت |

صفحات: Users · Roles · Permissions · Sessions.

## گام ۱۱.۳ — سخت‌سازی Linux

- root قفل؛ `maintenance` با sudoers whitelist؛ در production SSH نصب نیست.
- polkit ruleها: فقط کاربر `ban-agent` مجاز به `org.freedesktop.systemd1.manage-units` (برای unitهای whitelist)، NetworkManager، timedate1.
- hardening کامل unitها با `systemd-analyze security` (هدف امتیاز < ۳ برای سرویس‌های Ban): `ProtectSystem=strict` `ProtectKernelTunables` `RestrictAddressFamilies` `SystemCallFilter=@system-service` `CapabilityBoundingSet=` `MemoryDenyWriteExecute` (جز WebKit) `PrivateDevices` (جز ban-hardware).
- مجوز فایل‌ها: `/etc/ban` = `root:ban-agent 0640`؛ `audit.db` فقط `ban-event`؛ `/opt` فقط‌خواندنی؛ `/data` با `nosuid,nodev`؛ `/tmp` با `noexec`.
- sysctl: `kernel.sysrq=0` `kernel.kptr_restrict=2` `kernel.dmesg_restrict=1` `fs.protected_*` `net.ipv4.conf.all.rp_filter=1`؛ core dump خاموش.
- سرویس‌های غیرضروری: فهرست سفید unitهای فعال در `security/hardening/enabled-units.txt`؛ تست CI اگر unit اضافه‌ای فعال باشد fail می‌شود.
- GRUB با رمز (مرحله ۲)؛ توصیه BIOS در راهنمای نصب: رمز BIOS، بوت فقط از دیسک داخلی.
- Chromium فقط با policy مدیریت‌شده (مرحله ۳.۶).

## گام ۱۱.۴ — شبکه و Firewall

`/etc/nftables.conf`: ورودی پیش‌فرض `drop`؛ مجاز: loopback، established، ICMP محدود، DHCP client. خروجی: آزاد در 1.0 (فهرست سفید دامنه‌ها بعداً).

| نقش دستگاه | قاعده اضافه |
| --- | --- |
| Standalone / Client | هیچ پورت ورودی |
| Server | TCP 5432 فقط از subnet LAN فروشگاه (نه از Wi-Fi مهمان) |

PostgreSQL نقش Server: `listen_addresses` = IP LAN · `pg_hba`: `hostssl adad adad_client <subnet> scram-sha-256` · TLS با گواهی خودامضا ساخته‌شده در Provisioning و pin شده روی Clientها · رمز `adad_client` تصادفی، هنگام جفت‌سازی Client منتقل می‌شود (مرحله ۱۲). همه ارتباط‌های بیرونی Ban فقط HTTPS با بررسی گواهی.

## گام ۱۱.۵ — Secrets و داده محلی

- اصل full-chat: «اطلاعات حساس مثل API key و credential را داخل Image عمومی قرار نده؛ هنگام نصب Provision شوند.» تست CI: اسکن Image برای الگوهای کلید/رمز.
- کلید خصوصی دستگاه: `/var/lib/ban/identity/device.key` مود `0600` مالک `ban-agent`؛ بعد از 1.0 → TPM (full-chat §28).
- Secrets برنامه‌ها: `systemd-creds` (رمزنگاری‌شده با کلید میزبان) به‌جای فایل متنی.
- Backupها رمزنگاری‌شده (مرحله ۱۰.۲).
- رمزنگاری کامل `/data` (LUKS): در 1.0 اختیاری و پیش‌فرض خاموش، چون بوت بدون دخالت لازم است و بدون TPM کلید باید کنار دیسک باشد؛ با TPM بعد از 1.0 پیش‌فرض می‌شود.

## گام ۱۱.۶ — رویدادهای امنیتی و مقاومت در برابر دست‌کاری

- رویدادها: `LOGIN_FAILED` `ACCOUNT_LOCKED` `PERMISSION_DENIED` `EMERGENCY_ACCESS_USED` `USB_DEVICE_BLOCKED` `AUDIT_CHAIN_BROKEN` `FIREWALL_CHANGED` `INTEGRITY_CHECK_FAILED`.
- Hash chain (full-chat §16) + بررسی زنجیره در هر بوت و هفتگی؛ شکست → `AUDIT_CHAIN_BROKEN` (CRITICAL).
- «رویدادهای حساس به سرور مرکزی هم ارسال شوند» (full-chat): با `ban-sync` بعد از Cloud؛ تا آن زمان در Support Bundle.
- بررسی یکپارچگی فایل‌های `/opt/ban` و `/opt/adad` با `dpkg --verify` هفتگی.

## گام ۱۱.۷ — USB و تجهیزات جانبی

- `usbguard`: پیش‌فرض allow برای کلاس‌های HID، Printer، CDC/Serial، Hub؛ **block برای Mass Storage** و کلاس‌های ناشناخته → `USB_DEVICE_BLOCKED`.
- Mass Storage فقط وقتی Agent موقتاً اجازه دهد (Backup، Support Bundle، آپدیت آفلاین)؛ mount با `noexec,nosuid,nodev`.
- خطر BadUSB (HID جعلی): رویداد و اعلان برای HID جدیدِ دیده‌نشده؛ حالت سخت‌گیرانه اختیاری = تأیید تکنسین.

## معیار پذیرش

چک‌لیست `docs/security/hardening.md` کامل پاس · آزمون نفوذ داخلی با سناریوهای: صندوق‌دار کنجکاو (کلیدهای ترکیبی، USB، کشیدن برق و بوت از USB)، تکنسین غیرمجاز (حدس PIN)، مهاجم شبکه محلی (اسکن پورت، اتصال به 5432 از subnet دیگر) · هیچ Secret در Image · دست‌کاری audit.db تشخیص داده می‌شود.

خروجی (p1): «مدل دسترسی مشخص و کنترل‌شده؛ مسیرهای حساس قابل حسابرسی.» Secure Boot و TPM بعد از 1.0 (full-chat §39).

---

# مرحله ۱۲ — نصب‌کننده و Provisioning (OS-09)

## هدف

«ایجاد فرآیند استاندارد برای ساخت، نصب و آماده‌سازی Ban OS روی دستگاه‌های واقعی.» (p1)

## پوشش اقلام OS-09

| قلم p1 | گام |
| --- | --- |
| ساخت Image نهایی | ۱۲.۱ |
| نصب‌کننده Ban OS / پشتیبانی از UEFI | ۱۲.۲ |
| پشتیبانی از سخت‌افزارهای هدف | ۱۲.۲ + HCL |
| تنظیمات اولیه دستگاه / زبان و منطقه / شبکه اولیه / نمایشگر و Touch | ۱۲.۳ |
| ایجاد Device Identity | ۱۲.۴ |
| Provisioning / ثبت دستگاه در زیرساخت Ban | ۱۲.۵ |
| نصب کارخانه‌ای / تکنسین / Recovery / بروزرسانی Image / آزمایشی | ۱۲.۶ |

## گام ۱۲.۱ — خروجی‌های Build (full-chat §31)

`ban-os-1.0.0-amd64.iso` (نصب‌کننده USB) · `ban-os-1.0.0-amd64.img.zst` (دیسک آماده برای clone کارخانه‌ای) · `SHA256SUMS` + امضا · `manifest-packages.txt` (فهرست دقیق بسته‌ها برای بازتولید).

## گام ۱۲.۲ — نصب‌کننده

تصمیم (full-chat §34): «برای نسخه اول Debian Installer را customize کن؛ installer اختصاصی بعداً — هزینه نگهداری‌اش زیاد است.» پس: `lb config --debian-installer live` + preseed. منوی بوت ISO (full-chat §26):

```
Install Ban OS            (unattended با preseed)
Install Ban OS (expert)   (انتخاب دستی دیسک)
Recovery
Hardware Diagnostics      (live: تست touch، نمایشگر، شبکه، دیسک، چاپگر — بدون نصب)
```

`installer/preseed/ban.cfg`: locale و keyboard ثابت · بدون mirror شبکه (نصب کامل آفلاین از ISO) · انتخاب دیسک: تنها دیسک داخلی غیر USB، اگر بیش از یکی بود سؤال · `partman-auto/expert_recipe` مطابق جدول مرحله ۱۰.۱ با GPT و EFI · بدون ساخت کاربر تعاملی · `grub-efi` با `--removable` برای BIOSهای بدقلق + fallback نصب legacy BIOS برای دستگاه‌های قدیمی · `late_command` → `installer/postinstall/` (bind mountهای `/data`، فعال‌سازی unitها، علامت `first-boot`).

فقط یک تأیید: «تمام اطلاعات دیسک X پاک می‌شود». هدف: < ۱۰ دقیقه روی SSD.

## گام ۱۲.۳ — First-boot wizard

Ban Center در «حالت setup» (همان برنامه Tauri، مسیر `/setup`) — بدون PIN چون هنوز کاربری نیست؛ Agent فقط وقتی علامت `first-boot` هست متدهای `setup.*` را می‌پذیرد. مراحل (بازنویسی جریان full-chat §26 برای Ban):

| # | صفحه | جزئیات |
| --- | --- | --- |
| ۱ | زبان و منطقه | فارسی/انگلیسی، منطقه زمانی |
| ۲ | نمایشگر و Touch | رزولوشن، چرخش، کالیبره، تست touch |
| ۳ | شبکه | Ethernet/Wi-Fi با Diagnostics؛ «بعداً» مجاز است (Offline-first) |
| ۴ | تاریخ و ساعت | NTP یا دستی |
| ۵ | نوع راه‌اندازی | نصب جدید / **بازیابی از Backup** (USB + رمز) |
| ۶ | نقش دستگاه | Standalone / Server / Client (پایین) |
| ۷ | هویت فروشگاه | Store ID، Terminal ID، نام نمایشی |
| ۸ | فعال‌سازی | License (آنلاین، یا کد آفلاین) |
| ۹ | مدیر سیستم | ساخت کاربر Admin و PIN، رمز Backup؛ کاربر Technician اختیاری |
| ۱۰ | سخت‌افزار | شناسایی خودکار چاپگر/اسکنر/کشو + تست چاپ |
| ۱۱ | خلاصه | تأیید → اعمال → حذف علامت `first-boot` → اجرای Adad |

نقش دستگاه:

| نقش | کار wizard |
| --- | --- |
| Standalone | PostgreSQL محلی، فقط socket |
| Server | پیشنهاد IP ثابت · فعال‌سازی listen روی LAN، TLS، firewall 5432 · ساخت نقش `adad_client` · نمایش «کد جفت‌سازی» (QR + متن: آدرس، اثر انگشت گواهی، توکن یک‌بارمصرف ۱۵دقیقه‌ای) |
| Client | اسکن/ورود کد جفت‌سازی → دریافت credential از Server با TLS pin → ذخیره با `systemd-creds` → غیرفعال‌سازی PostgreSQL محلی → `pos.toml` → تست اتصال |

هر مرحله رویداد `SETUP_*`؛ پایان: `DEVICE_PROVISIONED`.

## گام ۱۲.۴ — Device Identity (full-chat §27 و §28)

```TOML
# /etc/ban/device.toml
device_id       = "BAN-8F92A1"     # از hash کلید عمومی
installation_id = "…ULID"          # با هر نصب مجدد عوض می‌شود
store_id        = "1024"
terminal_id     = "03"
role            = "standalone"
provisioned_at  = "…"
```

کلید Ed25519 روی خود دستگاه ساخته می‌شود: «Private key → device · Public key → activation server». hostname → `ban-8f92a1`. نصب مجدد روی همان سخت‌افزار: کلید جدید، ولی اثر انگشت سخت‌افزار (DMI serial + MAC) برای تشخیص «همان دستگاه» فرستاده می‌شود.

## گام ۱۲.۵ — Activation حداقلی (تنها جزء سمت سرور پیش از 1.0)

`POST /v1/devices/activate` ← `{public_key, device_id, installation_id, store_id, terminal_id, license_code, hw_fingerprint, versions}` → `{status, license{…, signature}, channel}`. License امضاشده محلی ذخیره می‌شود و Launcher آن را **آفلاین** تأیید می‌کند (مرحله ۳.۳). فعال‌سازی آفلاین: دستگاه کد درخواست (QR) می‌دهد → پشتیبانی کد پاسخ می‌دهد. دوره مهلت بدون فعال‌سازی: قابل تنظیم (مثلاً ۷ روز) تا نصب در محل بدون اینترنت متوقف نشود. سرور: یک سرویس کوچک + PostgreSQL؛ همین بعداً نطفه Ban Cloud (BC-10) می‌شود.

## گام ۱۲.۶ — انواع نصب (p1)

| نوع | روش |
| --- | --- |
| کارخانه‌ای | clone `.img.zst` روی دیسک‌ها (یا PXE) → اولین بوت: بزرگ‌کردن خودکار `/data` + wizard. هیچ هویتی در Image نیست؛ هر دستگاه کلید خودش را می‌سازد |
| تکنسین | USB ISO → unattended → wizard |
| Recovery Installation | ISO → «Recovery»: نصب مجدد System A **بدون دست زدن به `/data`** → داده و هویت می‌ماند |
| بروزرسانی Image | تا پیش از A/B: همان Recovery Installation با ISO جدید |
| آزمایشی و توسعه‌ای | Profile `development`: wizard با مقادیر پیش‌فرض قابل رد شدن (`ban.setup=auto`)، SSH روشن |

`installer/factory-setup/`: اسکریپت clone دسته‌ای + برگه QC (تست touch، چاپگر، شبکه، burn-in ۳۰ دقیقه‌ای) + چاپ برچسب `device_id`.

## معیار پذیرش

از USB تا Adad آماده فروش < ۱۵ دقیقه با حداقل ورودی · نصب Server + دو Client در یک LAN و فروش هم‌زمان · Recovery Installation داده را حفظ می‌کند · دو دستگاه clone‌شده از یک Image، `device_id` متفاوت دارند · نصب روی حداقل ۳ مدل سخت‌افزار واقعی (UEFI و یک legacy).

خروجی (p1): «فرآیند مشخص برای تولید Image و نصب روی دستگاه‌های مختلف با حداقل دخالت دستی.»

---

# مرحله ۱۳ — انتشار Production (OS-10 + BC-12)

## هدف

«آماده‌سازی Ban OS برای استفاده تجاری و نصب روی دستگاه‌های واقعی مشتریان.» (p1) + «نسخه نهایی Ban Center» (p2)

## گام ۱۳.۱ — ماتریس تست OS (همه اقلام p1)

| قلم p1 | تست | معیار |
| --- | --- | --- |
| تست کامل سیستم‌عامل | اجرای همه `tests/integration` روی Image production | ۱۰۰٪ سبز |
| سخت‌افزارهای هدف | چک‌لیست HCL روی هر مدل | همه مدل‌های «پشتیبانی‌شده» |
| فرآیند بوت | ۱۰۰ بوت پیاپی خودکار | ۱۰۰/۱۰۰، زمان < هدف |
| Crash و Recovery | kill/hang Adad، crashloop، ۳ بوت خراب | بازیابی خودکار |
| بروزرسانی | 0.9→1.0، آپدیت خراب، قطع برق حین آپدیت، آپدیت آفلاین | بدون brick |
| امنیت | چک‌لیست hardening + آزمون نفوذ مرحله ۱۱ | بدون یافته بحرانی |
| عملکرد | بوت، زمان باز شدن Adad و Ban Center، RAM بیکار (هدف < ۱٫۲GB با PostgreSQL)، زمان چاپ رسید | ثبت baseline |
| خاموش و روشن | ۵۰۰ چرخه power با رله روی دستگاه واقعی | بدون خرابی FS/DB |
| قطع و وصل شبکه | flap شبکه حین فروش و sync؛ نقش Client با قطع Server | فروش Standalone بی‌وقفه؛ Client پیام واضح و اتصال مجدد خودکار |
| قطع برق | `tests/reliability/power-cut.sh` + دستگاه واقعی | ۲۰۰/۲۰۰ |
| پایداری طولانی‌مدت | soak ۷۲ساعت (سپس ۷روز) با فروش مصنوعی و چاپ | بدون نشت حافظه، رشد دیسک قابل پیش‌بینی |

## گام ۱۳.۲ — ماتریس تست Ban Center (همه اقلام p2 BC-12)

عملکرد UI روی ضعیف‌ترین سخت‌افزار · ارتباط با Agent (قطع، کندی، نسخه ناسازگار) · مجوزها (هر نقش × هر عملیات از روی `roles.toml`، خودکار) · عملیات حساس (تأیید، احراز هویت مجدد، Audit) · قطع ارتباط با سرویس‌ها (NM، systemd، CUPS، PostgreSQL پایین) · خطاهای شبکه · سخت‌افزارهای هدف (رزولوشن‌ها، چرخش، touch) · خوانایی و کاربردپذیری (آزمون با ۳ تکنسین واقعی: ۸ سناریو بدون راهنما) · Maintenance Mode (هر سه مسیر ورود) · ثبت رویدادها (هر عملیات = رویداد درست) · امنیت (WebView بدون دسترسی OS، CSP، بدون devtools).

## گام ۱۳.۳ — Pilot

۳ تا ۵ فروشگاه واقعی، ۲ تا ۴ هفته روی کانال `beta`؛ جمع‌آوری هفتگی Support Bundle؛ معیار خروج: بدون باگ مسدودکننده فروش، crash rate Adad زیر آستانه توافق‌شده، هیچ از دست رفتن داده.

## گام ۱۳.۴ — فرآیند انتشار (full-chat §31)

```
tag → CI: build debs → build ISO/IMG → test-boot → integration (QEMU) → sign
    → publish dev → (تست دستی + سخت‌افزار) → promote beta → (pilot) → promote stable با rollout 10% → 50% → 100%
```

- تعیین نسخه پایدار: `1.0.0`؛ پس از آن `1.0.x` فقط رفع باگ/امنیت، `1.x` قابلیت.
- Release Notes فارسی برای کاربر (در manifest) + فنی در `docs/release/`.
- جدول سازگاری نسخه‌ها (Ban OS ↔ Agent API ↔ Center ↔ Adad ↔ Hardware API) در `docs/release/compatibility.md`.
- پشتیبانی نسخه‌ها: آخرین دو minor؛ وصله امنیتی Debian حداکثر ظرف ۷ روز روی stable.
- گزارش و رفع خطا: قالب گزارش (device_id + Support Bundle + مراحل)، شدت S1–S4، مسیر hotfix: شاخه `release/1.0` → build → beta ۲۴ساعت → stable.

## گام ۱۳.۵ — مستندات (p2)

مستندات تکنسین (`docs/operations/technician-guide-fa.md`: نصب، wizard، هر صفحه Ban Center، عیب‌یابی رایج، Recovery، کد اضطراری) · مستندات پشتیبانی (خواندن Support Bundle، جدول کدهای خطا و رویدادها، رویه Rollback) · کارت یک‌صفحه‌ای صندوق‌دار («اگر صفحه خطا دیدید…»).

## خروجی

«نسخه Production از Ban OS با فرآیند مشخص برای انتشار، نگهداری، بروزرسانی و پشتیبانی» (p1) + «نسخه Production از Ban Center» (p2) — **نقطه عطف M4: Ban OS 1.0.0 + Ban Center 1.0.0**

---

# تطبیق با «خروجی نهایی» p1 و p2

| خروجی نهایی p1 | مرحله |
| --- | --- |
| سیستم‌عامل اختصاصی مبتنی بر Debian | ۱ |
| بوت خودکار و اجرای محیط POS | ۲، ۳ |
| اجرای پایدار Adad | ۳ |
| حالت Maintenance برای تکنسین | ۳، ۵ |
| سرویس‌های مدیریتی و کنترلی | ۴ |
| پشتیبانی از سخت‌افزارهای POS | ۸ |
| سیستم ثبت رویداد و لاگ | ۴، ۶ |
| سیستم بروزرسانی | ۹ |
| Recovery و Backup | ۱۰ |
| کنترل دسترسی و امنیت | ۱۱ |
| نصب‌کننده و Image قابل انتشار | ۱۲، ۱۳ |
| زیرساخت آماده اتصال به Ban Desk و Ban Center | ۴ (`support.*` رزرو)، ۵ |
| امکان توسعه مدیریت متمرکز در Ban Cloud | ۴ (`ban-sync`)، ۱۲ (Activation) |

| خروجی نهایی p2 | مرحله |
| --- | --- |
| وضعیت کامل دستگاه | ۶ |
| مدیریت شبکه | ۷ |
| کنترل سرویس‌های مجاز | ۶ |
| مشاهده و تست سخت‌افزارها | ۸ |
| لاگ‌ها و Audit | ۶ |
| بروزرسانی‌ها | ۹ |
| Backup و Recovery | ۱۰ |
| کاربران و مجوزها | ۱۱ |
| ثبت و پیگیری عملیات حساس | ۴ (middleware)، ۱۱ |
| رابط فارسی مناسب تکنسین | ۵ |
| وضعیت Ban Desk · اتصال به Ban Cloud · مدیریت چند دستگاه | بعد از 1.0 |

قراردادهایی که p1 گفته از ابتدا باید با Ban Desk/Ban Center مشخص باشند — و جایشان: Device Identity (۱۲.۴) · وضعیت سرویس‌ها (۴.۱، ۶.۲) · رویدادها (۴.۲، ۴.۳) · بروزرسانی (۹.۲) · کنترل دسترسی (۱۱.۱).

# بعد از 1.0

| مورد | پیش‌نیازِ آماده‌شده در این نقشه |
| --- | --- |
| BC-10 Ban Cloud Integration | `ban-sync` + Outbox، Activation server، `network.diag.cloud`، صفحه Cloud |
| BC-11 Fleet Management | رویدادها و metrics استاندارد، `rollout.percent`، Device Identity |
| Ban Desk (BD-01…08) — RustDesk self-hosted | رویدادهای `REMOTE_SUPPORT_*`، نقش Support Agent، صفحه Remote Support، `support.toml`، انتخاب Xorg |
| A/B OS Update | پارتیشن System B، ارزیابی root فقط‌خواندنی، Health check و bootcount |
| Secure Boot و TPM | کلید دستگاه در مسیر جدا، `systemd-creds`، LUKS اختیاری |
