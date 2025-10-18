#!/bin/bash

###############################################################################
# REDUCE BUFFERBLOAT SCRIPT
# Chuyên biệt giảm bufferbloat để gameplay mượt mà hơn
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
echo -e "${GREEN}    REDUCE BUFFERBLOAT - Giảm Độ Trễ Mạng${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

# Test bufferbloat trước khi áp dụng
test_bufferbloat_before() {
    echo -e "\n${YELLOW}[1/4] Test bufferbloat hiện tại...${NC}"
    echo -e "${CYAN}Đang ping 8.8.8.8...${NC}"
    
    # Ping baseline
    baseline=$(ping -c 10 -i 0.2 8.8.8.8 2>/dev/null | tail -1 | awk -F '/' '{print $5}')
    echo -e "${CYAN}Ping trung bình (không tải): ${baseline} ms${NC}"
    
    # Ping under load
    echo -e "${CYAN}Đang tạo tải mạng để test...${NC}"
    timeout 15 curl -o /dev/null http://speedtest.tele2.net/10MB.zip &>/dev/null &
    LOAD_PID=$!
    sleep 2
    
    under_load=$(ping -c 10 -i 0.2 8.8.8.8 2>/dev/null | tail -1 | awk -F '/' '{print $5}')
    echo -e "${CYAN}Ping trung bình (dưới tải): ${under_load} ms${NC}"
    
    kill $LOAD_PID 2>/dev/null
    wait $LOAD_PID 2>/dev/null
    
    # Tính toán mức độ bufferbloat
    if [ ! -z "$baseline" ] && [ ! -z "$under_load" ]; then
        increase=$(echo "scale=2; ($under_load - $baseline) / $baseline * 100" | bc -l)
        echo -e "\n${YELLOW}Tăng ping dưới tải: ${increase}%${NC}"
        
        if (( $(echo "$increase < 10" | bc -l) )); then
            echo -e "${GREEN}✓ Bufferbloat: THẤP (Rất tốt!)${NC}"
        elif (( $(echo "$increase < 30" | bc -l) )); then
            echo -e "${CYAN}○ Bufferbloat: TRUNG BÌNH${NC}"
        else
            echo -e "${RED}✗ Bufferbloat: CAO (Cần tối ưu!)${NC}"
        fi
    fi
}

# Apply advanced queue discipline
apply_cake_qdisc() {
    echo -e "\n${YELLOW}[2/4] Áp dụng CAKE Queue Discipline...${NC}"
    
    # Kiểm tra CAKE có available không
    if ! modinfo sch_cake &>/dev/null; then
        echo -e "${YELLOW}CAKE không khả dụng, dùng fq_codel thay thế${NC}"
        apply_fq_codel
        return
    fi
    
    for interface in $(ls /sys/class/net/ | grep -v lo); do
        if [ -d "/sys/class/net/$interface" ] && [ "$(cat /sys/class/net/$interface/operstate)" = "up" ]; then
            echo -e "${CYAN}Cấu hình CAKE cho $interface...${NC}"
            
            # Xóa qdisc cũ
            tc qdisc del dev $interface root 2>/dev/null
            
            # Thêm CAKE với các tùy chọn gaming-optimized
            # bandwidth: set theo connection speed
            # besteffort: priority mode
            # triple-isolate: isolate flows
            tc qdisc add dev $interface root cake bandwidth 100Mbit besteffort triple-isolate nonat nowash no-ack-filter
            
            echo -e "${GREEN}✓ CAKE đã được áp dụng cho $interface${NC}"
        fi
    done
}

# Apply fq_codel (fallback)
apply_fq_codel() {
    echo -e "\n${YELLOW}[2/4] Áp dụng fq_codel Queue Discipline...${NC}"
    
    for interface in $(ls /sys/class/net/ | grep -v lo); do
        if [ -d "/sys/class/net/$interface" ] && [ "$(cat /sys/class/net/$interface/operstate)" = "up" ]; then
            echo -e "${CYAN}Cấu hình fq_codel cho $interface...${NC}"
            
            # Xóa qdisc cũ
            tc qdisc del dev $interface root 2>/dev/null
            
            # Thêm fq_codel với các tùy chọn tối ưu
            # quantum: 300 bytes (tốt cho gaming packets)
            # limit: số packet tối đa trong queue
            # target: target delay (5ms)
            # interval: interval (100ms)
            tc qdisc add dev $interface root fq_codel quantum 300 limit 1000 target 5ms interval 100ms noecn
            
            echo -e "${GREEN}✓ fq_codel đã được áp dụng cho $interface${NC}"
        fi
    done
}

# Optimize network buffers
optimize_buffers() {
    echo -e "\n${YELLOW}[3/4] Tối ưu hóa network buffers...${NC}"
    
    # Giảm txqueuelen để tránh bufferbloat
    for interface in $(ls /sys/class/net/ | grep -v lo); do
        if [ -d "/sys/class/net/$interface" ] && [ "$(cat /sys/class/net/$interface/operstate)" = "up" ]; then
            # Set txqueuelen (default thường 1000, giảm xuống cho low latency)
            ip link set $interface txqueuelen 500
            echo -e "${GREEN}✓ Đã set txqueuelen=500 cho $interface${NC}"
        fi
    done
    
    # Tối ưu hóa sysctl parameters
    sysctl -w net.core.netdev_max_backlog=2000
    sysctl -w net.core.netdev_budget=300
    sysctl -w net.core.netdev_budget_usecs=2000
    
    echo -e "${GREEN}✓ Network buffers đã được tối ưu${NC}"
}

# Disable offloading features that cause bufferbloat
disable_offloading() {
    echo -e "\n${YELLOW}[4/4] Tắt hardware offloading features...${NC}"
    
    for interface in $(ls /sys/class/net/ | grep -v lo); do
        if [ -d "/sys/class/net/$interface" ] && [ "$(cat /sys/class/net/$interface/operstate)" = "up" ]; then
            echo -e "${CYAN}Cấu hình $interface...${NC}"
            
            # Tắt các feature có thể gây bufferbloat
            ethtool -K $interface tso off 2>/dev/null && echo "  ✓ TSO off"
            ethtool -K $interface gso off 2>/dev/null && echo "  ✓ GSO off"
            ethtool -K $interface gro off 2>/dev/null && echo "  ✓ GRO off"
            ethtool -K $interface lro off 2>/dev/null && echo "  ✓ LRO off"
            
            # Giảm interrupt coalescing
            ethtool -C $interface rx-usecs 0 2>/dev/null && echo "  ✓ RX coalescing off"
            ethtool -C $interface tx-usecs 0 2>/dev/null && echo "  ✓ TX coalescing off"
        fi
    done
    
    echo -e "${GREEN}✓ Hardware offloading đã được tối ưu${NC}"
}

# Save configuration
save_configuration() {
    echo -e "\n${YELLOW}Lưu cấu hình...${NC}"
    
    # Create systemd service to apply on boot
    cat > /etc/systemd/system/reduce-bufferbloat.service << 'EOF'
[Unit]
Description=Reduce Bufferbloat - Apply Queue Discipline
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/reduce-bufferbloat-apply.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    # Create apply script
    cat > /usr/local/bin/reduce-bufferbloat-apply.sh << 'EOF'
#!/bin/bash
# Auto-generated script to apply bufferbloat reduction

# Apply fq_codel to all interfaces
for interface in $(ls /sys/class/net/ | grep -v lo); do
    if [ -d "/sys/class/net/$interface" ] && [ "$(cat /sys/class/net/$interface/operstate)" = "up" ]; then
        tc qdisc del dev $interface root 2>/dev/null
        tc qdisc add dev $interface root fq_codel quantum 300 limit 1000 target 5ms interval 100ms noecn
        ip link set $interface txqueuelen 500
        
        # Disable offloading
        ethtool -K $interface tso off 2>/dev/null
        ethtool -K $interface gso off 2>/dev/null
        ethtool -K $interface gro off 2>/dev/null
        ethtool -K $interface lro off 2>/dev/null
        ethtool -C $interface rx-usecs 0 2>/dev/null
        ethtool -C $interface tx-usecs 0 2>/dev/null
    fi
done

# Sysctl settings
sysctl -w net.core.netdev_max_backlog=2000
sysctl -w net.core.netdev_budget=300
sysctl -w net.core.netdev_budget_usecs=2000
sysctl -w net.core.default_qdisc=fq_codel
EOF

    chmod +x /usr/local/bin/reduce-bufferbloat-apply.sh
    
    # Enable service
    systemctl daemon-reload
    systemctl enable reduce-bufferbloat.service
    
    echo -e "${GREEN}✓ Cấu hình đã được lưu và sẽ tự động áp dụng khi khởi động${NC}"
}

# Show current status
show_status() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Trạng thái hiện tại:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    for interface in $(ls /sys/class/net/ | grep -v lo); do
        if [ -d "/sys/class/net/$interface" ] && [ "$(cat /sys/class/net/$interface/operstate)" = "up" ]; then
            echo -e "\n${YELLOW}Interface: $interface${NC}"
            
            # Queue discipline
            qdisc=$(tc qdisc show dev $interface | head -1)
            echo -e "${CYAN}Queue Discipline:${NC} $qdisc"
            
            # txqueuelen
            txqueue=$(cat /sys/class/net/$interface/tx_queue_len)
            echo -e "${CYAN}TX Queue Length:${NC} $txqueue"
        fi
    done
    
    echo -e "\n${CYAN}Default QDisc:${NC} $(sysctl -n net.core.default_qdisc)"
}

# Main execution
main() {
    test_bufferbloat_before
    
    # Try CAKE first, fallback to fq_codel
    if modinfo sch_cake &>/dev/null; then
        apply_cake_qdisc
    else
        apply_fq_codel
    fi
    
    optimize_buffers
    disable_offloading
    save_configuration
    show_status
    
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Hoàn tất giảm bufferbloat!${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Khuyến nghị:${NC}"
    echo -e "  • Test lại bufferbloat: ping 8.8.8.8 khi đang download"
    echo -e "  • Chơi game và cảm nhận sự khác biệt"
    echo -e "  • Cấu hình sẽ tự động áp dụng khi khởi động lại"
    echo ""
}

case "$1" in
    status)
        show_status
        ;;
    test)
        test_bufferbloat_before
        ;;
    *)
        main
        ;;
esac
