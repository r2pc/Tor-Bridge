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

# بررسی اینکه اسکریپت با sudo اجرا شده باشد
if [ -z "$SUDO_USER" ]; then
    echo -e "${RED}لطفاً اسکریپت را با sudo اجرا کنید.${NC}"
    exit 1
fi

header "به‌روزرسانی سیستم"
run_cmd "apt update && apt upgrade -y"

header "بررسی نصب بودن whiptail"
if ! command -v whiptail &>/dev/null; then
    echo -e "${YELLOW}نصب whiptail...${NC}"
    run_cmd "DEBIAN_FRONTEND=noninteractive apt install -y whiptail"
fi

header "انتخاب پیش‌نیازها برای نصب"
declare -a fixed_packages=("docker.io" "docker-buildx" "docker-compose-v2" "ufw" "fail2ban")
declare -a optional_packages=("vnstat" "net-tools" "iftop" "traceroute" "portainer")
declare -a options=()

# فیلتر کردن پکیج‌های نصب نشده از fixed_packages
actual_fixed_packages=()
for pkg in "${fixed_packages[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        actual_fixed_packages+=("$pkg")
        options+=("$pkg" "(required)" ON)
    fi
    # اگر نصب بود، نیازی به تلاش برای نصب مجدد نیست
done

# اضافه کردن پکیج‌های اختیاری
for pkg in "${optional_packages[@]}"; do
    options+=("$pkg" "" OFF)
done

if [ "${#options[@]}" -eq 0 ]; then
    echo -e "${GREEN}تمامی پیش‌نیازها قبلاً نصب شده‌اند. مرحله نصب پکیج‌ها رد شد.${NC}"
    selected_packages=()
else
    selected=$(whiptail --title "Select Required Packages" \
      --checklist "Select the packages you want to install:" \
      20 78 15 "${options[@]}" 3>&1 1>&2 2>&3)

    selected_packages=("${actual_fixed_packages[@]}")
    read -ra selected_array <<< "$selected"
    for pkg in "${selected_array[@]}"; do
        cleaned=$(echo "$pkg" | tr -d '"')
        if [[ ! " ${selected_packages[*]} " =~ " ${cleaned} " ]]; then
            selected_packages+=("$cleaned")
        fi
    done
fi

if [ "${#selected_packages[@]}" -gt 0 ]; then
    header "نصب پیش‌نیازهای انتخاب شده"
    run_cmd "DEBIAN_FRONTEND=noninteractive apt install -y ${selected_packages[*]}"
else
    echo -e "${YELLOW}هیچ برنامه‌ای برای نصب انتخاب نشد.${NC}"
fi

# نصب و پیکربندی Portainer در صورت انتخاب
if [[ " ${selected_packages[*]} " =~ " portainer " ]]; then
    header "راه‌اندازی Portainer"
    docker volume create portainer_data
    run_cmd "docker run -d -p 2053:2053 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce"

    if command -v ufw &>/dev/null; then
        run_cmd "ufw allow 2053/tcp"
    fi

    if whiptail --title "استفاده از دامنه برای Portainer" --yesno "آیا می‌خواهید دامنه‌ای برای دسترسی به Portainer تنظیم کنید؟ (مثلاً: portainer.example.com)" 10 60; then
        domain=$(whiptail --inputbox "دامنه مورد نظر را وارد کنید:" 10 60 3>&1 1>&2 2>&3)
        if [ -n "$domain" ]; then
            header "تنظیم Portainer برای استفاده با دامنه: $domain"
            echo -e "${YELLOW}توجه: برای راه‌اندازی با دامنه، پیشنهاد می‌شود reverse proxy مانند Nginx یا Caddy تنظیم شود.${NC}"
            echo "نمونه تنظیم Nginx برای دامنه $domain در پورت 2053:" 
            echo -e "\nserver {
    listen 80;
    server_name $domain;

    location / {
        proxy_pass http://localhost:2053/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}" 
        fi
    fi
fi

header "تنظیم Docker"
run_cmd "usermod -aG docker $SUDO_USER"

header "پیکربندی فایروال"
read -p "پورت SSH شما (پیش‌فرض: 22): " ssh_port
ssh_port=${ssh_port:-22}

if command -v ufw &>/dev/null; then
    run_cmd "ufw default deny incoming"
    run_cmd "ufw default allow outgoing"
    run_cmd "ufw allow $ssh_port"
    run_cmd "ufw deny 2096/tcp"
    run_cmd "ufw allow 8443/tcp"
    run_cmd "ufw --force enable"
fi

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

if command -v fail2ban-client &>/dev/null; then
    run_cmd "systemctl restart fail2ban"
fi

header "راه‌اندازی Tor Bridge"
if [ ! -f docker-compose.yml ]; then
    echo -e "${RED}فایل docker-compose.yml پیدا نشد.${NC}"
    exit 1
fi

# بررسی وجود docker compose فقط در صورت انتخاب آن
if ! command -v docker &>/dev/null || ! docker compose version &>/dev/null; then
    echo -e "${YELLOW}Docker یا Docker Compose در دسترس نیست. لطفاً مطمئن شوید که آن را از لیست نصب انتخاب کرده‌اید.${NC}"
    exit 1
fi

run_cmd "docker compose up -d --build"

header "صبر کنید تا Tor Bridge راه‌اندازی شود..."
sleep 5

header "نصب کامل شد"
echo -e "${GREEN}اطلاعات Bridge:${NC}"
run_cmd "sudo docker exec tor-bridge cat /var/lib/tor/fingerprint"
run_cmd "sudo docker exec tor-bridge cat /var/lib/tor/pt_state/obfs4_bridgeline.txt"

echo -e "\n${YELLOW}دستورات مدیریتی:${NC}"
echo "مشاهده لاگ‌ها: sudo docker logs -f tor-bridge"
echo "توقف سرویس: sudo docker compose down"
echo "شروع مجدد: sudo docker compose up -d"
echo "اجرای Nyx برای مشاهده وضعیت Tor (درون کانتینر): sudo docker exec -it tor-bridge nyx"
