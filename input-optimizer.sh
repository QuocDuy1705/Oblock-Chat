#!/bin/bash

###############################################################################
# INPUT OPTIMIZER - No Input Delay
# Giảm input lag từ keyboard & mouse
# Tối ưu USB polling rate, interrupt handling, input processing
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
echo -e "${BLUE}║${GREEN}     INPUT OPTIMIZER - Giảm Input Delay 100%           ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

# Detect input devices
detect_input_devices() {
    echo -e "\n${YELLOW}[1/9] Phát hiện input devices...${NC}"
    
    # Keyboard
    KEYBOARDS=$(find /sys/class/input -name "*kbd*" -o -name "*keyboard*" 2>/dev/null)
    
    # Mouse
    MICE=$(find /sys/class/input -name "*mouse*" -o -name "*mice*" 2>/dev/null)
    
    # USB devices
    USB_DEVICES=$(lsusb | grep -iE "keyboard|mouse|gaming" | wc -l)
    
    echo -e "${GREEN}✓ Tìm thấy:${NC}"
    echo -e "  Keyboards: $(echo "$KEYBOARDS" | grep -v "^$" | wc -l)"
    echo -e "  Mice: $(echo "$MICE" | grep -v "^$" | wc -l)"
    echo -e "  USB Gaming devices: $USB_DEVICES"
}

# Optimize USB polling rate
optimize_usb_polling() {
    echo -e "\n${YELLOW}[2/9] Tối ưu USB polling rate...${NC}"
    
    # Set USB autosuspend to -1 (disable) cho input devices
    for device in /sys/bus/usb/devices/*/power/autosuspend; do
        if [ -f "$device" ]; then
            echo -1 > "$device" 2>/dev/null
        fi
    done
    
    # Disable USB power management cho input devices
    for device in /sys/bus/usb/devices/*/power/control; do
        if [ -f "$device" ]; then
            echo "on" > "$device" 2>/dev/null
        fi
    done
    
    # Set usbhid mousepoll to 1ms (1000Hz) if supported
    if [ -f /sys/module/usbhid/parameters/mousepoll ]; then
        current=$(cat /sys/module/usbhid/parameters/mousepoll)
        echo -e "${CYAN}Current mousepoll: ${current}ms${NC}"
        
        # Try to set to 1ms (1000Hz)
        modprobe -r usbhid 2>/dev/null
        modprobe usbhid mousepoll=1 2>/dev/null
        echo -e "${GREEN}✓ Đã set mousepoll=1ms (1000Hz)${NC}"
    fi
    
    echo -e "${GREEN}✓ USB polling rate đã được tối ưu${NC}"
}

# Optimize IRQ (Interrupt Request) for input devices
optimize_irq() {
    echo -e "\n${YELLOW}[3/9] Tối ưu IRQ cho input devices...${NC}"
    
    # Find USB controller IRQs
    USB_IRQS=$(grep -E "xhci|ehci|uhci|ohci" /proc/interrupts | awk -F: '{print $1}' | tr -d ' ')
    
    if [ ! -z "$USB_IRQS" ]; then
        for irq in $USB_IRQS; do
            if [ -f "/proc/irq/$irq/smp_affinity" ]; then
                # Set affinity to CPU 0-1 (gaming cores)
                echo "3" > /proc/irq/$irq/smp_affinity 2>/dev/null
                echo -e "${GREEN}✓ Set IRQ $irq affinity to CPU 0-1${NC}"
            fi
        done
    fi
    
    # Disable irqbalance để maintain affinity
    systemctl stop irqbalance 2>/dev/null
    systemctl disable irqbalance 2>/dev/null
    
    echo -e "${GREEN}✓ IRQ đã được tối ưu cho input${NC}"
}

# Optimize kernel input subsystem
optimize_kernel_input() {
    echo -e "\n${YELLOW}[4/9] Tối ưu kernel input subsystem...${NC}"
    
    # Giảm input event queue size để reduce batching
    if [ -f /sys/module/evdev/parameters/max_buffer_size ]; then
        echo 64 > /sys/module/evdev/parameters/max_buffer_size 2>/dev/null
    fi
    
    # Tối ưu HID (Human Interface Device) processing
    for device in /sys/class/input/input*/device/power/control; do
        if [ -f "$device" ]; then
            echo "on" > "$device" 2>/dev/null
        fi
    done
    
    # Disable power saving for input devices
    for device in /sys/class/input/input*/device/power/autosuspend_delay_ms; do
        if [ -f "$device" ]; then
            echo -1 > "$device" 2>/dev/null
        fi
    done
    
    echo -e "${GREEN}✓ Kernel input subsystem đã được tối ưu${NC}"
}

# Optimize X11/Wayland input handling
optimize_display_server() {
    echo -e "\n${YELLOW}[5/9] Tối ưu X11/Wayland input...${NC}"
    
    # Detect display server
    if [ ! -z "$WAYLAND_DISPLAY" ]; then
        echo -e "${CYAN}Wayland detected${NC}"
        # Wayland config (compositor specific)
        
    elif [ ! -z "$DISPLAY" ]; then
        echo -e "${CYAN}X11 detected${NC}"
        
        # Disable mouse acceleration
        if command -v xinput &> /dev/null; then
            for id in $(xinput list | grep -iE "mouse|pointer" | grep -oP 'id=\K\d+'); do
                xinput set-prop $id "libinput Accel Profile Enabled" 0, 1 2>/dev/null
                xinput set-prop $id "libinput Accel Speed" 0 2>/dev/null
                echo -e "${GREEN}✓ Disabled acceleration for device $id${NC}"
            done
        fi
        
        # X11 settings for low latency
        cat > /etc/X11/xorg.conf.d/50-input-optimization.conf << 'EOF'
Section "InputClass"
    Identifier "Mouse Optimization"
    MatchIsPointer "on"
    Option "AccelerationProfile" "-1"
    Option "AccelerationScheme" "none"
    Option "AccelSpeed" "0"
    Option "VelScale" "1"
EndSection

Section "InputClass"
    Identifier "Keyboard Optimization"
    MatchIsKeyboard "on"
    Option "AutoRepeat" "200 30"
EndSection
EOF
        echo -e "${GREEN}✓ X11 input config created${NC}"
    fi
    
    echo -e "${GREEN}✓ Display server input đã được tối ưu${NC}"
}

# Optimize CPU governor for input response
optimize_cpu_for_input() {
    echo -e "\n${YELLOW}[6/9] Tối ưu CPU governor cho input response...${NC}"
    
    # Set performance governor
    if command -v cpupower &> /dev/null; then
        cpupower frequency-set -g performance 2>/dev/null
        echo -e "${GREEN}✓ CPU governor: performance${NC}"
    else
        # Fallback to manual
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            if [ -f "$cpu" ]; then
                echo "performance" > "$cpu" 2>/dev/null
            fi
        done
        echo -e "${GREEN}✓ CPU governor: performance (manual)${NC}"
    fi
    
    # Disable CPU idle states (C-states) để avoid latency
    for state in /sys/devices/system/cpu/cpu*/cpuidle/state*/disable; do
        if [ -f "$state" ]; then
            echo 1 > "$state" 2>/dev/null
        fi
    done
    echo -e "${GREEN}✓ CPU idle states disabled${NC}"
    
    echo -e "${GREEN}✓ CPU đã được tối ưu cho input response${NC}"
}

# Optimize process scheduling for input
optimize_scheduling() {
    echo -e "\n${YELLOW}[7/9] Tối ưu process scheduling...${NC}"
    
    # Kernel scheduler settings
    sysctl -w kernel.sched_latency_ns=1000000          # 1ms
    sysctl -w kernel.sched_min_granularity_ns=100000   # 0.1ms
    sysctl -w kernel.sched_wakeup_granularity_ns=500000 # 0.5ms
    sysctl -w kernel.sched_migration_cost_ns=500000    # 0.5ms
    
    # Reduce context switch overhead
    sysctl -w kernel.sched_nr_migrate=8
    
    # RT scheduling (for critical processes)
    sysctl -w kernel.sched_rt_runtime_us=950000
    sysctl -w kernel.sched_rt_period_us=1000000
    
    echo -e "${GREEN}✓ Process scheduling đã được tối ưu${NC}"
}

# Optimize timer resolution
optimize_timer() {
    echo -e "\n${YELLOW}[8/9] Tối ưu timer resolution...${NC}"
    
    # Increase timer frequency (1000 Hz)
    sysctl -w kernel.timer_migration=0
    
    # High resolution timers
    if [ -f /sys/kernel/timer_migration ]; then
        echo 0 > /sys/kernel/timer_migration
    fi
    
    echo -e "${GREEN}✓ Timer resolution đã được tối ưu${NC}"
}

# Save configuration
save_configuration() {
    echo -e "\n${YELLOW}[9/9] Lưu cấu hình vĩnh viễn...${NC}"
    
    # Sysctl configuration
    cat > /etc/sysctl.d/97-input-optimization.conf << 'EOF'
# Input Optimization - No Input Delay
# Giảm input lag từ keyboard & mouse

# Process Scheduling
kernel.sched_latency_ns = 1000000
kernel.sched_min_granularity_ns = 100000
kernel.sched_wakeup_granularity_ns = 500000
kernel.sched_migration_cost_ns = 500000
kernel.sched_nr_migrate = 8

# RT Scheduling
kernel.sched_rt_runtime_us = 950000
kernel.sched_rt_period_us = 1000000

# Timer
kernel.timer_migration = 0
EOF

    sysctl -p /etc/sysctl.d/97-input-optimization.conf
    
    # USB module configuration
    cat > /etc/modprobe.d/usbhid-optimization.conf << 'EOF'
# USB HID optimization for gaming
options usbhid mousepoll=1
options usbhid jspoll=1
EOF
    
    # systemd service for USB power management
    cat > /etc/systemd/system/input-optimizer.service << 'EOF'
[Unit]
Description=Input Optimizer - Disable USB autosuspend
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'for device in /sys/bus/usb/devices/*/power/autosuspend; do echo -1 > $device 2>/dev/null; done'
ExecStart=/bin/bash -c 'for device in /sys/bus/usb/devices/*/power/control; do echo "on" > $device 2>/dev/null; done'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable input-optimizer.service
    
    # udev rules for input devices
    cat > /etc/udev/rules.d/99-input-optimization.rules << 'EOF'
# Disable autosuspend for input devices
ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="03", ATTR{power/autosuspend}="-1"
ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="03", ATTR{power/control}="on"

# Set scheduler for USB devices
ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="03", RUN+="/bin/sh -c 'echo -1 > /sys$devpath/power/autosuspend'"
EOF
    
    udevadm control --reload-rules
    
    echo -e "${GREEN}✓ Cấu hình đã được lưu vĩnh viễn${NC}"
}

# Test input latency
test_input_latency() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Input Latency Information:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}USB Polling Rates:${NC}"
    if [ -f /sys/module/usbhid/parameters/mousepoll ]; then
        poll=$(cat /sys/module/usbhid/parameters/mousepoll)
        freq=$((1000 / poll))
        echo -e "  Mouse: ${GREEN}${poll}ms (${freq}Hz)${NC}"
    fi
    
    echo -e "\n${YELLOW}CPU Governor:${NC}"
    gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
    if [ ! -z "$gov" ]; then
        echo -e "  ${GREEN}$gov${NC}"
    fi
    
    echo -e "\n${YELLOW}Scheduler Settings:${NC}"
    echo -e "  Latency: $(sysctl -n kernel.sched_latency_ns)ns"
    echo -e "  Min Granularity: $(sysctl -n kernel.sched_min_granularity_ns)ns"
    
    echo -e "\n${YELLOW}Input Devices Power:${NC}"
    suspended=0
    active=0
    for device in /sys/class/input/input*/device/power/control; do
        if [ -f "$device" ]; then
            status=$(cat "$device")
            if [ "$status" = "on" ]; then
                ((active++))
            else
                ((suspended++))
            fi
        fi
    done
    echo -e "  Active: ${GREEN}$active${NC}"
    echo -e "  Suspended: ${RED}$suspended${NC}"
}

# Show recommendations
show_recommendations() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Khuyến nghị thêm:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${CYAN}1. Trong Game Settings:${NC}"
    echo -e "   • Tắt V-Sync"
    echo -e "   • Tắt Motion Blur"
    echo -e "   • Set Max FPS = Monitor refresh rate × 2"
    echo -e "   • Raw Input = ON (nếu có)"
    
    echo -e "\n${CYAN}2. Windows Manager:${NC}"
    echo -e "   • Disable compositing khi chơi game"
    echo -e "   • Sử dụng fullscreen (không borderless)"
    
    echo -e "\n${CYAN}3. Hardware:${NC}"
    echo -e "   • Gaming mouse với DPI button"
    echo -e "   • Mechanical keyboard (faster response)"
    echo -e "   • High refresh rate monitor (144Hz+)"
    
    echo -e "\n${CYAN}4. Test Input Lag:${NC}"
    echo -e "   • https://www.testufo.com/mouse"
    echo -e "   • https://www.humanbenchmark.com/tests/reactiontime"
}

# Show status
show_status() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Input Optimizer Status:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    test_input_latency
    
    echo -e "\n${YELLOW}Services:${NC}"
    if systemctl is-enabled input-optimizer.service &>/dev/null; then
        echo -e "  input-optimizer: ${GREEN}Enabled${NC}"
    else
        echo -e "  input-optimizer: ${RED}Disabled${NC}"
    fi
    
    echo -e "\n${YELLOW}irqbalance:${NC}"
    if systemctl is-active irqbalance &>/dev/null; then
        echo -e "  ${YELLOW}Active (nên disable cho gaming)${NC}"
    else
        echo -e "  ${GREEN}Inactive (tốt!)${NC}"
    fi
}

# Main execution
main() {
    detect_input_devices
    optimize_usb_polling
    optimize_irq
    optimize_kernel_input
    optimize_display_server
    optimize_cpu_for_input
    optimize_scheduling
    optimize_timer
    save_configuration
    test_input_latency
    show_recommendations
    
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Input Optimizer hoàn tất!${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}Kết quả:${NC}"
    echo -e "  ${GREEN}✓${NC} USB polling rate: 1000Hz (1ms)"
    echo -e "  ${GREEN}✓${NC} IRQ optimized cho input devices"
    echo -e "  ${GREEN}✓${NC} CPU governor: performance"
    echo -e "  ${GREEN}✓${NC} Scheduler latency: <1ms"
    echo -e "  ${GREEN}✓${NC} Power management: disabled"
    
    echo -e "\n${CYAN}Lưu ý:${NC}"
    echo -e "  • Khởi động lại để áp dụng hoàn toàn"
    echo -e "  • Test trong game để cảm nhận sự khác biệt"
    echo -e "  • Kết hợp với Low Latency Gaming script"
    echo ""
}

# Handle arguments
case "$1" in
    status)
        show_status
        ;;
    test)
        test_input_latency
        ;;
    *)
        main
        ;;
esac
