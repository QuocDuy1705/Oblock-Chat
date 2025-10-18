#!/bin/bash

###############################################################################
# NETWORK MONITOR - Giám sát Ping, Latency, Packet Loss
# Theo dõi chất lượng kết nối mạng real-time
###############################################################################

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Servers để test (gaming servers & DNS)
SERVERS=(
    "8.8.8.8:Google DNS"
    "1.1.1.1:Cloudflare DNS"
    "208.67.222.222:OpenDNS"
)

# Hàm hiển thị banner
show_banner() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${GREEN}        NETWORK MONITOR - Giám sát Mạng Gaming          ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Hàm kiểm tra ping với màu sắc
check_ping() {
    local host=$1
    local name=$2
    
    # Ping 5 lần
    result=$(ping -c 5 -W 2 $host 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        # Lấy thông số
        avg_ping=$(echo "$result" | tail -1 | awk -F '/' '{print $5}')
        min_ping=$(echo "$result" | tail -1 | awk -F '/' '{print $4}')
        max_ping=$(echo "$result" | tail -1 | awk -F '/' '{print $6}')
        packet_loss=$(echo "$result" | grep -oP '\d+(?=% packet loss)')
        
        # Xác định màu dựa trên ping
        if (( $(echo "$avg_ping < 30" | bc -l) )); then
            color=$GREEN
            status="EXCELLENT"
        elif (( $(echo "$avg_ping < 60" | bc -l) )); then
            color=$CYAN
            status="GOOD"
        elif (( $(echo "$avg_ping < 100" | bc -l) )); then
            color=$YELLOW
            status="FAIR"
        else
            color=$RED
            status="POOR"
        fi
        
        printf "${color}%-20s${NC} │ ${color}%8.2f ms${NC} │ %8.2f ms │ %8.2f ms │ %7s%% │ ${color}%s${NC}\n" \
            "$name" "$avg_ping" "$min_ping" "$max_ping" "$packet_loss" "$status"
    else
        printf "${RED}%-20s${NC} │ ${RED}  TIMEOUT ${NC} │          - │          - │       - │ ${RED}FAIL${NC}\n" "$name"
    fi
}

# Hàm hiển thị network statistics
show_network_stats() {
    echo -e "\n${YELLOW}═══ Network Interface Statistics ═══${NC}"
    
    for interface in $(ls /sys/class/net/ | grep -v lo); do
        if [ -d "/sys/class/net/$interface" ]; then
            # Kiểm tra interface có active không
            if [ "$(cat /sys/class/net/$interface/operstate)" = "up" ]; then
                echo -e "\n${GREEN}Interface: $interface${NC}"
                
                # RX/TX Statistics
                rx_bytes=$(cat /sys/class/net/$interface/statistics/rx_bytes)
                tx_bytes=$(cat /sys/class/net/$interface/statistics/tx_bytes)
                rx_packets=$(cat /sys/class/net/$interface/statistics/rx_packets)
                tx_packets=$(cat /sys/class/net/$interface/statistics/tx_packets)
                rx_errors=$(cat /sys/class/net/$interface/statistics/rx_errors)
                tx_errors=$(cat /sys/class/net/$interface/statistics/tx_errors)
                
                # Convert to MB
                rx_mb=$(echo "scale=2; $rx_bytes / 1048576" | bc)
                tx_mb=$(echo "scale=2; $tx_bytes / 1048576" | bc)
                
                echo -e "  ${CYAN}RX:${NC} ${rx_mb} MB (${rx_packets} packets, ${rx_errors} errors)"
                echo -e "  ${CYAN}TX:${NC} ${tx_mb} MB (${tx_packets} packets, ${tx_errors} errors)"
                
                # Queue Discipline
                qdisc=$(tc qdisc show dev $interface | head -1 | awk '{print $2}')
                echo -e "  ${CYAN}QDisc:${NC} $qdisc"
                
                # Speed
                if [ -f "/sys/class/net/$interface/speed" ]; then
                    speed=$(cat /sys/class/net/$interface/speed 2>/dev/null)
                    if [ ! -z "$speed" ] && [ "$speed" != "-1" ]; then
                        echo -e "  ${CYAN}Speed:${NC} ${speed} Mbps"
                    fi
                fi
            fi
        fi
    done
}

# Hàm hiển thị connection info
show_connection_info() {
    echo -e "\n${YELLOW}═══ Connection Information ═══${NC}"
    
    # TCP Congestion Control
    cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    echo -e "${CYAN}TCP Congestion:${NC} $cc"
    
    # Queue Discipline
    qd=$(sysctl -n net.core.default_qdisc 2>/dev/null)
    echo -e "${CYAN}Queue Discipline:${NC} $qd"
    
    # Active connections
    tcp_conn=$(ss -tan | grep ESTAB | wc -l)
    udp_conn=$(ss -uan | wc -l)
    echo -e "${CYAN}TCP Connections:${NC} $tcp_conn active"
    echo -e "${CYAN}UDP Connections:${NC} $udp_conn active"
}

# Hàm giám sát continuous
continuous_monitor() {
    while true; do
        show_banner
        
        echo -e "${YELLOW}Server               │  Avg Ping  │  Min Ping  │  Max Ping  │  Loss   │ Status${NC}"
        echo -e "${BLUE}─────────────────────┼────────────┼────────────┼────────────┼─────────┼────────${NC}"
        
        # Test từng server
        for server_info in "${SERVERS[@]}"; do
            IFS=':' read -r host name <<< "$server_info"
            check_ping "$host" "$name"
        done
        
        show_connection_info
        show_network_stats
        
        echo -e "\n${CYAN}[Cập nhật mỗi 5 giây - Nhấn Ctrl+C để thoát]${NC}"
        echo -e "${YELLOW}Thời gian: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
        
        sleep 5
    done
}

# Hàm test một lần
single_test() {
    show_banner
    
    echo -e "${YELLOW}Server               │  Avg Ping  │  Min Ping  │  Max Ping  │  Loss   │ Status${NC}"
    echo -e "${BLUE}─────────────────────┼────────────┼────────────┼────────────┼─────────┼────────${NC}"
    
    for server_info in "${SERVERS[@]}"; do
        IFS=':' read -r host name <<< "$server_info"
        check_ping "$host" "$name"
    done
    
    show_connection_info
    show_network_stats
}

# Hàm test bufferbloat
test_bufferbloat() {
    show_banner
    echo -e "${YELLOW}═══ Bufferbloat Test ═══${NC}"
    echo -e "${CYAN}Đang test bufferbloat với ping dưới tải...${NC}\n"
    
    # Ping trước khi tải
    echo -e "${YELLOW}1. Ping không tải (baseline):${NC}"
    ping -c 10 8.8.8.8 | tail -2
    
    echo -e "\n${YELLOW}2. Đang tạo tải mạng...${NC}"
    # Tạo tải bằng cách download
    timeout 20 curl -o /dev/null http://speedtest.tele2.net/10MB.zip &>/dev/null &
    LOAD_PID=$!
    
    sleep 2
    
    echo -e "${YELLOW}3. Ping dưới tải (testing bufferbloat):${NC}"
    ping -c 10 8.8.8.8 | tail -2
    
    # Dọn dẹp
    kill $LOAD_PID 2>/dev/null
    wait $LOAD_PID 2>/dev/null
    
    echo -e "\n${GREEN}✓ Test hoàn tất${NC}"
    echo -e "${CYAN}Nếu ping tăng đáng kể dưới tải = có bufferbloat${NC}"
    echo -e "${CYAN}Nếu ping ổn định = bufferbloat thấp (tốt)${NC}"
}

# Menu chính
show_menu() {
    show_banner
    echo -e "${YELLOW}Chọn chế độ giám sát:${NC}\n"
    echo -e "  ${GREEN}1.${NC} Giám sát liên tục (real-time)"
    echo -e "  ${GREEN}2.${NC} Test một lần"
    echo -e "  ${GREEN}3.${NC} Test Bufferbloat"
    echo -e "  ${GREEN}4.${NC} Thêm server tùy chỉnh"
    echo -e "  ${GREEN}5.${NC} Thoát"
    echo ""
    read -p "Lựa chọn [1-5]: " choice
    
    case $choice in
        1) continuous_monitor ;;
        2) single_test ;;
        3) test_bufferbloat ;;
        4) add_custom_server ;;
        5) echo -e "${GREEN}Tạm biệt!${NC}"; exit 0 ;;
        *) echo -e "${RED}Lựa chọn không hợp lệ${NC}"; sleep 2; show_menu ;;
    esac
}

# Hàm thêm server tùy chỉnh
add_custom_server() {
    show_banner
    echo -e "${YELLOW}Thêm Server Tùy Chỉnh${NC}\n"
    read -p "Nhập IP hoặc hostname: " custom_host
    read -p "Nhập tên server: " custom_name
    
    if [ ! -z "$custom_host" ] && [ ! -z "$custom_name" ]; then
        SERVERS+=("$custom_host:$custom_name")
        echo -e "\n${GREEN}✓ Đã thêm: $custom_name ($custom_host)${NC}"
    else
        echo -e "\n${RED}✗ Thông tin không hợp lệ${NC}"
    fi
    
    sleep 2
    show_menu
}

# Kiểm tra dependencies
check_dependencies() {
    local missing=()
    
    command -v ping >/dev/null 2>&1 || missing+=("iputils-ping")
    command -v bc >/dev/null 2>&1 || missing+=("bc")
    command -v tc >/dev/null 2>&1 || missing+=("iproute2")
    command -v ss >/dev/null 2>&1 || missing+=("iproute2")
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Missing dependencies: ${missing[*]}${NC}"
        echo -e "${YELLOW}Install with: sudo apt install ${missing[*]}${NC}"
        exit 1
    fi
}

# Main
main() {
    check_dependencies
    
    if [ "$1" == "--continuous" ] || [ "$1" == "-c" ]; then
        continuous_monitor
    elif [ "$1" == "--once" ] || [ "$1" == "-o" ]; then
        single_test
    elif [ "$1" == "--bufferbloat" ] || [ "$1" == "-b" ]; then
        test_bufferbloat
    else
        show_menu
    fi
}

# Trap Ctrl+C
trap 'echo -e "\n${GREEN}Đã dừng giám sát${NC}"; exit 0' INT

main "$@"
