#!/bin/bash

###############################################################################
# ANTI GHOST BULLET (WHITE BULLET) OPTIMIZER
# Giảm ghost bullets - viên đạn bắn nhưng không gây damage
# Nguyên nhân: packet loss, jitter, tick rate mismatch, client-server desync
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

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${GREEN}     ANTI GHOST BULLET - Xóa Viên Đạn Trắng            ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

# Backup
backup_settings() {
    echo -e "\n${YELLOW}[1/8] Backup cấu hình...${NC}"
    BACKUP_DIR="/etc/anti-ghostbullet-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    sysctl -a > "$BACKUP_DIR/sysctl_backup.conf" 2>/dev/null
    echo -e "${GREEN}✓ Đã backup vào: $BACKUP_DIR${NC}"
}

# Optimize packet transmission (giảm packet loss)
optimize_packet_transmission() {
    echo -e "\n${YELLOW}[2/8] Tối ưu packet transmission (giảm packet loss)...${NC}"
    
    # Tăng buffer để tránh packet drops
    sysctl -w net.core.rmem_max=268435456
    sysctl -w net.core.wmem_max=268435456
    sysctl -w net.core.rmem_default=33554432
    sysctl -w net.core.wmem_default=33554432
    
    # Tối ưu UDP (game packets)
    sysctl -w net.ipv4.udp_rmem_min=16384
    sysctl -w net.ipv4.udp_wmem_min=16384
    
    # Tăng queue cho packet processing
    sysctl -w net.core.netdev_max_backlog=10000
    sysctl -w net.core.netdev_budget=600
    sysctl -w net.core.netdev_budget_usecs=4000
    
    # Giảm packet loss với flow control
    sysctl -w net.ipv4.tcp_moderate_rcvbuf=1
    
    echo -e "${GREEN}✓ Packet transmission đã được tối ưu${NC}"
}

# Reduce jitter (hitreg consistency)
reduce_jitter() {
    echo -e "\n${YELLOW}[3/8] Giảm jitter (cải thiện hitreg)...${NC}"
    
    # Ưu tiên real-time packet processing
    sysctl -w net.ipv4.tcp_low_latency=1
    sysctl -w net.ipv4.tcp_sack=1
    
    # Giảm coalescing delay
    for interface in $(ls /sys/class/net/ | grep -v lo); do
        if [ -d "/sys/class/net/$interface" ] && [ "$(cat /sys/class/net/$interface/operstate)" = "up" ]; then
            # Tắt interrupt coalescing để giảm jitter
            ethtool -C $interface rx-usecs 0 2>/dev/null
            ethtool -C $interface tx-usecs 0 2>/dev/null
            ethtool -C $interface rx-frames 1 2>/dev/null
            ethtool -C $interface tx-frames 1 2>/dev/null
            
            echo -e "${GREEN}✓ Đã giảm jitter cho $interface${NC}"
        fi
    done
    
    # Pacing rate optimization
    sysctl -w net.ipv4.tcp_pacing_ss_ratio=200
    sysctl -w net.ipv4.tcp_pacing_ca_ratio=120
    
    echo -e "${GREEN}✓ Jitter đã được giảm thiểu${NC}"
}

# Optimize tick rate sync
optimize_tickrate() {
    echo -e "\n${YELLOW}[4/8] Tối ưu tick rate synchronization...${NC}"
    
    # Giảm timer slack để tăng độ chính xác
    sysctl -w kernel.timer_migration=0
    
    # Tăng polling rate cho network
    sysctl -w net.core.busy_poll=50
    sysctl -w net.core.busy_read=50
    
    # Disable động để tránh packet bunching
    for interface in $(ls /sys/class/net/ | grep -v lo); do
        if [ -d "/sys/class/net/$interface" ] && [ "$(cat /sys/class/net/$interface/operstate)" = "up" ]; then
            ethtool -C $interface adaptive-rx off 2>/dev/null
            ethtool -C $interface adaptive-tx off 2>/dev/null
            echo -e "${GREEN}✓ Đã tối ưu tick sync cho $interface${NC}"
        fi
    done
    
    echo -e "${GREEN}✓ Tick rate sync đã được tối ưu${NC}"
}

# Packet prioritization (gaming packets first)
prioritize_gaming_packets() {
    echo -e "\n${YELLOW}[5/8] Ưu tiên gaming packets...${NC}"
    
    # Real-time priority cho gaming traffic
    iptables -t mangle -F PREROUTING 2>/dev/null
    iptables -t mangle -F OUTPUT 2>/dev/null
    
    # Gaming UDP ports - TOS/DSCP marking cho lowest latency
    GAMING_PORTS="27000:27050,3074:3075,5000:5500,6112,7000:8000,9000:9100,27015:27030,30000:30009,6672,61455:61458,30211:30217"
    
    # Mark gaming packets với highest priority
    iptables -t mangle -A OUTPUT -p udp -m multiport --dports $GAMING_PORTS -j TOS --set-tos 0x10
    iptables -t mangle -A OUTPUT -p udp -m multiport --sports $GAMING_PORTS -j TOS --set-tos 0x10
    
    # DSCP EF (Expedited Forwarding) cho gaming
    iptables -t mangle -A OUTPUT -p udp -m multiport --dports $GAMING_PORTS -j DSCP --set-dscp-class EF
    
    # Ưu tiên receive packets
    iptables -t mangle -A PREROUTING -p udp -m multiport --sports $GAMING_PORTS -j DSCP --set-dscp-class EF
    
    echo -e "${GREEN}✓ Gaming packets được ưu tiên cao nhất${NC}"
}

# Anti packet loss aggressive
anti_packet_loss() {
    echo -e "\n${YELLOW}[6/8] Chống packet loss aggressive...${NC}"
    
    # Tăng socket buffer
    sysctl -w net.ipv4.tcp_mem="786432 1048576 26777216"
    sysctl -w net.ipv4.udp_mem="786432 1048576 26777216"
    
    # Tăng connection tracking
    sysctl -w net.netfilter.nf_conntrack_max=1048576 2>/dev/null || true
    
    # Ring buffer optimization
    for interface in $(ls /sys/class/net/ | grep -v lo); do
        if [ -d "/sys/class/net/$interface" ] && [ "$(cat /sys/class/net/$interface/operstate)" = "up" ]; then
            # Tăng ring buffers
            MAX_RX=$(ethtool -g $interface 2>/dev/null | grep "^RX:" | head -1 | awk '{print $2}')
            MAX_TX=$(ethtool -g $interface 2>/dev/null | grep "^TX:" | head -1 | awk '{print $2}')
            
            if [ ! -z "$MAX_RX" ] && [ "$MAX_RX" != "n/a" ]; then
                ethtool -G $interface rx $MAX_RX 2>/dev/null && echo -e "  ${CYAN}RX ring: $MAX_RX${NC}"
            fi
            
            if [ ! -z "$MAX_TX" ] && [ "$MAX_TX" != "n/a" ]; then
                ethtool -G $interface tx $MAX_TX 2>/dev/null && echo -e "  ${CYAN}TX ring: $MAX_TX${NC}"
            fi
        fi
    done
    
    # Giảm packet drop với better queuing
    sysctl -w net.core.default_qdisc=fq
    
    echo -e "${GREEN}✓ Packet loss prevention đã được kích hoạt${NC}"
}

# Client-Server sync optimization
optimize_client_server_sync() {
    echo -e "\n${YELLOW}[7/8] Tối ưu Client-Server synchronization...${NC}"
    
    # TCP timestamp cho better RTT calculation
    sysctl -w net.ipv4.tcp_timestamps=1
    
    # Tắt delay ACK cho faster response
    sysctl -w net.ipv4.tcp_quickack=1
    
    # TCP Fast Open cho reconnection nhanh
    sysctl -w net.ipv4.tcp_fastopen=3
    
    # Giảm retransmission timeout
    sysctl -w net.ipv4.tcp_retries2=8
    
    # Early retransmit
    sysctl -w net.ipv4.tcp_early_retrans=3
    
    # MTU probing để tránh fragmentation
    sysctl -w net.ipv4.tcp_mtu_probing=1
    
    echo -e "${GREEN}✓ Client-Server sync đã được tối ưu${NC}"
}

# Save configuration
save_configuration() {
    echo -e "\n${YELLOW}[8/8] Lưu cấu hình vĩnh viễn...${NC}"
    
    cat > /etc/sysctl.d/98-anti-ghostbullet.conf << 'EOF'
# Anti Ghost Bullet Configuration
# Giảm packet loss, jitter, cải thiện hitreg

# Packet Transmission Optimization
net.core.rmem_max = 268435456
net.core.wmem_max = 268435456
net.core.rmem_default = 33554432
net.core.wmem_default = 33554432
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384

# Network Queue Optimization
net.core.netdev_max_backlog = 10000
net.core.netdev_budget = 600
net.core.netdev_budget_usecs = 4000

# Jitter Reduction
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_pacing_ss_ratio = 200
net.ipv4.tcp_pacing_ca_ratio = 120

# Tick Rate Optimization
kernel.timer_migration = 0
net.core.busy_poll = 50
net.core.busy_read = 50

# Packet Loss Prevention
net.ipv4.tcp_mem = 786432 1048576 26777216
net.ipv4.udp_mem = 786432 1048576 26777216
net.core.default_qdisc = fq

# Client-Server Sync
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_quickack = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_early_retrans = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_moderate_rcvbuf = 1
EOF

    sysctl -p /etc/sysctl.d/98-anti-ghostbullet.conf
    
    # Save iptables rules
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/anti-ghostbullet.rules
    
    echo -e "${GREEN}✓ Cấu hình đã được lưu vĩnh viễn${NC}"
}

# Test connection quality
test_connection() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Test chất lượng kết nối:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}1. Packet Loss Test:${NC}"
    loss=$(ping -c 100 -i 0.2 8.8.8.8 2>/dev/null | grep -oP '\d+(?=% packet loss)')
    if [ ! -z "$loss" ]; then
        if [ "$loss" -eq 0 ]; then
            echo -e "   ${GREEN}✓ Packet Loss: 0% (EXCELLENT)${NC}"
        elif [ "$loss" -lt 1 ]; then
            echo -e "   ${CYAN}○ Packet Loss: ${loss}% (GOOD)${NC}"
        else
            echo -e "   ${YELLOW}! Packet Loss: ${loss}% (Cần cải thiện)${NC}"
        fi
    fi
    
    echo -e "\n${YELLOW}2. Jitter Test:${NC}"
    jitter=$(ping -c 50 -i 0.2 8.8.8.8 2>/dev/null | tail -1 | awk -F '/' '{print $7}')
    if [ ! -z "$jitter" ]; then
        jitter_int=${jitter%.*}
        if [ "$jitter_int" -lt 3 ]; then
            echo -e "   ${GREEN}✓ Jitter: ${jitter}ms (EXCELLENT)${NC}"
        elif [ "$jitter_int" -lt 10 ]; then
            echo -e "   ${CYAN}○ Jitter: ${jitter}ms (GOOD)${NC}"
        else
            echo -e "   ${YELLOW}! Jitter: ${jitter}ms (Cần cải thiện)${NC}"
        fi
    fi
    
    echo -e "\n${YELLOW}3. Latency Consistency:${NC}"
    ping -c 20 -i 0.2 8.8.8.8 2>/dev/null | tail -1
}

# Show status
show_status() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Trạng thái Anti Ghost Bullet:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}Buffer Sizes:${NC}"
    echo -e "  RX Max: $(sysctl -n net.core.rmem_max) bytes"
    echo -e "  TX Max: $(sysctl -n net.core.wmem_max) bytes"
    
    echo -e "\n${YELLOW}Network Queue:${NC}"
    echo -e "  Backlog: $(sysctl -n net.core.netdev_max_backlog)"
    echo -e "  Budget: $(sysctl -n net.core.netdev_budget)"
    
    echo -e "\n${YELLOW}TCP Settings:${NC}"
    echo -e "  Low Latency: $(sysctl -n net.ipv4.tcp_low_latency)"
    echo -e "  Quick ACK: $(sysctl -n net.ipv4.tcp_quickack)"
    echo -e "  Fast Open: $(sysctl -n net.ipv4.tcp_fastopen)"
    
    echo -e "\n${YELLOW}Network Interfaces:${NC}"
    for interface in $(ls /sys/class/net/ | grep -v lo); do
        if [ -d "/sys/class/net/$interface" ] && [ "$(cat /sys/class/net/$interface/operstate)" = "up" ]; then
            echo -e "  ${CYAN}$interface:${NC}"
            
            # Ring buffers
            RX=$(ethtool -g $interface 2>/dev/null | grep "^RX:" | tail -1 | awk '{print $2}')
            TX=$(ethtool -g $interface 2>/dev/null | grep "^TX:" | tail -1 | awk '{print $2}')
            echo -e "    RX Ring: $RX, TX Ring: $TX"
            
            # Queue length
            txqueue=$(cat /sys/class/net/$interface/tx_queue_len)
            echo -e "    TX Queue: $txqueue"
        fi
    done
}

# Main execution
main() {
    backup_settings
    optimize_packet_transmission
    reduce_jitter
    optimize_tickrate
    prioritize_gaming_packets
    anti_packet_loss
    optimize_client_server_sync
    save_configuration
    test_connection
    show_status
    
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Anti Ghost Bullet đã được kích hoạt!${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}Hiệu quả:${NC}"
    echo -e "  ${GREEN}✓${NC} Giảm packet loss → ít ghost bullets"
    echo -e "  ${GREEN}✓${NC} Giảm jitter → hitreg chính xác hơn"
    echo -e "  ${GREEN}✓${NC} Ưu tiên gaming packets → đạn đăng ký nhanh hơn"
    echo -e "  ${GREEN}✓${NC} Client-server sync tốt hơn → gameplay nhất quán"
    
    echo -e "\n${CYAN}Lưu ý:${NC}"
    echo -e "  • Ghost bullets phụ thuộc cả vào server quality"
    echo -e "  • Khuyến nghị dùng Ethernet thay vì Wi-Fi"
    echo -e "  • Khởi động lại game để áp dụng hoàn toàn"
    echo -e "  • Test trong game: ${CYAN}ping, packet loss, var${NC}"
    echo ""
}

# Handle arguments
case "$1" in
    status)
        show_status
        ;;
    test)
        test_connection
        ;;
    *)
        main
        ;;
esac
