#!/bin/bash

###############################################################################
# DNS OPTIMIZER
# Tối ưu hóa DNS để giảm delay khi kết nối server
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Vui lòng chạy với quyền root (sudo)${NC}"
    exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}    DNS OPTIMIZER - Tối ưu DNS cho Gaming${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

# DNS servers to test
DNS_SERVERS=(
    "1.1.1.1:Cloudflare"
    "1.0.0.1:Cloudflare Secondary"
    "8.8.8.8:Google"
    "8.8.4.4:Google Secondary"
    "208.67.222.222:OpenDNS"
    "208.67.220.220:OpenDNS Secondary"
    "9.9.9.9:Quad9"
    "149.112.112.112:Quad9 Secondary"
)

# Test DNS speed
test_dns_speed() {
    local dns=$1
    local name=$2
    
    # Test with multiple domains
    local total_time=0
    local test_domains=("google.com" "facebook.com" "amazon.com" "youtube.com" "github.com")
    
    for domain in "${test_domains[@]}"; do
        # Measure DNS lookup time
        time=$(dig @$dns $domain +stats | grep "Query time:" | awk '{print $4}')
        if [ ! -z "$time" ]; then
            total_time=$((total_time + time))
        else
            return 1
        fi
    done
    
    # Average time
    avg_time=$((total_time / ${#test_domains[@]}))
    echo "$avg_time"
}

# Find fastest DNS
find_fastest_dns() {
    echo -e "\n${YELLOW}Đang test tốc độ các DNS servers...${NC}"
    echo -e "${CYAN}(Có thể mất 30-60 giây)${NC}\n"
    
    echo -e "${YELLOW}DNS Server           │  Avg Time  │  Status${NC}"
    echo -e "${BLUE}─────────────────────┼────────────┼──────────${NC}"
    
    local fastest_dns=""
    local fastest_time=99999
    local results=()
    
    for server_info in "${DNS_SERVERS[@]}"; do
        IFS=':' read -r dns name <<< "$server_info"
        
        time=$(test_dns_speed "$dns" "$name")
        
        if [ $? -eq 0 ] && [ ! -z "$time" ]; then
            results+=("$time:$dns:$name")
            
            if [ $time -lt $fastest_time ]; then
                fastest_time=$time
                fastest_dns=$dns
            fi
            
            # Color based on speed
            if [ $time -lt 20 ]; then
                color=$GREEN
                status="EXCELLENT"
            elif [ $time -lt 50 ]; then
                color=$CYAN
                status="GOOD"
            elif [ $time -lt 100 ]; then
                color=$YELLOW
                status="FAIR"
            else
                color=$RED
                status="SLOW"
            fi
            
            printf "${color}%-20s${NC} │ %6s ms │ ${color}%s${NC}\n" "$name" "$time" "$status"
        else
            printf "${RED}%-20s${NC} │    FAILED │ ${RED}ERROR${NC}\n" "$name"
        fi
    done
    
    echo -e "\n${GREEN}✓ DNS nhanh nhất: $fastest_dns (${fastest_time}ms)${NC}"
    echo "$fastest_dns"
}

# Configure DNS
configure_dns() {
    local primary_dns=$1
    local secondary_dns=${2:-"1.1.1.1"}
    
    echo -e "\n${YELLOW}Cấu hình DNS...${NC}"
    
    # Backup original resolv.conf
    if [ ! -f /etc/resolv.conf.backup ]; then
        cp /etc/resolv.conf /etc/resolv.conf.backup
        echo -e "${GREEN}✓ Đã backup /etc/resolv.conf${NC}"
    fi
    
    # Check if using systemd-resolved
    if systemctl is-active --quiet systemd-resolved; then
        echo -e "${CYAN}Hệ thống dùng systemd-resolved${NC}"
        
        # Configure systemd-resolved
        mkdir -p /etc/systemd/resolved.conf.d/
        cat > /etc/systemd/resolved.conf.d/dns.conf << EOF
[Resolve]
DNS=$primary_dns $secondary_dns
FallbackDNS=8.8.8.8 8.8.4.4
DNSSEC=no
DNSOverTLS=no
Cache=yes
CacheFromLocalhost=no
EOF
        
        systemctl restart systemd-resolved
        echo -e "${GREEN}✓ Đã cấu hình systemd-resolved${NC}"
        
    else
        # Traditional resolv.conf
        cat > /etc/resolv.conf << EOF
# DNS Optimizer - Gaming DNS Configuration
nameserver $primary_dns
nameserver $secondary_dns
options timeout:1
options attempts:2
options rotate
EOF
        
        # Prevent overwriting
        chattr +i /etc/resolv.conf 2>/dev/null
        echo -e "${GREEN}✓ Đã cấu hình /etc/resolv.conf${NC}"
    fi
}

# Optimize DNS caching
optimize_dns_cache() {
    echo -e "\n${YELLOW}Tối ưu hóa DNS cache...${NC}"
    
    # Install dnsmasq for local caching if not present
    if ! command -v dnsmasq &> /dev/null; then
        echo -e "${CYAN}Cài đặt dnsmasq cho local DNS cache...${NC}"
        apt-get update -qq
        apt-get install -y dnsmasq
    fi
    
    # Configure dnsmasq for gaming
    cat > /etc/dnsmasq.d/gaming-dns.conf << 'EOF'
# Gaming DNS Cache Configuration
cache-size=10000
no-negcache
dns-forward-max=1000
min-cache-ttl=300
max-cache-ttl=3600

# Parallel queries
strict-order
all-servers

# Performance
no-poll
no-resolv
EOF
    
    # Set upstream DNS
    echo "server=$1" >> /etc/dnsmasq.d/gaming-dns.conf
    
    systemctl restart dnsmasq
    systemctl enable dnsmasq
    
    echo -e "${GREEN}✓ DNS cache đã được tối ưu với dnsmasq${NC}"
}

# Test current DNS
test_current_dns() {
    echo -e "\n${YELLOW}Test DNS hiện tại...${NC}"
    
    # Get current DNS
    if systemctl is-active --quiet systemd-resolved; then
        current_dns=$(resolvectl status | grep "Current DNS Server" | awk '{print $4}')
    else
        current_dns=$(grep "^nameserver" /etc/resolv.conf | head -1 | awk '{print $2}')
    fi
    
    echo -e "${CYAN}DNS hiện tại: $current_dns${NC}"
    
    # Test lookup time
    echo -e "\n${CYAN}Test lookup time:${NC}"
    for domain in "google.com" "facebook.com" "github.com"; do
        time=$(dig $domain +stats | grep "Query time:" | awk '{print $4}')
        echo -e "  $domain: ${time}ms"
    done
}

# Show DNS status
show_status() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}DNS Status:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    if systemctl is-active --quiet systemd-resolved; then
        echo -e "\n${YELLOW}systemd-resolved:${NC}"
        resolvectl status | grep -A 5 "Global"
    else
        echo -e "\n${YELLOW}/etc/resolv.conf:${NC}"
        cat /etc/resolv.conf | grep -v "^#"
    fi
    
    if systemctl is-active --quiet dnsmasq; then
        echo -e "\n${YELLOW}dnsmasq:${NC} ${GREEN}Active${NC}"
        echo -e "${CYAN}Cache stats:${NC}"
        pkill -USR1 dnsmasq
        sleep 1
        tail -20 /var/log/syslog | grep dnsmasq | tail -5
    fi
}

# Main menu
show_menu() {
    echo -e "\n${YELLOW}Chọn chế độ:${NC}\n"
    echo -e "  ${GREEN}1.${NC} Auto - Tìm và dùng DNS nhanh nhất"
    echo -e "  ${GREEN}2.${NC} Cloudflare (1.1.1.1)"
    echo -e "  ${GREEN}3.${NC} Google (8.8.8.8)"
    echo -e "  ${GREEN}4.${NC} OpenDNS (208.67.222.222)"
    echo -e "  ${GREEN}5.${NC} Test DNS hiện tại"
    echo -e "  ${GREEN}6.${NC} Khôi phục cấu hình gốc"
    echo -e "  ${GREEN}7.${NC} Hiển thị status"
    echo -e "  ${GREEN}8.${NC} Thoát"
    echo ""
    read -p "Lựa chọn [1-8]: " choice
    
    case $choice in
        1)
            fastest=$(find_fastest_dns)
            configure_dns "$fastest"
            optimize_dns_cache "$fastest"
            test_current_dns
            ;;
        2)
            configure_dns "1.1.1.1" "1.0.0.1"
            optimize_dns_cache "1.1.1.1"
            test_current_dns
            ;;
        3)
            configure_dns "8.8.8.8" "8.8.4.4"
            optimize_dns_cache "8.8.8.8"
            test_current_dns
            ;;
        4)
            configure_dns "208.67.222.222" "208.67.220.220"
            optimize_dns_cache "208.67.222.222"
            test_current_dns
            ;;
        5)
            test_current_dns
            read -p "Nhấn Enter để tiếp tục..."
            show_menu
            ;;
        6)
            if [ -f /etc/resolv.conf.backup ]; then
                chattr -i /etc/resolv.conf 2>/dev/null
                cp /etc/resolv.conf.backup /etc/resolv.conf
                echo -e "${GREEN}✓ Đã khôi phục cấu hình gốc${NC}"
            fi
            systemctl stop dnsmasq 2>/dev/null
            systemctl disable dnsmasq 2>/dev/null
            ;;
        7)
            show_status
            read -p "Nhấn Enter để tiếp tục..."
            show_menu
            ;;
        8)
            echo -e "${GREEN}Tạm biệt!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Lựa chọn không hợp lệ${NC}"
            sleep 2
            show_menu
            ;;
    esac
    
    echo -e "\n${GREEN}✓ Hoàn tất!${NC}"
}

# Check dependencies
check_dependencies() {
    local missing=()
    
    command -v dig >/dev/null 2>&1 || missing+=("dnsutils")
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}Cài đặt dependencies...${NC}"
        apt-get update -qq
        apt-get install -y ${missing[*]}
    fi
}

# Main
main() {
    check_dependencies
    show_menu
}

main
