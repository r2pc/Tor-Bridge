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
run_cmd "apt update"

header "انتخاب پیش‌نیازها برای نصب"
declare -a available_packages=("ufw" "fail2ban" "net-tools" "iftop" "traceroute" "docker.io" "docker-buildx" "docker-compose-v2")
declare -A selection_status # آرایه انجمنی برای وضعیت انتخاب

# مقداردهی اولیه وضعیت انتخاب به انتخاب نشده
for package in "${available_packages[@]}"; do
    selection_status["$package"]=' '
done

selected_packages=()
current_index=0
num_packages="${#available_packages[@]}"

# ذخیره تنظیمات اولیه ترمینال
initial_tty_settings=$(stty -g)

while true; do
    clear # پاک کردن صفحه ترمینال در هر بار نمایش

    echo "لیست برنامه‌های قابل نصب (از کلیدهای جهت‌نما برای حرکت و اسپیس برای انتخاب استفاده کنید):"
    for i in "${!available_packages[@]}"; do
        package="${available_packages[$i]}"
        status="${selection_status["$package"]}"
        indicator=" "
        if [ "$i" -eq "$current_index" ]; then
            indicator="${GREEN}>${NC}"
        fi
        printf "%s [%s] %s\n" "$indicator" "$status" "$package"
    done

    echo -e "\n${YELLOW}برای تایید و ادامه نصب، Enter را فشار دهید.${NC}"

    # تنظیم ترمینال برای خواندن کلیدهای خاص
    stty -icanon -echo

    # خواندن یک کاراکتر ورودی
    read -r -n 1 key

    case "$key" in
        $'\E') # شروع دنباله escape
            read -r -n 1 char2
            case "$char2" in
                '[')
                    read -r -n 1 char3
                    case "$char3" in
                        'A') # کلید بالا
                            if [ "$current_index" -gt 0 ]; then
                                ((current_index--))
                            fi
                            ;;
                        'B') # کلید پایین
                            if [ "$current_index" -lt "$((num_packages - 1))" ]; then
                                ((current_index++))
                            fi
                            ;;
                        'C') # کلید راست (اختیاری)
                            ;;
                        'D') # کلید چپ (اختیاری)
                            ;;
                    esac
                    ;;
            esac
            ;;
        " ") # کلید اسپیس
            local current_package="${available_packages[$current_index]}"
            if [ "${selection_status["$current_package"]}" == " " ]; then
                selection_status["$current_package"]='X'
                selected_packages+=("$current_package")
            else
                selection_status["$current_package"]=' '
                selected_packages=($(printf "%s\n" "${selected_packages[@]}" | grep -v "^${current_package}$"))
            fi
            ;;
        $'\r') # کلید Enter
            break
            ;;
        $'\x03') # Ctrl+C برای خروج اضطراری
            stty "$initial_tty_settings"
            exit 1
            ;;
    esac

    # بازگرداندن تنظیمات اولیه ترمینال
    stty "$initial_tty_settings"

done

if [ -n "${selected_packages[*]}" ]; then
    header "نصب پیش‌نیازهای انتخاب شده"
    run_cmd "apt install -y ${selected_packages[*]}"
else
    echo -e "${YELLOW}هیچ برنامه‌ای برای نصب انتخاب نشد.${NC}"
fi

header "تنظیم Docker"
run_cmd "usermod -aG docker $SUDO_USER"

header "پیکربندی فایروال"
read -p "پورت SSH شما (پیش‌فرض: 22): " ssh_port
ssh_port=${ssh_port:-22}

run_cmd "ufw default deny incoming"
run_cmd "ufw default allow outgoing"
run_cmd "ufw allow $ssh_port"
run_cmd "ufw deny 2096/tcp"
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
