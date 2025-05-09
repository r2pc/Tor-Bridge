# 🏴‍☠️ نصب و راه اندازی خودکار Tor Bridge روی Docker

پیکربندی کامل Tor Bridge با obfs4proxy در کمتر از 1 دقیقه!

## 🚀 نصب با یک دستور

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/r2pc/Tor-Bridge/main/setup.sh)"

📌 اطلاعات فنی

پورت‌ها:
ORPort: 2096/tcp
obfs4: 8443/tcp
کانفیگ‌ها:
No-Exit Policy
Bridge Mode
پشتیبانی از obfs4proxy
🔍 پس از نصب

bash
# مشاهده لاگ‌ها
tail -f /opt/tor-bridge/logs/notices.log

# دریافت اطلاعات Bridge
docker exec tor-bridge cat /var/lib/tor/fingerprint
docker exec tor-bridge cat /var/lib/tor/pt_state/obfs4_bridgeline.txt

⚙️ مدیریت سرویس

       دستور                                        	توضیح
cd /opt/tor-bridge && docker-compose up -d	راه‌اندازی سرویس
cd /opt/tor-bridge && docker-compose down	توقف سرویس
docker ps --filter name=tor-bridge	وضعیت کانتینر
ufw status	وضعیت فایروال

❓ راهنمای عیب‌یابی

اگر اطلاعات Bridge نمایش داده نشد، 2-3 دقیقه صبر کنید و دوباره چک کنید
برای بررسی خطاها: docker logs tor-bridge
اگر پورت‌ها باز نشدند: ufw disable && ufw enable

📜 لیسانس

MIT License - استفاده برای اهداف غیرقانونی ممنوع است


