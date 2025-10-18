# 🚀 Quick Start Guide - Network Optimization cho Gaming

Hướng dẫn nhanh để giảm delay, ping và tối ưu mạng cho gaming trong vài phút.

## ⚡ Cài đặt Nhanh (5 phút)

### Bước 1: Clone Repository

```bash
git clone https://github.com/yourusername/network-optimization-toolkit.git
cd network-optimization-toolkit
```

### Bước 2: Chạy Installer

```bash
chmod +x install.sh
sudo ./install.sh
```

Installer sẽ tự động:
- Cài đặt tất cả dependencies
- Copy scripts vào system
- Tạo systemd services
- Cấu hình kernel modules

## 🎮 Sử dụng Ngay

### Option 1: Auto-Optimize (Khuyến nghị cho người mới)

Chạy lệnh này để tối ưu tự động:

```bash
sudo ./network-optimizer.sh
```

✅ Script sẽ tự động:
- Backup cấu hình cũ
- Tối ưu TCP/IP
- Giảm bufferbloat
- Setup QoS
- Giảm latency
- Lưu cấu hình vĩnh viễn

**Thời gian:** ~2 phút

### Option 2: Từng Bước (Cho người muốn kiểm soát)

#### 1. Tối ưu Network

```bash
sudo ./network-optimizer.sh
```

#### 2. Giảm Bufferbloat

```bash
sudo ./reduce-bufferbloat.sh
```

#### 3. Setup Gaming QoS

```bash
# Thay 50 và 100 bằng tốc độ mạng thực của bạn (Mbps)
sudo ./gaming-qos.sh 50 100
```

💡 **Làm sao biết tốc độ mạng?**
- Test tại: https://fast.com hoặc https://speedtest.net
- Upload speed thường thấp hơn download
- Ví dụ: Upload 50Mbps, Download 100Mbps

#### 4. Tối ưu DNS

```bash
sudo ./dns-optimizer.sh
# Chọn option 1 (Auto) để tìm DNS nhanh nhất
```

## 📊 Kiểm tra Kết quả

### Test Ping

```bash
./network-monitor.sh
# Chọn option 2 (Test một lần)
```

Bạn sẽ thấy:
- ✅ Ping giảm đáng kể
- ✅ Jitter thấp hơn
- ✅ Packet loss gần 0%

### Monitor Real-time

```bash
./network-monitor.sh
# Chọn option 1 (Giám sát liên tục)
```

## 🎯 Kết quả Mong đợi

| Metric | Trước | Sau | Cải thiện |
|--------|-------|-----|-----------|
| **Ping** | 60-100ms | 20-40ms | ↓50-60% |
| **Jitter** | 15-30ms | 2-5ms | ↓80-90% |
| **Bufferbloat** | Grade C-D | Grade A-B | ⭐⭐⭐ |
| **Packet Loss** | 1-3% | <0.5% | ↓70-90% |

## 🔧 Cấu hình Cho Game Cụ thể

### Valorant

```bash
# Valorant dùng UDP ports 7000-8000
sudo ./gaming-qos.sh 50 100
# Ports đã được include sẵn
```

### League of Legends

```bash
# LoL dùng UDP 5000-5500, TCP 8393-8400
sudo ./gaming-qos.sh 50 100
# Ports đã được include sẵn
```

### CS:GO / CS2

```bash
# CS dùng UDP/TCP 27000-27030
sudo ./gaming-qos.sh 50 100
# Ports đã được include sẵn
```

## 🛠️ Commands Hữu ích

### Kiểm tra Status

```bash
# Network status
sudo ./gaming-qos.sh status

# Bufferbloat status
sudo ./reduce-bufferbloat.sh status

# DNS status
sudo ./dns-optimizer.sh status
```

### Xóa Cấu hình

```bash
# Xóa QoS
sudo ./gaming-qos.sh remove

# Khôi phục DNS gốc
sudo ./dns-optimizer.sh
# Chọn option 6 (Khôi phục)
```

### Auto-start khi Boot

```bash
# Enable
sudo systemctl enable network-optimizer.service
sudo systemctl enable gaming-qos.service

# Disable
sudo systemctl disable network-optimizer.service
sudo systemctl disable gaming-qos.service
```

## 📱 Quick Access Menu

Sau khi install, dùng lệnh `netopt`:

```bash
netopt
```

Menu sẽ hiện:
```
╔════════════════════════════════════════════╗
║  Network Optimization Toolkit              ║
╚════════════════════════════════════════════╝

1. Network Optimizer   - Tối ưu toàn diện
2. Network Monitor     - Giám sát mạng
3. Gaming QoS          - Ưu tiên gaming
4. Reduce Bufferbloat  - Giảm bufferbloat
5. DNS Optimizer       - Tối ưu DNS
```

## ⚠️ Lưu ý Quan trọng

### 1. Cần Root Access

Tất cả scripts cần chạy với `sudo`:

```bash
sudo ./network-optimizer.sh  # ✅ Đúng
./network-optimizer.sh       # ❌ Sai
```

### 2. Backup Tự động

Scripts tự động backup cấu hình vào:
```
/etc/network-optimizer-backup-YYYYMMDD-HHMMSS/
```

### 3. Khởi động lại

Sau khi cấu hình lần đầu, khuyến nghị:
```bash
sudo reboot
```

### 4. Test Trước - Sau

```bash
# Test TRƯỚC khi tối ưu
ping -c 50 8.8.8.8 > before.txt

# Chạy tối ưu
sudo ./network-optimizer.sh

# Test SAU khi tối ưu
ping -c 50 8.8.8.8 > after.txt

# So sánh
cat before.txt after.txt
```

## 🆘 Troubleshooting Nhanh

### Script báo lỗi permission

```bash
chmod +x *.sh
sudo ./script-name.sh
```

### Không thấy sự khác biệt

```bash
# Kiểm tra cấu hình đã apply chưa
sysctl net.ipv4.tcp_congestion_control
# Nên là: bbr

sysctl net.core.default_qdisc
# Nên là: fq_codel

# Nếu chưa, chạy lại
sudo ./network-optimizer.sh
sudo reboot
```

### Ping vẫn cao

1. **Kiểm tra kết nối vật lý**
   - Dùng Ethernet thay vì Wi-Fi
   - Kiểm tra cable chất lượng

2. **Kiểm tra ISP**
   - Có thể ISP của bạn có ping cao tự nhiên
   - Test ping đến router: `ping 192.168.1.1`

3. **Kiểm tra router**
   - Enable QoS trên router
   - Update firmware router

### QoS không hoạt động

```bash
# Kiểm tra interface
ip link show

# Kiểm tra qdisc
tc qdisc show

# Apply lại
sudo ./gaming-qos.sh 50 100
```

## 💡 Tips Nâng cao

### 1. Combine với Router QoS

Để hiệu quả tối đa:
- Bật QoS trên router
- Set priority cho PC/gaming device
- Sử dụng cả hai cấu hình (PC + Router)

### 2. Monitor Thường xuyên

```bash
# Chạy monitor trong tmux/screen
tmux
./network-monitor.sh -c
# Ctrl+B, D để detach
```

### 3. Game-specific Optimization

Nếu chơi game có ports đặc biệt:
```bash
# Edit gaming-qos.sh
sudo nano /usr/local/bin/gaming-qos.sh

# Tìm dòng GAMING_TCP_PORTS và GAMING_UDP_PORTS
# Thêm ports của game
```

### 4. Disable không cần thiết

```bash
# Nếu không dùng IPv6
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1

# Nếu không dùng Bluetooth
sudo systemctl disable bluetooth
```

## 📞 Cần Hỗ trợ?

1. **Đọc README.md** - Hướng dẫn chi tiết
2. **Check Issues** - Có thể ai đó đã gặp vấn đề tương tự
3. **Create Issue** - Mô tả chi tiết vấn đề
4. **Discord/Reddit** - Cộng đồng sẵn sàng giúp đỡ

## ✅ Checklist Hoàn thành

- [ ] Clone repository
- [ ] Chạy `sudo ./install.sh`
- [ ] Chạy `sudo ./network-optimizer.sh`
- [ ] Chạy `./network-monitor.sh` để test
- [ ] Setup QoS với `sudo ./gaming-qos.sh`
- [ ] Test trong game
- [ ] Enable auto-start (optional)
- [ ] Khởi động lại PC

## 🎮 Ready to Game!

Sau khi hoàn thành, bạn đã sẵn sàng:
- ✅ Ping thấp hơn
- ✅ Gameplay mượt mà hơn
- ✅ Ít lag/disconnect
- ✅ Phản hồi nhanh hơn

**Chúc bạn gaming vui vẻ!** 🎮🚀

---

**Pro Tip:** Share kết quả trước/sau với cộng đồng để giúp người khác! 🤝
