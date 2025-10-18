#!/bin/bash

###############################################################################
# LOW LATENCY GAMING - System Optimizer
# Giảm tối đa độ trễ của máy tính
# Tối ưu CPU, RAM, GPU, Storage, Power cho gaming
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
echo -e "${BLUE}║${GREEN}   LOW LATENCY GAMING - Tối ưu Toàn Bộ Hệ Thống       ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

# System detection
detect_system() {
    echo -e "\n${YELLOW}[1/12] Phát hiện cấu hình hệ thống...${NC}"
    
    CPU_CORES=$(nproc)
    TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
    SWAP_SIZE=$(free -g | awk '/^Swap:/{print $2}')
    
    # GPU detection
    if lspci | grep -i nvidia &>/dev/null; then
        GPU="NVIDIA"
    elif lspci | grep -i amd | grep -i vga &>/dev/null; then
        GPU="AMD"
    elif lspci | grep -i intel | grep -i vga &>/dev/null; then
        GPU="Intel"
    else
        GPU="Unknown"
    fi
    
    echo -e "${GREEN}✓ System Info:${NC}"
    echo -e "  CPU Cores: $CPU_CORES"
    echo -e "  RAM: ${TOTAL_RAM}GB"
    echo -e "  Swap: ${SWAP_SIZE}GB"
    echo -e "  GPU: $GPU"
}

# CPU Optimization
optimize_cpu() {
    echo -e "\n${YELLOW}[2/12] Tối ưu CPU...${NC}"
    
    # Performance governor
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [ -f "$cpu" ]; then
            echo "performance" > "$cpu" 2>/dev/null
        fi
    done
    echo -e "${GREEN}✓ CPU Governor: Performance${NC}"
    
    # Disable CPU frequency scaling
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
        if [ -f "$cpu" ]; then
            max_freq=$(cat "$cpu")
            min_file="${cpu/max/min}"
            echo "$max_freq" > "$min_file" 2>/dev/null
        fi
    done
    echo -e "${GREEN}✓ CPU Frequency: Max locked${NC}"
    
    # Disable C-states (CPU idle states)
    for state in /sys/devices/system/cpu/cpu*/cpuidle/state*/disable; do
        if [ -f "$state" ]; then
            echo 1 > "$state" 2>/dev/null
        fi
    done
    echo -e "${GREEN}✓ C-states: Disabled${NC}"
    
    # Disable Turbo Boost throttling
    if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
        echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null
        echo -e "${GREEN}✓ Intel Turbo: Enabled${NC}"
    fi
    
    if [ -f /sys/devices/system/cpu/cpufreq/boost ]; then
        echo 1 > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null
        echo -e "${GREEN}✓ AMD Boost: Enabled${NC}"
    fi
    
    # CPU affinity for gaming (isolate cores)
    sysctl -w kernel.sched_autogroup_enabled=0
    
    echo -e "${GREEN}✓ CPU đã được tối ưu${NC}"
}

# RAM/Memory Optimization
optimize_memory() {
    echo -e "\n${YELLOW}[3/12] Tối ưu RAM & Memory...${NC}"
    
    # Swappiness (giảm swap usage)
    sysctl -w vm.swappiness=10
    
    # Cache pressure (ưu tiên game trong RAM)
    sysctl -w vm.vfs_cache_pressure=50
    
    # Dirty ratio (giảm flush delay)
    sysctl -w vm.dirty_ratio=10
    sysctl -w vm.dirty_background_ratio=5
    
    # Overcommit (cho phép allocate nhiều RAM)
    sysctl -w vm.overcommit_memory=1
    sysctl -w vm.overcommit_ratio=50
    
    # THP (Transparent Huge Pages)
    if [ -f /sys/kernel/mm/transparent_hugepage/enabled ]; then
        echo always > /sys/kernel/mm/transparent_hugepage/enabled
        echo -e "${GREEN}✓ THP: Enabled${NC}"
    fi
    
    # Compact memory
    echo 1 > /proc/sys/vm/compact_memory 2>/dev/null
    
    # Zone reclaim
    sysctl -w vm.zone_reclaim_mode=0
    
    echo -e "${GREEN}✓ Memory đã được tối ưu${NC}"
}

# I/O Scheduler Optimization
optimize_io() {
    echo -e "\n${YELLOW}[4/12] Tối ưu I/O Scheduler...${NC}"
    
    for disk in /sys/block/sd*/queue/scheduler; do
        if [ -f "$disk" ]; then
            # Detect if SSD or HDD
            device=$(echo $disk | cut -d'/' -f4)
            rotational=$(cat /sys/block/$device/queue/rotational)
            
            if [ "$rotational" -eq 0 ]; then
                # SSD - use none/noop
                echo none > "$disk" 2>/dev/null || echo noop > "$disk" 2>/dev/null
                echo -e "${GREEN}✓ $device (SSD): none/noop${NC}"
            else
                # HDD - use mq-deadline
                echo mq-deadline > "$disk" 2>/dev/null || echo deadline > "$disk" 2>/dev/null
                echo -e "${GREEN}✓ $device (HDD): deadline${NC}"
            fi
        fi
    done
    
    # NVMe optimization
    for disk in /sys/block/nvme*/queue/scheduler; do
        if [ -f "$disk" ]; then
            echo none > "$disk" 2>/dev/null
            device=$(echo $disk | cut -d'/' -f4)
            echo -e "${GREEN}✓ $device (NVMe): none${NC}"
        fi
    done
    
    # I/O queue depth
    for disk in /sys/block/sd*/queue/nr_requests; do
        if [ -f "$disk" ]; then
            echo 512 > "$disk" 2>/dev/null
        fi
    done
    
    # Read-ahead (KB)
    for disk in /sys/block/sd*/queue/read_ahead_kb; do
        if [ -f "$disk" ]; then
            echo 512 > "$disk" 2>/dev/null
        fi
    done
    
    echo -e "${GREEN}✓ I/O Scheduler đã được tối ưu${NC}"
}

# GPU Optimization
optimize_gpu() {
    echo -e "\n${YELLOW}[5/12] Tối ưu GPU...${NC}"
    
    if [ "$GPU" = "NVIDIA" ]; then
        if command -v nvidia-smi &> /dev/null; then
            # Max performance mode
            nvidia-smi -pm 1 2>/dev/null
            
            # Max power limit
            nvidia-smi -pl $(nvidia-smi -q -d POWER | grep "Max Power Limit" | awk '{print $5}' | head -1) 2>/dev/null
            
            # Max clock
            nvidia-smi -lgc $(nvidia-smi -q -d SUPPORTED_CLOCKS | grep "Memory" | awk '{print $3}' | sort -n | tail -1) 2>/dev/null
            
            echo -e "${GREEN}✓ NVIDIA GPU: Max Performance${NC}"
        fi
        
    elif [ "$GPU" = "AMD" ]; then
        # AMD GPU settings
        if [ -d /sys/class/drm/card0/device ]; then
            echo high > /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null
            echo -e "${GREEN}✓ AMD GPU: High Performance${NC}"
        fi
        
    elif [ "$GPU" = "Intel" ]; then
        # Intel GPU settings
        echo -e "${CYAN}Intel GPU: Using default settings${NC}"
    fi
    
    echo -e "${GREEN}✓ GPU đã được tối ưu${NC}"
}

# Process Priority Optimization
optimize_process_priority() {
    echo -e "\n${YELLOW}[6/12] Tối ưu Process Priority...${NC}"
    
    # Scheduler settings
    sysctl -w kernel.sched_latency_ns=1000000
    sysctl -w kernel.sched_min_granularity_ns=100000
    sysctl -w kernel.sched_wakeup_granularity_ns=500000
    sysctl -w kernel.sched_migration_cost_ns=500000
    
    # RT (Real-Time) settings
    sysctl -w kernel.sched_rt_runtime_us=950000
    sysctl -w kernel.sched_rt_period_us=1000000
    
    # Preemption
    if [ -f /sys/kernel/debug/sched_features ]; then
        echo NO_GENTLE_FAIR_SLEEPERS > /sys/kernel/debug/sched_features 2>/dev/null
    fi
    
    echo -e "${GREEN}✓ Process priority đã được tối ưu${NC}"
}

# Timer & Interrupt Optimization
optimize_timer_interrupt() {
    echo -e "\n${YELLOW}[7/12] Tối ưu Timer & Interrupt...${NC}"
    
    # Timer
    sysctl -w kernel.timer_migration=0
    
    # RCU (Read-Copy-Update)
    sysctl -w kernel.rcu_nocb_poll=1
    
    # Watchdog (disable để giảm overhead)
    sysctl -w kernel.nmi_watchdog=0
    sysctl -w kernel.soft_watchdog=0
    
    echo -e "${GREEN}✓ Timer & Interrupt đã được tối ưu${NC}"
}

# Power Management Optimization
optimize_power() {
    echo -e "\n${YELLOW}[8/12] Tối ưu Power Management...${NC}"
    
    # Disable laptop mode
    sysctl -w vm.laptop_mode=0
    
    # PCIe ASPM (disable để giảm latency)
    if [ -f /sys/module/pcie_aspm/parameters/policy ]; then
        echo performance > /sys/module/pcie_aspm/parameters/policy 2>/dev/null
        echo -e "${GREEN}✓ PCIe ASPM: Performance${NC}"
    fi
    
    # Disable USB autosuspend
    for device in /sys/bus/usb/devices/*/power/autosuspend; do
        if [ -f "$device" ]; then
            echo -1 > "$device" 2>/dev/null
        fi
    done
    
    for device in /sys/bus/usb/devices/*/power/control; do
        if [ -f "$device" ]; then
            echo on > "$device" 2>/dev/null
        fi
    done
    
    # Disable PCI power management
    for device in /sys/bus/pci/devices/*/power/control; do
        if [ -f "$device" ]; then
            echo on > "$device" 2>/dev/null
        fi
    done
    
    echo -e "${GREEN}✓ Power Management đã được tối ưu${NC}"
}

# Kernel Parameters Optimization
optimize_kernel_params() {
    echo -e "\n${YELLOW}[9/12] Tối ưu Kernel Parameters...${NC}"
    
    # Hung task timeout (giảm để detect freeze nhanh)
    sysctl -w kernel.hung_task_timeout_secs=30
    
    # Panic settings
    sysctl -w kernel.panic=10
    sysctl -w kernel.panic_on_oops=1
    
    # Printk (giảm console output)
    sysctl -w kernel.printk="3 4 1 3"
    
    # Randomization (tắt ASLR nếu cần - security trade-off)
    # sysctl -w kernel.randomize_va_space=0
    
    echo -e "${GREEN}✓ Kernel parameters đã được tối ưu${NC}"
}

# Filesystem Optimization
optimize_filesystem() {
    echo -e "\n${YELLOW}[10/12] Tối ưu Filesystem...${NC}"
    
    # Dirty writeback (giảm lag khi save)
    sysctl -w vm.dirty_writeback_centisecs=1500
    sysctl -w vm.dirty_expire_centisecs=3000
    
    # Inotify (cho Steam, game launchers)
    sysctl -w fs.inotify.max_user_watches=524288
    sysctl -w fs.inotify.max_user_instances=512
    
    # File handles
    sysctl -w fs.file-max=2097152
    
    echo -e "${GREEN}✓ Filesystem đã được tối ưu${NC}"
}

# Disable Unnecessary Services
disable_unnecessary_services() {
    echo -e "\n${YELLOW}[11/12] Disable unnecessary services...${NC}"
    
    SERVICES_TO_DISABLE=(
        "bluetooth.service"
        "cups.service"
        "cups-browsed.service"
        "ModemManager.service"
        "packagekit.service"
    )
    
    for service in "${SERVICES_TO_DISABLE[@]}"; do
        if systemctl is-active --quiet $service; then
            systemctl stop $service 2>/dev/null
            echo -e "${GREEN}✓ Stopped: $service${NC}"
        fi
    done
    
    echo -e "${CYAN}(Services sẽ không bị disable vĩnh viễn)${NC}"
}

# Save Configuration
save_configuration() {
    echo -e "\n${YELLOW}[12/12] Lưu cấu hình vĩnh viễn...${NC}"
    
    cat > /etc/sysctl.d/96-low-latency-gaming.conf << 'EOF'
# Low Latency Gaming - System Optimization
# Giảm tối đa độ trễ của máy tính

# CPU Scheduling
kernel.sched_latency_ns = 1000000
kernel.sched_min_granularity_ns = 100000
kernel.sched_wakeup_granularity_ns = 500000
kernel.sched_migration_cost_ns = 500000
kernel.sched_autogroup_enabled = 0

# RT Scheduling
kernel.sched_rt_runtime_us = 950000
kernel.sched_rt_period_us = 1000000

# Memory Management
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1
vm.overcommit_ratio = 50
vm.zone_reclaim_mode = 0
vm.laptop_mode = 0

# Filesystem
vm.dirty_writeback_centisecs = 1500
vm.dirty_expire_centisecs = 3000
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
fs.file-max = 2097152

# Timer & Interrupt
kernel.timer_migration = 0
kernel.rcu_nocb_poll = 1
kernel.nmi_watchdog = 0
kernel.soft_watchdog = 0

# Kernel
kernel.hung_task_timeout_secs = 30
kernel.panic = 10
kernel.panic_on_oops = 1
kernel.printk = 3 4 1 3
EOF

    sysctl -p /etc/sysctl.d/96-low-latency-gaming.conf
    
    # systemd service
    cat > /etc/systemd/system/low-latency-gaming.service << 'EOF'
[Unit]
Description=Low Latency Gaming System Optimization
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/low-latency-gaming.sh apply
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable low-latency-gaming.service
    
    echo -e "${GREEN}✓ Cấu hình đã được lưu vĩnh viễn${NC}"
}

# Show system status
show_status() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}System Status:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}CPU:${NC}"
    echo -e "  Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'N/A')"
    echo -e "  Frequency: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo 'N/A') kHz"
    
    echo -e "\n${YELLOW}Memory:${NC}"
    echo -e "  Swappiness: $(sysctl -n vm.swappiness)"
    echo -e "  Cache Pressure: $(sysctl -n vm.vfs_cache_pressure)"
    
    echo -e "\n${YELLOW}Scheduler:${NC}"
    echo -e "  Latency: $(sysctl -n kernel.sched_latency_ns)ns"
    echo -e "  Min Granularity: $(sysctl -n kernel.sched_min_granularity_ns)ns"
    
    echo -e "\n${YELLOW}GPU:${NC}"
    if [ "$GPU" = "NVIDIA" ] && command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=name,power.draw,clocks.gr --format=csv,noheader
    else
        echo -e "  $GPU"
    fi
}

# Benchmark system
benchmark_system() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}System Benchmark:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}CPU Performance:${NC}"
    if command -v sysbench &> /dev/null; then
        sysbench cpu --cpu-max-prime=20000 --threads=$CPU_CORES run 2>/dev/null | grep "events per second"
    else
        echo -e "  ${CYAN}Install sysbench để benchmark${NC}"
    fi
    
    echo -e "\n${YELLOW}Memory Latency:${NC}"
    if command -v mbw &> /dev/null; then
        mbw -n 1 100 2>/dev/null | tail -3
    else
        echo -e "  ${CYAN}Install mbw để test memory${NC}"
    fi
}

# Main execution
main() {
    detect_system
    optimize_cpu
    optimize_memory
    optimize_io
    optimize_gpu
    optimize_process_priority
    optimize_timer_interrupt
    optimize_power
    optimize_kernel_params
    optimize_filesystem
    disable_unnecessary_services
    save_configuration
    show_status
    
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Low Latency Gaming hoàn tất!${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}Tối ưu đã thực hiện:${NC}"
    echo -e "  ${GREEN}✓${NC} CPU: Performance mode, C-states disabled"
    echo -e "  ${GREEN}✓${NC} Memory: Low swappiness, optimized caching"
    echo -e "  ${GREEN}✓${NC} I/O: Best scheduler cho SSD/HDD"
    echo -e "  ${GREEN}✓${NC} GPU: Max performance mode"
    echo -e "  ${GREEN}✓${NC} Scheduler: Low latency (<1ms)"
    echo -e "  ${GREEN}✓${NC} Power: Maximum performance"
    
    echo -e "\n${CYAN}Lưu ý:${NC}"
    echo -e "  • Pin sẽ tụt nhanh hơn (laptop)"
    echo -e "  • CPU/GPU chạy nóng hơn"
    echo -e "  • Trade-off: Performance > Battery life"
    echo -e "  • Khởi động lại để áp dụng hoàn toàn"
    echo ""
}

# Handle arguments
case "$1" in
    status)
        detect_system
        show_status
        ;;
    benchmark)
        detect_system
        benchmark_system
        ;;
    apply)
        # For systemd service
        detect_system
        optimize_cpu
        optimize_memory
        optimize_io
        optimize_gpu
        optimize_power
        ;;
    *)
        main
        ;;
esac
