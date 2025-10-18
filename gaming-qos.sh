#!/bin/bash

###############################################################################
# GAMING QoS SCRIPT
# Ưu tiên traffic gaming, giảm lag khi có nhiều thiết bị dùng mạng
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Vui lòng chạy với quyền root (sudo)${NC}"
    exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}    GAMING QoS - Ưu tiên Traffic Gaming${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

# Cấu hình
UPLOAD_SPEED=${1:-100}  # Mbps - tốc độ upload của bạn (mặc định 100)
DOWNLOAD_SPEED=${2:-100}  # Mbps - tốc độ download của bạn (mặc định 100)

# Chuyển đổi sang Kbps
UPLOAD_KBPS=$((UPLOAD_SPEED * 1000))
DOWNLOAD_KBPS=$((DOWNLOAD_SPEED * 1000))

# Gaming ports - các port phổ biến của games
GAMING_TCP_PORTS="27015,27016,3074,3075,6112,9308,27000:27050,30000:30009"
GAMING_UDP_PORTS="27015,27016,3074,3075,3658,5223,6112,9308,27000:27050,30000:30009,3478,3479"

# Specific game ports
# Valorant: 7000-8000 UDP
# League of Legends: 5000-5500 UDP, 8393-8400 TCP
# CS:GO/CS2: 27015-27030 UDP/TCP
# Dota 2: 27015-27050 UDP/TCP
# Fortnite: 9000-9100 UDP
# PUBG: 7000-8000 UDP
# Apex Legends: 37000-40000 TCP

configure_qos() {
    local interface=$1
    
    echo -e "\n${YELLOW}Cấu hình QoS cho interface: $interface${NC}"
    
    # Xóa qdisc cũ
    tc qdisc del dev $interface root 2>/dev/null
    
    # Tạo root qdisc với HTB (Hierarchical Token Bucket)
    tc qdisc add dev $interface root handle 1: htb default 30
    
    # Class chính - tổng băng thông
    tc class add dev $interface parent 1: classid 1:1 htb rate ${UPLOAD_KBPS}kbit ceil ${UPLOAD_KBPS}kbit
    
    # Class 1:10 - Gaming traffic (priority cao nhất - 40% bandwidth)
    tc class add dev $interface parent 1:1 classid 1:10 htb rate $((UPLOAD_KBPS * 40 / 100))kbit ceil ${UPLOAD_KBPS}kbit prio 0
    
    # Class 1:20 - VoIP/Streaming (priority cao - 25% bandwidth)
    tc class add dev $interface parent 1:1 classid 1:20 htb rate $((UPLOAD_KBPS * 25 / 100))kbit ceil ${UPLOAD_KBPS}kbit prio 1
    
    # Class 1:30 - Normal traffic (priority trung bình - 25% bandwidth)
    tc class add dev $interface parent 1:1 classid 1:30 htb rate $((UPLOAD_KBPS * 25 / 100))kbit ceil ${UPLOAD_KBPS}kbit prio 2
    
    # Class 1:40 - Bulk/Download (priority thấp - 10% bandwidth)
    tc class add dev $interface parent 1:1 classid 1:40 htb rate $((UPLOAD_KBPS * 10 / 100))kbit ceil $((UPLOAD_KBPS * 80 / 100))kbit prio 3
    
    # Thêm fq_codel cho mỗi class để giảm bufferbloat
    tc qdisc add dev $interface parent 1:10 handle 10: fq_codel quantum 300 noecn
    tc qdisc add dev $interface parent 1:20 handle 20: fq_codel quantum 300 noecn
    tc qdisc add dev $interface parent 1:30 handle 30: fq_codel quantum 300 noecn
    tc qdisc add dev $interface parent 1:40 handle 40: fq_codel quantum 300 noecn
    
    # Filters - phân loại traffic
    
    # Gaming TCP traffic
    tc filter add dev $interface protocol ip parent 1:0 prio 0 u32 match ip dport 27015 0xffff flowid 1:10
    tc filter add dev $interface protocol ip parent 1:0 prio 0 u32 match ip sport 27015 0xffff flowid 1:10
    
    # Gaming - mark traffic với iptables DSCP
    tc filter add dev $interface protocol ip parent 1:0 prio 0 handle 1 fw flowid 1:10
    
    # VoIP/Video - Discord, Zoom, Teams
    tc filter add dev $interface protocol ip parent 1:0 prio 1 u32 match ip dport 50000 0xff00 flowid 1:20
    tc filter add dev $interface protocol ip parent 1:0 prio 1 handle 2 fw flowid 1:20
    
    # Bulk traffic - torrents, downloads
    tc filter add dev $interface protocol ip parent 1:0 prio 3 u32 match ip dport 6881 0xff00 flowid 1:40
    tc filter add dev $interface protocol ip parent 1:0 prio 3 handle 4 fw flowid 1:40
    
    echo -e "${GREEN}✓ QoS đã được cấu hình cho $interface${NC}"
}

configure_iptables_marking() {
    echo -e "\n${YELLOW}Cấu hình iptables marking...${NC}"
    
    # Xóa rules cũ trong mangle table
    iptables -t mangle -F
    
    # Gaming traffic - mark 1 (highest priority)
    iptables -t mangle -A POSTROUTING -p tcp -m multiport --dports $GAMING_TCP_PORTS -j MARK --set-mark 1
    iptables -t mangle -A POSTROUTING -p udp -m multiport --dports $GAMING_UDP_PORTS -j MARK --set-mark 1
    iptables -t mangle -A POSTROUTING -p tcp -m multiport --sports $GAMING_TCP_PORTS -j MARK --set-mark 1
    iptables -t mangle -A POSTROUTING -p udp -m multiport --sports $GAMING_UDP_PORTS -j MARK --set-mark 1
    
    # Valorant
    iptables -t mangle -A POSTROUTING -p udp --dport 7000:8000 -j MARK --set-mark 1
    iptables -t mangle -A POSTROUTING -p udp --sport 7000:8000 -j MARK --set-mark 1
    
    # League of Legends
    iptables -t mangle -A POSTROUTING -p udp --dport 5000:5500 -j MARK --set-mark 1
    iptables -t mangle -A POSTROUTING -p tcp --dport 8393:8400 -j MARK --set-mark 1
    
    # Fortnite
    iptables -t mangle -A POSTROUTING -p udp --dport 9000:9100 -j MARK --set-mark 1
    
    # Apex Legends
    iptables -t mangle -A POSTROUTING -p tcp --dport 37000:40000 -j MARK --set-mark 1
    
    # VoIP/Streaming - mark 2
    # Discord
    iptables -t mangle -A POSTROUTING -p udp --dport 50000:65535 -j MARK --set-mark 2
    # Zoom
    iptables -t mangle -A POSTROUTING -p udp --dport 8801:8810 -j MARK --set-mark 2
    
    # DNS - priority cao
    iptables -t mangle -A POSTROUTING -p udp --dport 53 -j MARK --set-mark 1
    iptables -t mangle -A POSTROUTING -p tcp --dport 53 -j MARK --set-mark 1
    
    # DSCP marking
    iptables -t mangle -A POSTROUTING -m mark --mark 1 -j DSCP --set-dscp-class EF
    iptables -t mangle -A POSTROUTING -m mark --mark 2 -j DSCP --set-dscp-class AF41
    
    # Bulk traffic - torrents, mark 4 (lowest priority)
    iptables -t mangle -A POSTROUTING -p tcp --dport 6881:6889 -j MARK --set-mark 4
    iptables -t mangle -A POSTROUTING -p udp --dport 6881:6889 -j MARK --set-mark 4
    
    echo -e "${GREEN}✓ iptables marking đã được cấu hình${NC}"
}

show_status() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Trạng thái QoS:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    for interface in $(ls /sys/class/net/ | grep -v lo); do
        if [ -d "/sys/class/net/$interface" ] && [ "$(cat /sys/class/net/$interface/operstate)" = "up" ]; then
            echo -e "\n${YELLOW}Interface: $interface${NC}"
            tc -s qdisc show dev $interface
            echo ""
            tc -s class show dev $interface
        fi
    done
}

remove_qos() {
    echo -e "\n${YELLOW}Xóa cấu hình QoS...${NC}"
    
    for interface in $(ls /sys/class/net/ | grep -v lo); do
        if [ -d "/sys/class/net/$interface" ]; then
            tc qdisc del dev $interface root 2>/dev/null
            echo -e "${GREEN}✓ Đã xóa QoS khỏi $interface${NC}"
        fi
    done
    
    iptables -t mangle -F
    echo -e "${GREEN}✓ Đã xóa iptables marking${NC}"
}

# Main
case "$3" in
    remove)
        remove_qos
        ;;
    status)
        show_status
        ;;
    *)
        echo -e "\n${CYAN}Tốc độ Upload: ${UPLOAD_SPEED} Mbps${NC}"
        echo -e "${CYAN}Tốc độ Download: ${DOWNLOAD_SPEED} Mbps${NC}"
        echo ""
        read -p "Đúng không? (y/n): " confirm
        
        if [ "$confirm" != "y" ]; then
            echo -e "${YELLOW}Sử dụng: sudo $0 <upload_mbps> <download_mbps>${NC}"
            echo -e "${YELLOW}Ví dụ: sudo $0 50 100${NC}"
            exit 1
        fi
        
        configure_iptables_marking
        
        for interface in $(ls /sys/class/net/ | grep -v lo); do
            if [ -d "/sys/class/net/$interface" ] && [ "$(cat /sys/class/net/$interface/operstate)" = "up" ]; then
                configure_qos $interface
            fi
        done
        
        show_status
        
        echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}✓ Gaming QoS đã được kích hoạt!${NC}"
        echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}Lưu ý:${NC}"
        echo -e "  • Gaming traffic được ưu tiên cao nhất"
        echo -e "  • Chạy '$0 remove' để xóa QoS"
        echo -e "  • Chạy '$0 status' để xem trạng thái"
        echo ""
        ;;
esac
