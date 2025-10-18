# 🎮 Network Optimization Toolkit - Gaming Edition

Bộ công cụ tối ưu hóa mạng chuyên sâu cho gaming, giúp **giảm delay, ping, latency** và cải thiện trải nghiệm chơi game trên Linux.

## ✨ Tính năng

### 🚀 Giảm Delay & Latency
- ✅ Giảm ping xuống mức tối thiểu
- ✅ Phản hồi nhanh hơn khi chơi game
- ✅ Giảm bufferbloat để gameplay mượt mà
- ✅ Tối ưu TCP/UDP cho gaming

### 🌐 Tối ưu Kết nối
- ✅ Ổn định kết nối Ethernet & Wi-Fi
- ✅ Hạn chế disconnect
- ✅ Tăng độ tin cậy mạng
- ✅ Truyền tải nhanh & chính xác

### 🎯 QoS (Quality of Service)
- ✅ Ưu tiên packet gaming
- ✅ Tối ưu luồng dữ liệu router–PC
- ✅ Giảm lag khi nhiều thiết bị dùng mạng
- ✅ Bandwidth management thông minh

### 📊 Giám sát Real-time
- ✅ Monitor ping liên tục
- ✅ Test bufferbloat
- ✅ Kiểm tra chất lượng kết nối
- ✅ Network statistics chi tiết

## 📦 Cài đặt

### Quick Install (Khuyến nghị)

```bash
# Clone repository
git clone https://github.com/yourusername/network-optimization-toolkit.git
cd network-optimization-toolkit

# Chạy installer
sudo ./install.sh
```

### Manual Install

```bash
# Cài đặt dependencies
sudo apt-get update
sudo apt-get install -y iproute2 ethtool iptables bc dnsutils curl net-tools iputils-ping

# Cấp quyền thực thi cho scripts
chmod +x *.sh

# Copy vào system path (optional)
sudo cp *.sh /usr/local/bin/
```

## 🎮 Sử dụng

### 1️⃣ Network Optimizer - Tối ưu Toàn diện

Script chính để tối ưu hóa toàn bộ network stack:

```bash
sudo ./network-optimizer.sh
```

**Thực hiện:**
- Backup cấu hình hiện tại
- Tối ưu TCP/IP stack
- Giảm bufferbloat với fq_codel
- Setup QoS cho gaming
- Tối ưu network interfaces
- Giảm latency & ping
- Lưu cấu hình vĩnh viễn

### 2️⃣ Network Monitor - Giám sát Mạng

Giám sát ping, latency và chất lượng kết nối:

```bash
./network-monitor.sh
```

**Chế độ:**
- **Continuous**: Giám sát liên tục real-time
- **Single Test**: Test một lần
- **Bufferbloat Test**: Kiểm tra bufferbloat

**Hotkeys:**
```bash
./network-monitor.sh -c          # Continuous mode
./network-monitor.sh -o          # Once mode
./network-monitor.sh -b          # Bufferbloat test
```

### 3️⃣ Gaming QoS - Ưu tiên Gaming Traffic

Thiết lập QoS để ưu tiên traffic gaming:

```bash
# Cần biết tốc độ upload/download (Mbps)
sudo ./gaming-qos.sh 50 100      # 50 Mbps upload, 100 Mbps download
```

**Game ports được hỗ trợ:**
- Valorant, League of Legends, CS:GO/CS2
- Dota 2, Fortnite, PUBG, Apex Legends
- Call of Duty, Overwatch, Rainbow Six
- Và nhiều game khác...

**Kiểm tra status:**
```bash
sudo ./gaming-qos.sh status
```

**Xóa QoS:**
```bash
sudo ./gaming-qos.sh remove
```

### 4️⃣ Reduce Bufferbloat - Giảm Bufferbloat

Chuyên biệt giảm bufferbloat cho gameplay mượt mà:

```bash
sudo ./reduce-bufferbloat.sh
```

**Thực hiện:**
- Test bufferbloat hiện tại
- Áp dụng CAKE/fq_codel queue discipline
- Tối ưu network buffers
- Disable hardware offloading
- Lưu cấu hình tự động apply khi boot

**Test bufferbloat:**
```bash
sudo ./reduce-bufferbloat.sh test
```

### 5️⃣ DNS Optimizer - Tối ưu DNS

Tìm và sử dụng DNS server nhanh nhất:

```bash
sudo ./dns-optimizer.sh
```

**Tính năng:**
- Auto-detect DNS nhanh nhất
- DNS caching với dnsmasq
- Giảm DNS lookup time
- Tối ưu cho gaming

**DNS servers hỗ trợ:**
- Cloudflare (1.1.1.1)
- Google (8.8.8.8)
- OpenDNS (208.67.222.222)
- Quad9 (9.9.9.9)

### 🚀 Quick Access

Sau khi install, sử dụng lệnh `netopt` để truy cập menu chính:

```bash
netopt
```

## 📋 Yêu cầu Hệ thống

- **OS**: Linux (Ubuntu, Debian, Fedora, Arch, etc.)
- **Kernel**: 4.9+ (khuyến nghị 5.0+)
- **RAM**: 512MB+
- **Quyền**: Root access (sudo)

### Dependencies

- `iproute2` - Network configuration
- `ethtool` - Ethernet tool
- `iptables` - Firewall/QoS
- `bc` - Calculator
- `dnsutils` - DNS tools
- `curl` - Download tool

## 🔧 Cấu hình

### Network Optimizer

File cấu hình: `/etc/sysctl.d/99-gaming-network-optimization.conf`

```bash
# Xem cấu hình
cat /etc/sysctl.d/99-gaming-network-optimization.conf

# Apply thủ công
sudo sysctl -p /etc/sysctl.d/99-gaming-network-optimization.conf
```

### Gaming QoS

Chỉnh tốc độ mạng trong file hoặc command line:

```bash
# Ví dụ: 100 Mbps upload, 200 Mbps download
sudo ./gaming-qos.sh 100 200
```

### Auto-start on Boot

Enable systemd service:

```bash
# Network Optimizer
sudo systemctl enable network-optimizer.service
sudo systemctl start network-optimizer.service

# Gaming QoS
sudo systemctl enable gaming-qos.service
sudo systemctl start gaming-qos.service
```

## 📊 Kiểm tra Hiệu quả

### Test Ping

```bash
# Trước khi tối ưu
ping -c 100 8.8.8.8

# Sau khi tối ưu
ping -c 100 8.8.8.8
```

### Test Bufferbloat

```bash
# Online test
https://www.waveform.com/tools/bufferbloat

# Hoặc dùng script
sudo ./reduce-bufferbloat.sh test
```

### Monitor Real-time

```bash
./network-monitor.sh -c
```

## 🎯 Best Practices

### 1. Thứ tự Thực hiện

```bash
# Bước 1: Tối ưu tổng quát
sudo ./network-optimizer.sh

# Bước 2: Giảm bufferbloat
sudo ./reduce-bufferbloat.sh

# Bước 3: Setup QoS (nếu cần)
sudo ./gaming-qos.sh 50 100

# Bước 4: Tối ưu DNS
sudo ./dns-optimizer.sh

# Bước 5: Monitor
./network-monitor.sh -c
```

### 2. Tối ưu cho Game Cụ thể

Thêm custom ports vào `gaming-qos.sh`:

```bash
# Mở file
sudo nano gaming-qos.sh

# Tìm dòng GAMING_TCP_PORTS và GAMING_UDP_PORTS
# Thêm ports của game bạn chơi
```

### 3. Router Configuration

Để hiệu quả tối đa, cấu hình thêm ở router:

- Enable QoS trên router
- Prioritize gaming device MAC address
- Disable SIP ALG (nếu có)
- Enable UPnP cho port forwarding

### 4. Hardware Tips

- **Ethernet > Wi-Fi** cho gaming
- Dùng **Cat6/Cat7 cable** chất lượng cao
- Cắm trực tiếp vào router (tránh switch/hub)
- Disable power saving trên network adapter

## 🔍 Troubleshooting

### Script không chạy được

```bash
# Kiểm tra quyền
ls -la *.sh

# Cấp quyền execute
chmod +x *.sh

# Chạy với sudo
sudo ./network-optimizer.sh
```

### Dependencies missing

```bash
# Ubuntu/Debian
sudo apt-get install -y iproute2 ethtool iptables bc dnsutils

# Fedora/RHEL
sudo dnf install -y iproute ethtool iptables bc bind-utils

# Arch
sudo pacman -S iproute2 ethtool iptables bc bind-tools
```

### Cấu hình không apply sau reboot

```bash
# Kiểm tra service
sudo systemctl status network-optimizer.service

# Enable service
sudo systemctl enable network-optimizer.service

# Start service
sudo systemctl start network-optimizer.service
```

### Khôi phục Cấu hình Gốc

```bash
# Tìm backup
ls -la /etc/network-optimizer-backup-*

# Khôi phục sysctl
sudo cp /etc/network-optimizer-backup-*/sysctl_backup.conf /etc/sysctl.conf
sudo sysctl -p

# Khôi phục iptables
sudo iptables-restore < /etc/network-optimizer-backup-*/iptables_backup.rules

# Xóa QoS
sudo ./gaming-qos.sh remove
```

## 📈 Hiệu quả Mong đợi

### Trước tối ưu:
- 🔴 Ping: 50-100ms
- 🔴 Jitter: 10-30ms
- 🔴 Bufferbloat: Grade C-D
- 🔴 Packet loss: 1-3%

### Sau tối ưu:
- 🟢 Ping: 20-40ms (giảm 30-60%)
- 🟢 Jitter: 1-5ms (giảm 70-90%)
- 🟢 Bufferbloat: Grade A-B
- 🟢 Packet loss: <0.5%

## 🤝 Contributing

Contributions are welcome! 

```bash
# Fork repository
# Create branch
git checkout -b feature/your-feature

# Make changes
# Commit
git commit -am "Add your feature"

# Push
git push origin feature/your-feature

# Create Pull Request
```

## 📝 License

MIT License - see LICENSE file for details

## 🙏 Credits

- **BBR Congestion Control** - Google
- **fq_codel/CAKE** - Dave Täht & Bufferbloat Project
- **Community contributions** from gaming and networking forums

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/network-optimization-toolkit/issues)
- **Discord**: [Gaming Network Optimization](https://discord.gg/yourserver)
- **Reddit**: r/linux_gaming

## ⚡ Advanced Tips

### CPU Affinity for Network

```bash
# Gán network IRQ vào CPU cores riêng
sudo systemctl start irqbalance
```

### Disable IPv6 (nếu không dùng)

```bash
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
```

### Optimize Network Adapter

```bash
# Tìm network interface
ip link show

# Optimize ring buffers
sudo ethtool -G eth0 rx 4096 tx 4096

# Disable power management
sudo ethtool -s eth0 wol d
```

## 🎮 Game-Specific Ports

### Popular Games

| Game | TCP Ports | UDP Ports |
|------|-----------|-----------|
| Valorant | - | 7000-8000 |
| League of Legends | 8393-8400 | 5000-5500 |
| CS:GO/CS2 | 27015-27030 | 27000-27030 |
| Dota 2 | 27015-27050 | 27000-27050 |
| Fortnite | 80, 443, 5222 | 9000-9100 |
| PUBG | 12000-12999 | 7000-8000 |
| Apex Legends | 37000-40000 | 37000-40000 |
| Call of Duty | 3074-3075 | 3074-3075 |
| Overwatch | 80, 443, 1119 | 3478-3479 |
| Rainbow Six | 80, 443 | 3074-3075 |

## 📚 Additional Resources

- [Bufferbloat Project](https://www.bufferbloat.net/)
- [BBR Congestion Control Paper](https://research.google/pubs/pub45646/)
- [Gaming Network Guide](https://www.reddit.com/r/linux_gaming/)
- [Linux Networking Documentation](https://www.kernel.org/doc/Documentation/networking/)

---

Made with ❤️ for the gaming community

**Star ⭐ this repo if it helps you!**
