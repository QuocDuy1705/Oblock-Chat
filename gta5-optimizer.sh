#!/bin/bash

###############################################################################
# GTA5VN OPTIMIZER
# Tối ưu chuyên biệt cho GTA5 Online / GTA5VN
# Giảm lag, disconnect, session timeout
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
echo -e "${BLUE}║${GREEN}     GTA5VN OPTIMIZER - Tối ưu cho GTA5 Online         ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

# GTA5 specific ports
GTA5_UDP_PORTS="6672,61455,61456,61457,61458"
GTA5_TCP_PORTS="80,443,30211,30212,30213,30214,30215,30216,30217"

# Optimize network for GTA5
optimize_gta5_network() {
    echo -e "\n${YELLOW}[1/6] Tối ưu network cho GTA5...${NC}"
    
    # Tăng buffer cho P2P connections
    sysctl -w net.core.rmem_max=268435456
    sysctl -w net.core.wmem_max=268435456
    sysctl -w net.ipv4.udp_rmem_min=16384
    sysctl -w net.ipv4.udp_wmem_min=16384
    
    # GTA5 sử dụng P2P, cần nhiều connections
    sysctl -w net.ipv4.ip_local_port_range="1024 65535"
    sysctl -w net.netfilter.nf_conntrack_max=1048576 2>/dev/null || true
    
    # Giảm timeout để tránh session hang
    sysctl -w net.ipv4.tcp_keepalive_time=120
    sysctl -w net.ipv4.tcp_keepalive_intvl=10
    sysctl -w net.ipv4.tcp_keepalive_probes=6
    
    echo -e "${GREEN}✓ Network base đã được tối ưu${NC}"
}

# GTA5 port forwarding optimization
setup_gta5_ports() {
    echo -e "\n${YELLOW}[2/6] Setup GTA5 port optimization...${NC}"
    
    # Clear existing GTA5 rules
    iptables -t mangle -D OUTPUT -p udp -m multiport --dports $GTA5_UDP_PORTS -j MARK --set-mark 1 2>/dev/null
    iptables -t mangle -D OUTPUT -p tcp -m multiport --dports $GTA5_TCP_PORTS -j MARK --set-mark 1 2>/dev/null
    
    # Highest priority for GTA5 traffic
    iptables -t mangle -A OUTPUT -p udp -m multiport --dports $GTA5_UDP_PORTS -j MARK --set-mark 1
    iptables -t mangle -A OUTPUT -p tcp -m multiport --dports $GTA5_TCP_PORTS -j MARK --set-mark 1
    
    # DSCP marking for GTA5
    iptables -t mangle -A OUTPUT -p udp -m multiport --dports $GTA5_UDP_PORTS -j DSCP --set-dscp-class EF
    iptables -t mangle -A OUTPUT -p tcp -m multiport --dports $GTA5_TCP_PORTS -j DSCP --set-dscp-class EF
    
    # Incoming traffic
    iptables -t mangle -A PREROUTING -p udp -m multiport --sports $GTA5_UDP_PORTS -j DSCP --set-dscp-class EF
    
    echo -e "${GREEN}✓ GTA5 ports đã được ưu tiên${NC}"
}

# Optimize for P2P connections
optimize_p2p() {
    echo -e "\n${YELLOW}[3/6] Tối ưu P2P connections...${NC}"
    
    # GTA5 sử dụng P2P, cần handle nhiều connections
    sysctl -w net.core.somaxconn=4096
    sysctl -w net.ipv4.tcp_max_syn_backlog=8192
    
    # Tăng file descriptors
    ulimit -n 65536 2>/dev/null
    
    # Connection tracking
    sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=3600 2>/dev/null || true
    sysctl -w net.netfilter.nf_conntrack_udp_timeout=180 2>/dev/null || true
    
    echo -e "${GREEN}✓ P2P connections đã được tối ưu${NC}"
}

# Reduce session timeouts
reduce_timeouts() {
    echo -e "\n${YELLOW}[4/6] Giảm session timeouts...${NC}"
    
    # TCP settings để tránh disconnect
    sysctl -w net.ipv4.tcp_retries2=8
    sysctl -w net.ipv4.tcp_orphan_retries=3
    
    # Faster detection of dead connections
    sysctl -w net.ipv4.tcp_fin_timeout=20
    
    # NAT timeout (quan trọng cho GTA5)
    if [ -f /proc/sys/net/netfilter/nf_conntrack_tcp_timeout_time_wait ]; then
        echo 30 > /proc/sys/net/netfilter/nf_conntrack_tcp_timeout_time_wait
    fi
    
    echo -e "${GREEN}✓ Timeouts đã được tối ưu${NC}"
}

# Optimize for Social Club
optimize_social_club() {
    echo -e "\n${YELLOW}[5/6] Tối ưu Rockstar Social Club...${NC}"
    
    # Social Club ports
    SOCIAL_CLUB_PORTS="30211:30217"
    
    # Priority cho Social Club authentication
    iptables -t mangle -A OUTPUT -p tcp --dport 443 -m string --string "socialclub" --algo bm -j MARK --set-mark 1
    
    # DNS optimization cho Rockstar servers
    # Cloudflare usually faster for Rockstar
    echo -e "${CYAN}Khuyến nghị DNS: 1.1.1.1 (Cloudflare)${NC}"
    
    echo -e "${GREEN}✓ Social Club đã được tối ưu${NC}"
}

# Save configuration
save_gta5_config() {
    echo -e "\n${YELLOW}[6/6] Lưu cấu hình GTA5...${NC}"
    
    cat > /etc/sysctl.d/95-gta5-optimization.conf << 'EOF'
# GTA5VN Network Optimization
# Tối ưu cho GTA5 Online

# High buffer for P2P
net.core.rmem_max = 268435456
net.core.wmem_max = 268435456
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384

# P2P connections
net.ipv4.ip_local_port_range = 1024 65535
net.core.somaxconn = 4096
net.ipv4.tcp_max_syn_backlog = 8192

# Session keepalive
net.ipv4.tcp_keepalive_time = 120
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6

# Timeout settings
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_orphan_retries = 3
net.ipv4.tcp_fin_timeout = 20
EOF

    sysctl -p /etc/sysctl.d/95-gta5-optimization.conf
    
    # Save iptables
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/gta5-optimization.rules
    
    echo -e "${GREEN}✓ Cấu hình đã được lưu vĩnh viễn${NC}"
}

# Test GTA5 connectivity
test_gta5_connection() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Test kết nối GTA5:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}1. Rockstar Services:${NC}"
    
    # Test Rockstar servers
    ROCKSTAR_SERVERS=(
        "socialclub.rockstargames.com"
        "prod.cloud.rockstargames.com"
        "gameservices.rockstargames.com"
    )
    
    for server in "${ROCKSTAR_SERVERS[@]}"; do
        if ping -c 3 -W 2 $server &>/dev/null; then
            avg=$(ping -c 5 $server 2>/dev/null | tail -1 | awk -F '/' '{print $5}')
            echo -e "  ${GREEN}✓ $server: ${avg}ms${NC}"
        else
            echo -e "  ${RED}✗ $server: Unreachable${NC}"
        fi
    done
    
    echo -e "\n${YELLOW}2. Port Status:${NC}"
    echo -e "  UDP ports: $GTA5_UDP_PORTS"
    echo -e "  TCP ports: $GTA5_TCP_PORTS"
    
    echo -e "\n${YELLOW}3. NAT Type:${NC}"
    nat_type=$(sysctl -n net.ipv4.ip_forward)
    if [ "$nat_type" = "1" ]; then
        echo -e "  ${CYAN}IP Forward: Enabled (Open/Moderate NAT)${NC}"
    else
        echo -e "  ${YELLOW}IP Forward: Disabled (có thể là Strict NAT)${NC}"
        echo -e "  ${CYAN}Tip: Enable với: sysctl -w net.ipv4.ip_forward=1${NC}"
    fi
}

# Show GTA5 tips
show_gta5_tips() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}GTA5VN Tips & Tricks:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${CYAN}1. In-Game Settings:${NC}"
    echo -e "   • Pause Menu > Online > Options"
    echo -e "   • Matchmaking: Open/Friends Only (tùy chọn)"
    echo -e "   • Enable UPnP trên router nếu có thể"
    
    echo -e "\n${CYAN}2. NAT Type:${NC}"
    echo -e "   • Open NAT = Tốt nhất (connect dễ dàng)"
    echo -e "   • Moderate NAT = OK"
    echo -e "   • Strict NAT = Khó connect, dễ timeout"
    
    echo -e "\n${CYAN}3. Router Configuration:${NC}"
    echo -e "   • Enable UPnP/NAT-PMP"
    echo -e "   • Port forward: 6672, 61455-61458 UDP"
    echo -e "   • DMZ host: Set PC IP (advanced)"
    
    echo -e "\n${CYAN}4. Giảm Disconnect:${NC}"
    echo -e "   • Dùng Ethernet thay Wi-Fi"
    echo -e "   • Close background apps (Discord, Chrome)"
    echo -e "   • Firewall: Allow GTA5.exe & SocialClub"
    
    echo -e "\n${CYAN}5. DNS Optimization:${NC}"
    echo -e "   • Khuyến nghị: 1.1.1.1 (Cloudflare)"
    echo -e "   • Hoặc: 8.8.8.8 (Google)"
    echo -e "   • Chạy: sudo ./dns-optimizer.sh"
    
    echo -e "\n${CYAN}6. Tối ưu Steam/Epic/Rockstar Launcher:${NC}"
    echo -e "   • Settings > Downloads"
    echo -e "   • Limit download speed khi chơi"
    echo -e "   • Disable auto-update"
}

# Status check
show_status() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}GTA5 Optimization Status:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}Network Settings:${NC}"
    echo -e "  UDP buffer: $(sysctl -n net.ipv4.udp_rmem_min) bytes"
    echo -e "  Port range: $(sysctl -n net.ipv4.ip_local_port_range)"
    echo -e "  Keepalive: $(sysctl -n net.ipv4.tcp_keepalive_time)s"
    
    echo -e "\n${YELLOW}Firewall Rules:${NC}"
    gta_rules=$(iptables -t mangle -L OUTPUT -n | grep -E "6672|61455" | wc -l)
    if [ $gta_rules -gt 0 ]; then
        echo -e "  ${GREEN}✓ GTA5 rules active ($gta_rules rules)${NC}"
    else
        echo -e "  ${RED}✗ No GTA5 rules found${NC}"
    fi
    
    echo -e "\n${YELLOW}Connection Tracking:${NC}"
    if [ -f /proc/sys/net/netfilter/nf_conntrack_max ]; then
        echo -e "  Max connections: $(cat /proc/sys/net/netfilter/nf_conntrack_max)"
        echo -e "  Current: $(cat /proc/sys/net/netfilter/nf_conntrack_count 2>/dev/null || echo 'N/A')"
    fi
}

# Main execution
main() {
    optimize_gta5_network
    setup_gta5_ports
    optimize_p2p
    reduce_timeouts
    optimize_social_club
    save_gta5_config
    test_gta5_connection
    show_gta5_tips
    
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ GTA5VN Optimizer hoàn tất!${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}Kết quả:${NC}"
    echo -e "  ${GREEN}✓${NC} Network buffer tối ưu cho P2P"
    echo -e "  ${GREEN}✓${NC} GTA5 ports được ưu tiên cao nhất"
    echo -e "  ${GREEN}✓${NC} Session timeout giảm thiểu"
    echo -e "  ${GREEN}✓${NC} P2P connections tối ưu"
    
    echo -e "\n${CYAN}Lưu ý:${NC}"
    echo -e "  • Khởi động lại GTA5 để áp dụng"
    echo -e "  • Check NAT type trong game"
    echo -e "  • Enable UPnP trên router"
    echo -e "  • Kết hợp với: ${CYAN}sudo ./anti-ghostbullet.sh${NC}"
    echo ""
}

# Handle arguments
case "$1" in
    status)
        show_status
        ;;
    test)
        test_gta5_connection
        ;;
    tips)
        show_gta5_tips
        ;;
    *)
        main
        ;;
esac
