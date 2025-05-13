#!/bin/bash
set -e

# تنظیم رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

function header() {
  echo -e "${GREEN}\n=== $1 ===${NC}"
}

function run_cmd() {
  echo -e "${YELLOW}$ $1${NC}"
  eval $1
}

header "به‌روزرسانی سیستم"
run_cmd "apt update && apt upgrade -y"

header "نصب پیش‌نیازها"
run_cmd "apt install -y ufw fail2ban net-tools iftop traceroute docker.io docker-buildx docker-compose-v2"

header "تنظیم Docker"
run_cmd "usermod -aG docker $SUDO_USER"

header "پیکربندی فایروال"
read -p "پورت SSH شما (پیش‌فرض: 22): " ssh_port
ssh_port=${ssh_port:-22}

run_cmd "ufw default deny incoming"
run_cmd "ufw default allow outgoing"
run_cmd "ufw allow $ssh_port"
run_cmd "ufw deny 2096"
run_cmd "ufw allow 8443/tcp"
run_cmd "ufw --force enable"

header "تنظیم Fail2Ban"
cat > /etc/fail2ban/jail.local <<EOL
[sshd]
enabled = true
port = $ssh_port
filter = sshd
logpath = %(sshd_log)s
maxretry = 3
bantime = 1h
EOL

run_cmd "systemctl restart fail2ban"

header "راه‌اندازی Tor Bridge"
run_cmd "docker compose up -d --build"

# اضافه کردن تاخیر قبل از اجرای دستورات docker exec
header "صبر کنید تا Tor Bridge راه‌اندازی شود..."
sleep 5

header "نصب کامل شد"
echo -e "${GREEN}اطلاعات Bridge:${NC}"
run_cmd "sudo docker exec tor-bridge cat /var/lib/tor/fingerprint"
run_cmd "sudo docker exec tor-bridge cat /var/lib/tor/pt_state/obfs4_bridgeline.txt"

echo -e "\n${YELLOW}دستورات مدیریتی:${NC}"
echo "مشاهده لاگ‌ها: docker logs -f tor-bridge"
echo "توقف سرویس: docker compose down"
echo "شروع مجدد: docker compose up -d"
