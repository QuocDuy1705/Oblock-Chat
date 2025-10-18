#!/bin/bash

###############################################################################
# NETWORK OPTIMIZER FOR GAMING
# Tối ưu hóa mạng để giảm delay, ping và cải thiện hiệu suất gaming
###############################################################################

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Vui lòng chạy script với quyền root (sudo)${NC}"
    exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}    NETWORK OPTIMIZER - Tối ưu hóa mạng cho Gaming${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

# Backup cấu hình hiện tại
backup_current_settings() {
    echo -e "\n${YELLOW}[1/10] Backup cấu hình hiện tại...${NC}"
    BACKUP_DIR="/etc/network-optimizer-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup sysctl
    sysctl -a > "$BACKUP_DIR/sysctl_backup.conf" 2>/dev/null
    
    # Backup iptables
    iptables-save > "$BACKUP_DIR/iptables_backup.rules" 2>/dev/null
    
    echo -e "${GREEN}✓ Đã backup vào: $BACKUP_DIR${NC}"
}

# Tối ưu hóa TCP/IP Stack
optimize_tcp_ip() {
    echo -e "\n${YELLOW}[2/10] Tối ưu hóa TCP/IP Stack...${NC}"
    
    # Tăng buffer size cho network
    sysctl -w net.core.rmem_max=134217728
    sysctl -w net.core.wmem_max=134217728
    sysctl -w net.core.rmem_default=16777216
    sysctl -w net.core.wmem_default=16777216
    sysctl -w net.ipv4.tcp_rmem="4096 87380 67108864"
    sysctl -w net.ipv4.tcp_wmem="4096 65536 67108864"
    
    # Tối ưu hóa TCP
    sysctl -w net.ipv4.tcp_fastopen=3
    sysctl -w net.ipv4.tcp_low_latency=1
    sysctl -w net.ipv4.tcp_sack=1
    sysctl -w net.ipv4.tcp_timestamps=1
    sysctl -w net.ipv4.tcp_window_scaling=1
    
    # Giảm latency
    sysctl -w net.ipv4.tcp_fin_timeout=15
    sysctl -w net.ipv4.tcp_keepalive_time=300
    sysctl -w net.ipv4.tcp_keepalive_probes=5
    sysctl -w net.ipv4.tcp_keepalive_intvl=15
    
    # Cải thiện throughput
    sysctl -w net.core.netdev_max_backlog=5000
    sysctl -w net.ipv4.tcp_max_syn_backlog=8192
    sysctl -w net.core.somaxconn=1024
    
    echo -e "${GREEN}✓ TCP/IP Stack đã được tối ưu hóa${NC}"
}

# Giảm Bufferbloat
reduce_bufferbloat() {
    echo -e "\n${YELLOW}[3/10] Giảm Bufferbloat...${NC}"
    
    # Sử dụng FQ_CODEL để giảm bufferbloat
    sysctl -w net.core.default_qdisc=fq_codel
    
    # Tối ưu hóa queue discipline cho tất cả interfaces
    for interface in $(ls /sys/class/net/ | grep -v lo); do
        if [ -d "/sys/class/net/$interface" ]; then
            tc qdisc del dev $interface root 2>/dev/null
            tc qdisc add dev $interface root fq_codel
            echo -e "${GREEN}✓ Đã cấu hình fq_codel cho $interface${NC}"
        fi
    done
    
    # Giảm txqueuelen để tránh bufferbloat
    for interface in $(ls /sys/class/net/ | grep -v lo); do
        if [ -d "/sys/class/net/$interface" ]; then
            ip link set $interface txqueuelen 1000
        fi
    done
    
    echo -e "${GREEN}✓ Bufferbloat đã được giảm thiểu${NC}"
}

# Ưu tiên Gaming Traffic (QoS)
setup_gaming_qos() {
    echo -e "\n${YELLOW}[4/10] Thiết lập QoS cho Gaming...${NC}"
    
    # Gaming ports phổ biến
    GAMING_PORTS="27015,27016,3074,3075,3478,3479,3658,5223,6112,9308,27000:27050,30000:30009"
    
    # Ưu tiên DSCP marking cho gaming traffic
    iptables -t mangle -F
    iptables -t mangle -A OUTPUT -p tcp -m multiport --dports $GAMING_PORTS -j DSCP --set-dscp-class EF
    iptables -t mangle -A OUTPUT -p udp -m multiport --dports $GAMING_PORTS -j DSCP --set-dscp-class EF
    
    # Ưu tiên DNS queries
    iptables -t mangle -A OUTPUT -p udp --dport 53 -j DSCP --set-dscp-class CS6
    iptables -t mangle -A OUTPUT -p tcp --dport 53 -j DSCP --set-dscp-class CS6
    
    echo -e "${GREEN}✓ QoS đã được cấu hình cho gaming traffic${NC}"
}

# Tối ưu hóa Network Interface
optimize_network_interface() {
    echo -e "\n${YELLOW}[5/10] Tối ưu hóa Network Interface...${NC}"
    
    for interface in $(ls /sys/class/net/ | grep -v lo); do
        if [ -d "/sys/class/net/$interface" ]; then
            # Tắt các tính năng không cần thiết
            ethtool -K $interface tso off 2>/dev/null
            ethtool -K $interface gso off 2>/dev/null
            ethtool -K $interface gro off 2>/dev/null
            ethtool -K $interface lro off 2>/dev/null
            
            # Tối ưu hóa interrupt coalescing để giảm latency
            ethtool -C $interface rx-usecs 0 2>/dev/null
            ethtool -C $interface tx-usecs 0 2>/dev/null
            
            echo -e "${GREEN}✓ Đã tối ưu hóa $interface${NC}"
        fi
    done
}

# Tối ưu hóa UDP
optimize_udp() {
    echo -e "\n${YELLOW}[6/10] Tối ưu hóa UDP (quan trọng cho gaming)...${NC}"
    
    sysctl -w net.ipv4.udp_rmem_min=8192
    sysctl -w net.ipv4.udp_wmem_min=8192
    sysctl -w net.core.optmem_max=65536
    
    echo -e "${GREEN}✓ UDP đã được tối ưu hóa${NC}"
}

# Giảm Latency & Ping
reduce_latency() {
    echo -e "\n${YELLOW}[7/10] Giảm Latency & Ping...${NC}"
    
    # Disable IPv6 nếu không dùng (giảm overhead)
    sysctl -w net.ipv6.conf.all.disable_ipv6=0
    sysctl -w net.ipv6.conf.default.disable_ipv6=0
    
    # Tối ưu hóa routing cache
    sysctl -w net.ipv4.route.flush=1
    
    # Giảm time wait
    sysctl -w net.ipv4.tcp_tw_reuse=1
    sysctl -w net.ipv4.tcp_tw_recycle=0
    
    # Tối ưu hóa congestion control
    sysctl -w net.ipv4.tcp_congestion_control=bbr
    sysctl -w net.core.default_qdisc=fq
    
    # Tăng tốc độ xử lý packet
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0
    
    echo -e "${GREEN}✓ Latency đã được tối ưu hóa${NC}"
}

# Tối ưu hóa DNS
optimize_dns() {
    echo -e "\n${YELLOW}[8/10] Tối ưu hóa DNS Resolution...${NC}"
    
    # Tăng cache size cho DNS
    sysctl -w net.ipv4.neigh.default.gc_thresh1=1024
    sysctl -w net.ipv4.neigh.default.gc_thresh2=2048
    sysctl -w net.ipv4.neigh.default.gc_thresh3=4096
    
    echo -e "${GREEN}✓ DNS đã được tối ưu hóa${NC}"
}

# Tối ưu hóa Connection Stability
improve_connection_stability() {
    echo -e "\n${YELLOW}[9/10] Cải thiện độ ổn định kết nối...${NC}"
    
    # Tăng số lượng connection tracking
    sysctl -w net.netfilter.nf_conntrack_max=524288 2>/dev/null || true
    
    # Giảm timeout cho connection tracking
    sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=1800 2>/dev/null || true
    
    # Tối ưu hóa ARP cache
    sysctl -w net.ipv4.neigh.default.gc_stale_time=120
    
    # Cho phép reuse TIME_WAIT sockets
    sysctl -w net.ipv4.tcp_tw_reuse=1
    
    echo -e "${GREEN}✓ Độ ổn định kết nối đã được cải thiện${NC}"
}

# Lưu cấu hình vĩnh viễn
save_settings() {
    echo -e "\n${YELLOW}[10/10] Lưu cấu hình vĩnh viễn...${NC}"
    
    cat > /etc/sysctl.d/99-gaming-network-optimization.conf << 'EOF'
# Gaming Network Optimization
# Tối ưu hóa mạng cho gaming - Giảm delay, ping, latency

# TCP/IP Optimization
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.rmem_default = 16777216
net.core.wmem_default = 16777216
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# Low Latency TCP
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1

# Reduce Latency
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# Network Performance
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_syn_backlog = 8192
net.core.somaxconn = 1024

# Bufferbloat Reduction
net.core.default_qdisc = fq_codel

# UDP Optimization
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.core.optmem_max = 65536

# BBR Congestion Control
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_slow_start_after_idle = 0

# Connection Stability
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.neigh.default.gc_stale_time = 120
net.ipv4.neigh.default.gc_thresh1 = 1024
net.ipv4.neigh.default.gc_thresh2 = 2048
net.ipv4.neigh.default.gc_thresh3 = 4096
EOF

    sysctl -p /etc/sysctl.d/99-gaming-network-optimization.conf
    
    echo -e "${GREEN}✓ Cấu hình đã được lưu vĩnh viễn${NC}"
}

# Test kết quả
test_network() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Kiểm tra cấu hình mạng hiện tại:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}TCP Congestion Control:${NC}"
    sysctl net.ipv4.tcp_congestion_control
    
    echo -e "\n${YELLOW}Queue Discipline:${NC}"
    sysctl net.core.default_qdisc
    
    echo -e "\n${YELLOW}Network Interfaces:${NC}"
    for interface in $(ls /sys/class/net/ | grep -v lo); do
        if [ -d "/sys/class/net/$interface" ]; then
            echo -e "${GREEN}$interface:${NC}"
            tc qdisc show dev $interface | head -1
        fi
    done
    
    echo -e "\n${YELLOW}Kiểm tra ping đến 8.8.8.8 (Google DNS):${NC}"
    ping -c 5 8.8.8.8 2>/dev/null | tail -2
}

# Main execution
main() {
    backup_current_settings
    optimize_tcp_ip
    reduce_bufferbloat
    setup_gaming_qos
    optimize_network_interface
    optimize_udp
    reduce_latency
    optimize_dns
    improve_connection_stability
    save_settings
    test_network
    
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Hoàn tất tối ưu hóa mạng cho gaming!${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Lưu ý:${NC}"
    echo -e "  • Cấu hình đã được lưu vĩnh viễn"
    echo -e "  • Khởi động lại máy để áp dụng hoàn toàn"
    echo -e "  • Backup được lưu tại: $BACKUP_DIR"
    echo -e "  • Chạy ./network-monitor.sh để giám sát hiệu suất"
    echo ""
}

# Chạy script
main
