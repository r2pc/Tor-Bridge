```markdown
# 🌉 Dockerized TorRelay Setup

![Tor Network](https://upload.wikimedia.org/wikipedia/commons/1/15/Tor-logo-2011-flat.svg)

یک راه‌حل کامل برای راه‌اندازی Bridge Relay با obfs4 روی Docker

## ✨ ویژگی‌های کلیدی

- 🛡️ **امنیت پیشرفته** با UFW + Fail2Ban
- 🐳 **بهینه‌شده برای Docker** با حجم کم
- ⚡ **راه‌اندازی در 1 دقیقه**
- 📡 **پشتیبانی از obfs4proxy**
- 🕒 **منطقه زمانی تهران** (Asia/Tehran)

## 🚀 شروع سریع

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/r2pc/tor-bridge/main/setup.sh)"
```

## 📌 مشخصات فنی

| بخش | تنظیمات |
|------|---------|
| **پورت‌ها** | ORPort: 2096/tcp • obfs4: 8443/tcp |
| **حالت کاری** | Bridge Relay (غیر خروجی) |
| **UID/GID** | 100:101 |
| **لاگ‌ها** | /var/log/tor/notices.log |

## 🔧 دستورات مدیریتی

### مدیریت سرویس
```bash
# راه‌اندازی
docker compose up -d

# توقف
docker compose down

# مشاهده لاگ‌ها
docker logs -f tor-bridge
```

### مدیریت امنیت
```bash
# وضعیت فایروال
ufw status

# وضعیت Fail2Ban
fail2ban-client status sshd
```

## 📂 ساختار پروژه
```
tor-bridge/
├── docker-compose.yml
├── Dockerfile
├── torrc
└── setup.sh
```

## ❓ راهنمای عیب‌یابی

### اگر Bridge نمایش داده نشد:
```bash
docker exec tor-bridge cat /var/lib/tor/fingerprint
```

### اگر پورت‌ها باز نشدند:
```bash
ufw disable && ufw enable
```

## 📜 لیسانس
MIT License - استفاده برای اهداف غیرقانونی ممنوع است

> ℹ️ **نکته**: این راه‌اندازی بهینه‌شده برای سرورهای ایرانی با UID/GID ثابت

---

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Tor](https://img.shields.io/badge/Tor-7D4698?style=for-the-badge&logo=Tor-Browser&logoColor=white)
```
