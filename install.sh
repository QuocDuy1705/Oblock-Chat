#!/bin/bash

###############################################################################
# INSTALLER - Network Optimization Toolkit
# Cài đặt và thiết lập tất cả các công cụ tối ưu mạng
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
echo -e "${BLUE}║${GREEN}     NETWORK OPTIMIZATION TOOLKIT - INSTALLER          ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        echo -e "${RED}Không thể detect OS${NC}"
        exit 1
    fi
    
    echo -e "\n${CYAN}OS: $OS $VER${NC}"
}

# Install dependencies
install_dependencies() {
    echo -e "\n${YELLOW}[1/5] Cài đặt dependencies...${NC}"
    
    case $OS in
        ubuntu|debian)
            apt-get update -qq
            apt-get install -y \
                iproute2 \
                ethtool \
                iptables \
                bc \
                dnsutils \
                curl \
                net-tools \
                iputils-ping \
                sysstat \
                tcpdump \
                iftop \
                nethogs
            ;;
        fedora|rhel|centos)
            dnf install -y \
                iproute \
                ethtool \
                iptables \
                bc \
                bind-utils \
                curl \
                net-tools \
                iputils \
                sysstat \
                tcpdump \
                iftop \
                nethogs
            ;;
        arch)
            pacman -Sy --noconfirm \
                iproute2 \
                ethtool \
                iptables \
                bc \
                bind-tools \
                curl \
                net-tools \
                iputils \
                sysstat \
                tcpdump \
                iftop \
                nethogs
            ;;
        *)
            echo -e "${YELLOW}OS không được hỗ trợ tự động, vui lòng cài các package cần thiết thủ công${NC}"
            ;;
    esac
    
    echo -e "${GREEN}✓ Dependencies đã được cài đặt${NC}"
}

# Copy scripts
install_scripts() {
    echo -e "\n${YELLOW}[2/5] Cài đặt scripts...${NC}"
    
    INSTALL_DIR="/usr/local/bin"
    SCRIPTS=(
        "network-optimizer.sh"
        "network-monitor.sh"
        "gaming-qos.sh"
        "reduce-bufferbloat.sh"
        "dns-optimizer.sh"
        "anti-ghostbullet.sh"
        "input-optimizer.sh"
        "low-latency-gaming.sh"
        "gta5-optimizer.sh"
    )
    
    for script in "${SCRIPTS[@]}"; do
        if [ -f "$script" ]; then
            cp "$script" "$INSTALL_DIR/"
            chmod +x "$INSTALL_DIR/$script"
            echo -e "${GREEN}✓ Installed: $script${NC}"
        else
            echo -e "${RED}✗ Not found: $script${NC}"
        fi
    done
    
    # Create convenient aliases
    cat > "$INSTALL_DIR/netopt" << 'EOF'
#!/bin/bash
# Network Optimization Launcher
echo "╔════════════════════════════════════════════╗"
echo "║  Network Optimization Toolkit              ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "=== Network Optimization ==="
echo "1. Network Optimizer   - Tối ưu toàn diện mạng"
echo "2. Network Monitor     - Giám sát mạng"
echo "3. Gaming QoS          - Ưu tiên gaming traffic"
echo "4. Reduce Bufferbloat  - Giảm bufferbloat"
echo "5. DNS Optimizer       - Tối ưu DNS"
echo ""
echo "=== System Optimization ==="
echo "6. Anti Ghost Bullet   - Xóa viên đạn trắng"
echo "7. Input Optimizer     - No input delay"
echo "8. Low Latency Gaming  - Tối ưu toàn hệ thống"
echo ""
echo "9. Apply ALL           - Áp dụng tất cả"
echo "0. Exit"
echo ""
read -p "Chọn [0-9]: " choice

case $choice in
    1) sudo network-optimizer.sh ;;
    2) network-monitor.sh ;;
    3) sudo gaming-qos.sh ;;
    4) sudo reduce-bufferbloat.sh ;;
    5) sudo dns-optimizer.sh ;;
    6) sudo anti-ghostbullet.sh ;;
    7) sudo input-optimizer.sh ;;
    8) sudo low-latency-gaming.sh ;;
    9) 
        echo "Đang áp dụng tất cả tối ưu..."
        sudo network-optimizer.sh
        sudo reduce-bufferbloat.sh
        sudo anti-ghostbullet.sh
        sudo input-optimizer.sh
        sudo low-latency-gaming.sh
        echo "✓ Hoàn tất! Khởi động lại để áp dụng hoàn toàn."
        ;;
    0) echo "Tạm biệt!" ;;
    *) echo "Invalid choice" ;;
esac
EOF
    chmod +x "$INSTALL_DIR/netopt"
    
    echo -e "${GREEN}✓ Scripts đã được cài đặt${NC}"
}

# Configure kernel modules
configure_kernel() {
    echo -e "\n${YELLOW}[3/5] Cấu hình kernel modules...${NC}"
    
    # Load BBR module
    modprobe tcp_bbr
    echo "tcp_bbr" >> /etc/modules-load.d/bbr.conf
    
    # Load fq_codel
    modprobe sch_fq_codel
    echo "sch_fq_codel" >> /etc/modules-load.d/qos.conf
    
    # Try to load CAKE if available
    modprobe sch_cake 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "sch_cake" >> /etc/modules-load.d/qos.conf
        echo -e "${GREEN}✓ CAKE module available${NC}"
    fi
    
    echo -e "${GREEN}✓ Kernel modules configured${NC}"
}

# Create systemd services
create_services() {
    echo -e "\n${YELLOW}[4/5] Tạo systemd services...${NC}"
    
    # Network Optimizer Service
    cat > /etc/systemd/system/network-optimizer.service << 'EOF'
[Unit]
Description=Network Optimizer for Gaming
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/network-optimizer.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    # Gaming QoS Service
    cat > /etc/systemd/system/gaming-qos.service << 'EOF'
[Unit]
Description=Gaming QoS
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/gaming-qos.sh 100 100
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    
    echo -e "${GREEN}✓ Systemd services created${NC}"
}

# Final configuration
final_setup() {
    echo -e "\n${YELLOW}[5/5] Hoàn tất cài đặt...${NC}"
    
    # Create config directory
    mkdir -p /etc/network-optimizer
    
    # Create config file
    cat > /etc/network-optimizer/config << 'EOF'
# Network Optimizer Configuration
UPLOAD_SPEED=100
DOWNLOAD_SPEED=100
AUTO_START=true
ENABLE_QOS=true
ENABLE_BUFFERBLOAT_REDUCTION=true
EOF
    
    echo -e "${GREEN}✓ Configuration created${NC}"
}

# Show completion message
show_completion() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Cài đặt hoàn tất!${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}Các lệnh có sẵn:${NC}"
    echo -e "  ${CYAN}netopt${NC}                    - Menu chính"
    echo -e "  ${CYAN}network-optimizer.sh${NC}      - Tối ưu hóa toàn diện"
    echo -e "  ${CYAN}network-monitor.sh${NC}        - Giám sát mạng"
    echo -e "  ${CYAN}gaming-qos.sh${NC}             - QoS cho gaming"
    echo -e "  ${CYAN}reduce-bufferbloat.sh${NC}     - Giảm bufferbloat"
    echo -e "  ${CYAN}dns-optimizer.sh${NC}          - Tối ưu DNS"
    echo -e "  ${CYAN}gta5-optimizer.sh${NC}         - Tối ưu GTA5VN"
    
    echo -e "\n${YELLOW}Bước tiếp theo:${NC}"
    echo -e "  1. Chạy: ${CYAN}sudo network-optimizer.sh${NC}"
    echo -e "  2. Chạy: ${CYAN}network-monitor.sh${NC} để kiểm tra"
    echo -e "  3. Khởi động lại để áp dụng hoàn toàn"
    
    echo -e "\n${YELLOW}Auto-start:${NC}"
    echo -e "  Enable: ${CYAN}sudo systemctl enable network-optimizer.service${NC}"
    echo -e "  Disable: ${CYAN}sudo systemctl disable network-optimizer.service${NC}"
    
    echo ""
}

# Main installation
main() {
    detect_os
    install_dependencies
    install_scripts
    configure_kernel
    create_services
    final_setup
    show_completion
}

main
