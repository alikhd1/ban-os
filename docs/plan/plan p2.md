۳. پنل مدیریت — Ban Center

محور سوم پروژه Ban OS

Ban Center برنامه مدیریتی اختصاصی Ban OS است که به تکنسین، مدیر سیستم و تیم پشتیبانی اجازه می‌دهد وضعیت دستگاه را مشاهده و عملیات مدیریتی مجاز را از طریق یک رابط واحد انجام دهند.

Ban Center باید به‌عنوان Control Plane سیستم‌عامل عمل کند، نه جایگزینی برای سرویس‌های استاندارد Linux.

نمای کلی فازهای Ban Center

فاز

	

عنوان

	

هدف




BC-01

	

پایه Ban Center

	

ایجاد ساختار برنامه، معماری و ارتباط با Ban Agent




BC-02

	

System Management

	

مشاهده و مدیریت وضعیت سیستم




BC-03

	

Network Management

	

مدیریت شبکه و اتصال اینترنت




BC-04

	

Service Management

	

مشاهده و کنترل سرویس‌های سیستم




BC-05

	

Hardware Management

	

مدیریت و تست سخت‌افزارهای POS




BC-06

	

Logs & Audit

	

مشاهده لاگ‌ها و رویدادهای سیستمی




BC-07

	

Update Management

	

مشاهده و مدیریت بروزرسانی‌ها




BC-08

	

Backup & Recovery

	

مدیریت پشتیبان‌گیری و بازیابی




BC-09

	

User & Access Management

	

مدیریت کاربران و دسترسی‌ها




BC-10

	

Ban Cloud Integration

	

اتصال به زیرساخت مرکزی Ban




BC-11

	

Fleet Management

	

مدیریت و مانیتورینگ چندین دستگاه




BC-12

	

Production Release

	

آماده‌سازی نسخه Production

معماری کلی Ban Center
┌──────────────────────────────────────────────┐
│                  Ban Center                  │
│                                              │
│  Dashboard                                  │
│  System                                     │
│  Network                                    │
│  Services                                   │
│  Hardware                                   │
│  Logs & Audit                               │
│  Updates                                    │
│  Backup & Recovery                          │
│  Users & Access                             │
│  Remote Support                             │
└──────────────────────┬───────────────────────┘
                       │
                       │ Local IPC
                       ▼
┌──────────────────────────────────────────────┐
│                 Ban Agent                    │
│                                              │
│  System Controller                           │
│  Network Controller                          │
│  Service Controller                          │
│  Hardware Controller                         │
│  Log Controller                              │
│  Update Controller                           │
│  Recovery Controller                         │
│  Permission Controller                       │
└──────────────────────┬───────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│            Linux & Ban Services              │
│                                              │
│ systemd · NetworkManager · CUPS · journald  │
│ udev · Ban Event · Ban Update · Ban Desk    │
└──────────────────────────────────────────────┘
اصل ارتباط

Ban Center نباید برای هر عملیات مستقیماً با دسترسی Root به Linux متصل شود. عملیات مدیریتی باید از طریق Ban Agent و با مجوزهای محدود، کنترل‌شده و قابل ثبت انجام شوند.

BC-01 — پایه Ban Center
هدف

ایجاد ساختار اولیه برنامه مدیریتی و زیرساخت ارتباطی آن با Ban Agent.

حوزه‌ها

انتخاب فناوری رابط کاربری

ساختار پروژه Ban Center

معماری صفحات و Navigation

ارتباط با Ban Agent

مدیریت وضعیت برنامه

مدیریت خطاهای ارتباطی

مدل دسترسی اولیه

طراحی قالب بصری Ban OS

مدیریت تنظیمات برنامه

ساختار تست

خروجی

یک نسخه اولیه از Ban Center که می‌تواند به Ban Agent متصل شود و ساختار اصلی پنل را نمایش دهد.

BC-02 — System Management
هدف

ارائه نمای کلی از وضعیت سیستم‌عامل و منابع سخت‌افزاری دستگاه.

بخش‌های اصلی

وضعیت CPU

وضعیت RAM

فضای ذخیره‌سازی

دمای سیستم

مدت زمان روشن بودن دستگاه

وضعیت بوت

وضعیت سیستم‌عامل

اطلاعات Kernel

اطلاعات دستگاه

وضعیت اتصال برق

وضعیت نمایشگر

وضعیت عملکرد سیستم

فرآیندهای فعال

هشدارهای سیستمی

صفحات پیشنهادی

System Overview

Device Information

Resource Usage

Performance

System Health

خروجی

مدیر یا تکنسین می‌تواند وضعیت کلی دستگاه را از یک صفحه مشاهده کند و مشکلات اولیه سیستم را شناسایی کند.

BC-03 — Network Management
هدف

مدیریت تنظیمات شبکه از طریق رابط اختصاصی Ban Center، با استفاده از NetworkManager به‌عنوان سرویس زیرساختی.

حوزه‌های اصلی

Ethernet

Wi-Fi

DHCP

Static IP

Gateway

DNS

اتصال و قطع شبکه

مدیریت شبکه‌های Wi-Fi

مشاهده IP و MAC Address

بررسی اتصال اینترنت

تست DNS

تست Gateway

وضعیت اتصال به Ban Cloud

وضعیت اتصال به سرویس‌های موردنیاز

مدیریت تنظیمات شبکه در حالت Maintenance

صفحات پیشنهادی

Network Overview

Ethernet Settings

Wi-Fi Settings

IP Configuration

Connection Diagnostics

Cloud Connectivity

خروجی

تکنسین بتواند تنظیمات شبکه و مشکلات اتصال را بدون نیاز به استفاده مستقیم از ترمینال مدیریت کند.

مرز مسئولیت: Ban Center رابط کاربری شبکه است؛ NetworkManager وظیفه مدیریت واقعی اتصال‌ها و تنظیمات شبکه را بر عهده دارد.

BC-04 — Service Management
هدف

مشاهده و مدیریت سرویس‌های Ban OS و سرویس‌های موردنیاز POS.

سرویس‌های هدف

Adad POS

Adad Launcher

Ban Agent

Ban Event

Ban Sync

Ban Update

Ban Desk

CUPS

NetworkManager

سایر سرویس‌های اختصاصی Ban OS

قابلیت‌های اصلی

مشاهده وضعیت سرویس

مشاهده زمان آخرین اجرا

مشاهده خطاهای سرویس

شروع سرویس

توقف سرویس

Restart سرویس

فعال یا غیرفعال بودن Startup

مشاهده وابستگی‌ها

مشاهده وضعیت Health Check

ثبت عملیات مدیریتی

کنترل دسترسی

عملیات حساس مانند توقف Adad، تغییر Startup یا Restart سرویس‌های حیاتی باید نیازمند سطح دسترسی مناسب باشند.

خروجی

تکنسین بتواند وضعیت سرویس‌ها را بررسی و عملیات مجاز را از طریق یک رابط کنترل‌شده انجام دهد.

BC-05 — Hardware Management
هدف

مشاهده، پیکربندی و تست تجهیزات متصل به پایانه فروش.

تجهیزات هدف

چاپگر رسید

بارکدخوان

کشوی پول

نمایشگر مشتری

ترازو

صفحه لمسی

کارت‌خوان

USB Devices

Serial Devices

تجهیزات شبکه

سایر تجهیزات POS

حوزه‌های اصلی

فهرست تجهیزات شناسایی‌شده

وضعیت اتصال دستگاه

مدل و شناسه سخت‌افزار

تنظیمات تجهیزات

انتخاب پورت و رابط ارتباطی

تست عملیاتی دستگاه

بررسی خطاهای اتصال

مدیریت Driver و Adapter

ذخیره تنظیمات تجهیزات

مشاهده تاریخچه خطاها

تست‌های نمونه

تست چاپ

تست بارکدخوان

تست کشوی پول

تست نمایشگر مشتری

تست ارتباط با ترازو

تست پورت ارتباطی

تست وضعیت کارت‌خوان

خروجی

تکنسین بتواند تجهیزات POS را شناسایی، پیکربندی و آزمایش کند.

BC-06 — Logs & Audit
هدف

ارائه یک مرکز مشاهده و بررسی رویدادهای سیستم، نرم‌افزار، امنیت و عملیات مدیریتی.

دسته‌بندی لاگ‌ها

دسته

	

محتوا




System Logs

	

رویدادهای سیستم‌عامل




Application Logs

	

رویدادهای Adad و برنامه‌ها




Hardware Logs

	

خطاها و وضعیت تجهیزات




Network Logs

	

رویدادهای اتصال و شبکه




Security Logs

	

ورودها و عملیات حساس




Support Logs

	

جلسات پشتیبانی و Ban Desk




Update Logs

	

بروزرسانی‌ها و نتایج آن‌ها




Audit Logs

	

عملیات انجام‌شده توسط کاربران و تکنسین‌ها

قابلیت‌های اصلی

مشاهده فهرست رویدادها

جست‌وجو

فیلتر بر اساس نوع رویداد

فیلتر بر اساس شدت

فیلتر بر اساس بازه زمانی

مشاهده جزئیات رویداد

نمایش شناسه دستگاه

مشاهده عامل ایجاد رویداد

خروجی گرفتن از لاگ‌ها

گزارش خطاهای مهم

نمایش وضعیت همگام‌سازی رویدادها

محدودسازی دسترسی به رویدادهای حساس

خروجی

یک Log Viewer و Audit Viewer یکپارچه که امکان بررسی مشکلات دستگاه و پیگیری عملیات مدیریتی را فراهم می‌کند.

BC-07 — Update Management
هدف

مدیریت وضعیت نسخه‌ها و فرآیند بروزرسانی Ban OS و اجزای نرم‌افزاری آن.

اجزای تحت مدیریت

نسخه Ban OS

نسخه Adad POS

نسخه Ban Center

نسخه Ban Agent

نسخه Hardware Layer

نسخه سرویس‌های سیستم

نسخه تنظیمات و سیاست‌ها

حوزه‌های اصلی

مشاهده نسخه فعلی

بررسی نسخه جدید

مشاهده Release Notes

نمایش وضعیت بروزرسانی

شروع بروزرسانی

زمان‌بندی بروزرسانی

مشاهده تاریخچه

اعتبارسنجی بسته‌ها

نمایش خطای بروزرسانی

Rollback در صورت پشتیبانی

نمایش وضعیت دستگاه در هنگام بروزرسانی

خروجی

مدیر بتواند وضعیت بروزرسانی دستگاه را مشاهده کند و تکنسین بتواند فرآیندهای مجاز بروزرسانی را مدیریت کند.

BC-08 — Backup & Recovery
هدف

ارائه امکانات مدیریت پشتیبان‌گیری، بازیابی و عملیات Recovery از طریق رابط مدیریتی.

حوزه‌های اصلی

وضعیت Backup

تاریخ آخرین پشتیبان

Backup دیتابیس

Backup تنظیمات

Backup اطلاعات دستگاه

انتخاب مقصد پشتیبان

بازیابی تنظیمات

بازیابی دیتابیس

مشاهده وضعیت فضای ذخیره‌سازی

Recovery Mode

Factory Reset

بررسی صحت Backup

تاریخچه عملیات بازیابی

کنترل‌های ضروری

احراز هویت مجدد برای عملیات حساس

تأیید صریح کاربر

نمایش هشدار درباره از دست رفتن اطلاعات

ثبت کامل عملیات در Audit Log

محدودیت دسترسی به Factory Reset

جلوگیری از اجرای عملیات ناسازگار با وضعیت دستگاه

خروجی

تکنسین بتواند عملیات پشتیبان‌گیری و بازیابی مجاز را به‌صورت کنترل‌شده انجام دهد.

BC-09 — User & Access Management
هدف

مدیریت کاربران، نقش‌ها و سطح دسترسی به امکانات Ban Center و عملیات حساس سیستم.

نقش‌های پیشنهادی

نقش

	

محدوده دسترسی




POS Operator

	

استفاده از محیط فروش




Store Manager

	

مشاهده وضعیت و تنظیمات محدود




Technician

	

تعمیرات و مدیریت سیستم




Support Agent

	

پشتیبانی از راه دور با مجوز




System Administrator

	

مدیریت کامل و تنظیمات حساس

حوزه‌های اصلی

مدیریت کاربران

نقش‌ها و مجوزها

ورود به Maintenance Mode

احراز هویت مجدد

مدیریت Session

محدودیت زمانی دسترسی

ثبت ورود و خروج

ثبت عملیات حساس

مدیریت دسترسی آفلاین

مدیریت دسترسی اضطراری

خروجی

مدل دسترسی مشخص و قابل حسابرسی برای کاربران مختلف Ban Center.

BC-10 — Ban Cloud Integration
هدف

اتصال Ban Center و Ban OS به زیرساخت مرکزی Ban برای مشاهده وضعیت دستگاه، همگام‌سازی رویدادها و مدیریت متمرکز.

حوزه‌های اصلی

ثبت دستگاه

Device Identity

وضعیت اتصال به Cloud

همگام‌سازی تنظیمات مجاز

ارسال رویدادها

دریافت سیاست‌ها

دریافت اطلاعات بروزرسانی

وضعیت آخرین Sync

مدیریت خطاهای اتصال

وضعیت احراز هویت دستگاه

ارتباط با زیرساخت Ban Desk

داده‌های قابل همگام‌سازی

مشخصات دستگاه

نسخه سیستم‌عامل

نسخه Adad

وضعیت سرویس‌ها

وضعیت سخت‌افزارها

رویدادهای منتخب

وضعیت شبکه

وضعیت بروزرسانی

اطلاعات سلامت سیستم

خروجی

Ban Center قادر به نمایش وضعیت اتصال و اطلاعات مدیریتی مرتبط با سرویس مرکزی Ban خواهد بود.

BC-11 — Fleet Management
هدف

مدیریت و مانیتورینگ چندین دستگاه Ban OS از طریق زیرساخت مرکزی.

این فاز به قابلیت‌های مرکزی Ban Cloud و پنل مدیریت سازمانی وابسته است و صرفاً مدیریت دستگاه محلی نیست.

حوزه‌های اصلی

فهرست دستگاه‌ها

جست‌وجو و فیلتر دستگاه‌ها

گروه‌بندی دستگاه‌ها

وضعیت آنلاین و آفلاین

وضعیت سلامت دستگاه

وضعیت Adad

وضعیت Ban OS

وضعیت چاپگر و تجهیزات

وضعیت فضای دیسک

وضعیت بروزرسانی

مشاهده خطاهای مهم

مدیریت نسخه‌ها

مدیریت سیاست‌ها

شروع عملیات پشتیبانی

مشاهده تاریخچه دستگاه

گزارش‌گیری

نماهای پیشنهادی

Fleet Overview

Device Details

Device Health

Device Events

Update Status

Support Status

Device Groups

خروجی

مدیریت مرکزی تعداد زیادی دستگاه و مشاهده وضعیت آن‌ها بدون نیاز به اتصال دستی به هر پایانه.

BC-12 — Production Release
هدف

آماده‌سازی نسخه نهایی Ban Center برای استفاده واقعی در دستگاه‌های مشتریان و محیط‌های پشتیبانی.

حوزه‌های اصلی

تست عملکرد رابط کاربری

تست ارتباط با Ban Agent

تست مجوزها

تست عملیات حساس

تست قطع ارتباط با سرویس‌ها

تست خطاهای شبکه

تست عملکرد روی سخت‌افزارهای هدف

تست خوانایی و کاربردپذیری

تست Maintenance Mode

تست ثبت رویدادها

تست امنیت

مدیریت نسخه

بسته‌بندی و انتشار

فرآیند بروزرسانی

مستندات تکنسین

مستندات پشتیبانی

خروجی

نسخه Production از Ban Center که قابل نصب و استفاده در محیط واقعی Ban OS باشد.

ساختار پیشنهادی صفحات Ban Center
Ban Center
│
├── Dashboard
│   ├── System Overview
│   ├── Device Health
│   ├── Service Status
│   ├── Network Status
│   └── Recent Events
│
├── System
│   ├── Overview
│   ├── Performance
│   ├── Storage
│   ├── Processes
│   └── Device Information
│
├── Network
│   ├── Overview
│   ├── Ethernet
│   ├── Wi-Fi
│   ├── IP Configuration
│   └── Diagnostics
│
├── Services
│   ├── All Services
│   ├── Ban Services
│   ├── Adad Services
│   └── Service Details
│
├── Hardware
│   ├── Overview
│   ├── Printers
│   ├── Barcode Scanner
│   ├── Cash Drawer
│   ├── Customer Display
│   ├── Scale
│   └── Payment Terminal
│
├── Logs & Audit
│   ├── System Logs
│   ├── Application Logs
│   ├── Security Logs
│   ├── Support Logs
│   ├── Update Logs
│   └── Audit Logs
│
├── Updates
│   ├── Current Versions
│   ├── Available Updates
│   ├── Update History
│   └── Update Settings
│
├── Backup & Recovery
│   ├── Backup Status
│   ├── Create Backup
│   ├── Restore
│   └── Recovery
│
├── Users & Access
│   ├── Users
│   ├── Roles
│   ├── Permissions
│   └── Sessions
│
├── Remote Support
│   ├── Ban Desk Status
│   ├── Connection Status
│   ├── Active Session
│   └── Support History
│
└── Settings
    ├── General
    ├── Security
    ├── Cloud
    └── Maintenance
ساختار پیشنهادی پروژه Ban Center
ban-center/
│
├── README.md
├── pyproject.toml
├── VERSION
│
├── app/
│   ├── main.py
│   ├── bootstrap/
│   ├── config/
│   ├── permissions/
│   └── session/
│
├── ui/
│   ├── shell/
│   ├── navigation/
│   ├── dashboard/
│   ├── system/
│   ├── network/
│   ├── services/
│   ├── hardware/
│   ├── logs/
│   ├── updates/
│   ├── recovery/
│   ├── users/
│   └── support/
│
├── application/
│   ├── system/
│   ├── network/
│   ├── services/
│   ├── hardware/
│   ├── logs/
│   ├── updates/
│   ├── recovery/
│   └── support/
│
├── infrastructure/
│   ├── ban-agent-client/
│   ├── ipc/
│   ├── serialization/
│   └── error-handling/
│
├── domain/
│   ├── devices/
│   ├── services/
│   ├── events/
│   ├── updates/
│   └── permissions/
│
├── resources/
│   ├── icons/
│   ├── themes/
│   ├── fonts/
│   └── translations/
│
├── tests/
│   ├── unit/
│   ├── integration/
│   └── ui/
│
└── packaging/
    ├── desktop-entry/
    ├── systemd/
    └── installer/

این ساختار نمونه است و می‌تواند با توجه به فناوری نهایی، مانند PyQt/PySide یا یک رابط دیگر، تغییر کند.

مرزبندی مسئولیت Ban Center و Ban Agent

قابلیت

	

Ban Center

	

Ban Agent




نمایش وضعیت سیستم

	

رابط نمایش

	

جمع‌آوری اطلاعات




تنظیم شبکه

	

فرم و تعامل کاربر

	

اجرای عملیات مجاز




مدیریت سرویس

	

نمایش و درخواست

	

ارتباط با systemd




مدیریت چاپگر

	

تنظیمات و تست

	

ارتباط با CUPS




مشاهده لاگ

	

جست‌وجو و نمایش

	

دسترسی و جمع‌آوری




بروزرسانی

	

نمایش و شروع عملیات

	

اعتبارسنجی و اجرا




Recovery

	

رابط و تأیید

	

اجرای عملیات کنترل‌شده




مجوزها

	

نمایش و جریان احراز هویت

	

اعمال سیاست‌های دسترسی




رویدادها

	

نمایش نتیجه عملیات

	

ثبت رویدادهای قابل حسابرسی

الزامات مشترک تمام فازها

این موارد باید در طراحی تمام بخش‌های Ban Center در نظر گرفته شوند:

Role-Based Access Control: کنترل دسترسی بر اساس نقش

Auditability: ثبت عملیات حساس

Least Privilege: حداقل سطح دسترسی موردنیاز

Error Handling: نمایش خطای قابل فهم و قابل پیگیری

Offline Tolerance: رفتار مشخص در زمان قطع ارتباط با Cloud

Consistency: یکپارچگی وضعیت نمایش‌داده‌شده با وضعیت واقعی سرویس‌ها

Confirmation: تأیید عملیات مخرب یا برگشت‌ناپذیر

Observability: امکان بررسی وضعیت و علت خطا

Localization: پشتیبانی از زبان فارسی و رابط راست‌به‌چپ

Version Compatibility: سازگاری نسخه Ban Center، Ban Agent و Ban OS

وابستگی فازها
BC-01
  │
  ├── BC-02 ──┐
  ├── BC-03   │
  ├── BC-04   ├── BC-06
  ├── BC-05   │
  │           ├── BC-07
  │           ├── BC-08
  │           └── BC-09
  │
  └─────────────────────┐
                        ▼
                    BC-10
                        │
                        ▼
                    BC-11
                        │
                        ▼
                    BC-12

برخی فازها می‌توانند به‌صورت موازی توسعه پیدا کنند، اما زیرساخت ارتباطی BC-01 و قابلیت‌های پایه Ban Agent باید پیش از یکپارچه‌سازی گسترده آماده باشند.

خروجی نهایی محور Ban Center

در پایان این محور، Ban Center باید امکان انجام موارد زیر را داشته باشد:

مشاهده وضعیت کامل دستگاه Ban OS

مدیریت تنظیمات شبکه

مشاهده و کنترل سرویس‌های مجاز

مشاهده و تست سخت‌افزارها

مشاهده لاگ‌ها و رویدادهای Audit

مشاهده و مدیریت بروزرسانی‌ها

انجام Backup و Recovery

مدیریت کاربران و مجوزها

مشاهده وضعیت Ban Desk

اتصال به Ban Cloud

مدیریت متمرکز چندین دستگاه

ثبت و پیگیری عملیات حساس

ارائه رابط مدیریتی فارسی و مناسب تکنسین‌ها

اصل نهایی: Ban Center باید یک رابط مدیریتی قابل اعتماد و کنترل‌شده روی Ban OS باشد؛ منطق اصلی عملیات سیستمی در Ban Agent و سرویس‌های استاندارد Linux باقی می‌ماند و Ban Center وظیفه تعامل، نمایش وضعیت، درخواست عملیات و ارائه بازخورد به کاربر را بر عهده دارد.