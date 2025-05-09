#!/bin/bash

# رنگ‌ها برای نمایش زیباتر
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# بررسی دسترسی root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}✖ این اسکریپت باید با دسترسی sudo اجرا شود${NC}"
  exit 1
fi

echo -e "${GREEN}➤ در حال نصب Tor Bridge روی سرور شما...${NC}"

# مرحله 1: نصب پیش‌نیازها
echo -e "${YELLOW}▷ در حال آپدیت سیستم و نصب پیش‌نیازها...${NC}"
apt update -qq && apt upgrade -y -qq
apt install -y -qq \
    git \
    docker.io \
    docker-compose \
    ufw \
    obfs4proxy

# مرحله 2: تنظیم فایروال
echo -e "${YELLOW}▷ تنظیم فایروال...${NC}"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 2096/tcp   # ORPort
ufw allow 8443/tcp   # obfs4
ufw allow 22/tcp     # SSH
ufw --force enable

# مرحله 3: دانلود و راه‌اندازی
echo -e "${YELLOW}▷ دریافت فایل‌های پیکربندی...${NC}"
repo_dir="/opt/tor-bridge"
if [ ! -d "$repo_dir" ]; then
  git clone https://github.com/r2pc/tor-bridge.git $repo_dir
else
  echo -e "${YELLOW}⚠ پوشه قبلاً وجود دارد، از نسخه موجود استفاده می‌شود${NC}"
fi

# مرحله 4: اجرای سرویس
echo -e "${YELLOW}▷ راه‌اندازی سرویس Tor Bridge...${NC}"
cd $repo_dir
docker-compose up --build -d

# مرحله 5: نمایش اطلاعات
echo -e "${GREEN}✔ نصب با موفقیت انجام شد!${NC}"
echo -e "\n${YELLOW}════════════════════════════════════════════${NC}"
echo -e "${GREEN}📌 اطلاعات Bridge شما:${NC}"

sleep 5  # منتظر بمانید تا سرویس کامل راه‌اندازی شود

echo -e "\n${YELLOW}🔑 Fingerprint:${NC}"
docker exec tor-bridge cat /var/lib/tor/fingerprint 2>/dev/null || \
echo -e "${RED}⚠ هنوز تولید نشده! چند دقیقه دیگر تلاش کنید${NC}"

echo -e "\n${YELLOW}🔗 خط اتصال obfs4:${NC}"
docker exec tor-bridge cat /var/lib/tor/pt_state/obfs4_bridgeline.txt 2>/dev/null || \
echo -e "${RED}⚠ هنوز تولید نشده! چند دقیقه دیگر بررسی کنید${NC}"

echo -e "\n${YELLOW}📝 برای مشاهده لاگ‌ها:${NC} tail -f $repo_dir/logs/notices.log"
echo -e "${YELLOW}════════════════════════════════════════════${NC}"
