# 🎮 GTA5VN Optimization Guide

Hướng dẫn tối ưu chuyên biệt cho GTA5 Online / GTA5VN để giảm lag, disconnect và session timeout.

---

## 🎯 Vấn đề Thường gặp GTA5 Online

### 1. Session Timeout / Disconnect
```
Nguyên nhân:
- NAT Type strict
- Router không mở ports
- Connection timeout
- P2P connection failed
```

### 2. Lag / Rubber Banding
```
Nguyên nhân:
- High ping
- Packet loss
- Bufferbloat
- Poor network optimization
```

### 3. Loading Lâu
```
Nguyên nhân:
- Slow DNS
- Social Club connection slow
- Network congestion
```

---

## 🚀 Quick Setup

### One-Command Optimization

```bash
sudo ./gta5-optimizer.sh
```

Hoặc kết hợp với các scripts khác:

```bash
# Full optimization cho GTA5VN
sudo ./network-optimizer.sh
sudo ./reduce-bufferbloat.sh
sudo ./anti-ghostbullet.sh
sudo ./gta5-optimizer.sh
sudo ./dns-optimizer.sh
```

---

## 🔧 GTA5 Optimizer Features

### Script: gta5-optimizer.sh

✅ **Network Optimization**
- Tăng buffer cho P2P connections
- Optimize UDP transmission
- Extend port range cho nhiều connections

✅ **Port Configuration**
- Ưu tiên GTA5 ports: UDP 6672, 61455-61458
- Ưu tiên Social Club: TCP 30211-30217
- DSCP marking cho lowest latency

✅ **P2P Optimization**
- Handle nhiều P2P connections
- Connection tracking tối ưu
- File descriptors tăng lên

✅ **Session Management**
- Giảm timeout để tránh disconnect
- TCP keepalive optimization
- Faster dead connection detection

✅ **Social Club Optimization**
- Ưu tiên authentication traffic
- DNS optimization cho Rockstar servers

---

## 📋 GTA5 Ports

### UDP Ports (Game Traffic)
```
6672       - Main game traffic
61455      - P2P connection 1
61456      - P2P connection 2
61457      - P2P connection 3
61458      - P2P connection 4
```

### TCP Ports (Social Club)
```
80         - HTTP
443        - HTTPS
30211      - Social Club 1
30212      - Social Club 2
30213      - Social Club 3
30214      - Social Club 4
30215      - Social Club 5
30216      - Social Club 6
30217      - Social Club 7
```

---

## 🛠️ Router Configuration

### Enable UPnP (Khuyến nghị)

Hầu hết routers hiện đại có UPnP:

```
1. Đăng nhập router (thường 192.168.1.1)
2. Tìm "UPnP" hoặc "NAT-PMP"
3. Enable UPnP
4. Save & Reboot
```

### Manual Port Forwarding

Nếu không có UPnP, forward ports thủ công:

**UDP Forwarding:**
```
Port: 6672
Protocol: UDP
Local IP: [PC IP của bạn]
```

```
Port Range: 61455-61458
Protocol: UDP
Local IP: [PC IP của bạn]
```

**TCP Forwarding:**
```
Port Range: 30211-30217
Protocol: TCP
Local IP: [PC IP của bạn]
```

### DMZ Host (Advanced)

Nếu vẫn gặp vấn đề:

```
1. Router settings > DMZ
2. Enable DMZ
3. DMZ Host IP: [PC IP của bạn]
```

⚠️ **Cảnh báo:** DMZ expose tất cả ports, có nguy cơ bảo mật

---

## 🌐 NAT Type Optimization

### Check NAT Type

Trong GTA5 Online:
```
Pause Menu > Settings > Network
→ NAT Type: Open / Moderate / Strict
```

### NAT Types Explained

| Type | Description | Connection |
|------|-------------|------------|
| **Open** | Tốt nhất, connect dễ dàng | ✅✅✅ |
| **Moderate** | OK, connect được hầu hết | ✅✅ |
| **Strict** | Khó connect, dễ timeout | ❌ |

### Improve NAT Type

```bash
# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Run GTA5 optimizer
sudo ./gta5-optimizer.sh

# Enable UPnP on router

# Restart GTA5 và check lại NAT type
```

---

## 📊 Performance Tips

### In-Game Settings

```
Pause Menu > Online > Options

✓ Matchmaking: Open (để connect nhiều người)
✓ Voice Chat: Off (nếu không dùng - tiết kiệm bandwidth)
✓ Auto-Invite: Off
```

### System Settings

```bash
# 1. Network optimization
sudo ./network-optimizer.sh
sudo ./reduce-bufferbloat.sh
sudo ./anti-ghostbullet.sh

# 2. GTA5 specific
sudo ./gta5-optimizer.sh

# 3. DNS (khuyến nghị Cloudflare)
sudo ./dns-optimizer.sh
# Chọn option 2 (Cloudflare 1.1.1.1)

# 4. System (nếu muốn max FPS)
sudo ./low-latency-gaming.sh
```

### Firewall Settings

**Linux:**
```bash
# Allow GTA5 ports
sudo ufw allow 6672/udp
sudo ufw allow 61455:61458/udp
sudo ufw allow 30211:30217/tcp
```

**Windows (nếu dual boot):**
```
Windows Defender Firewall > Advanced Settings
→ Allow GTA5.exe
→ Allow SocialClubHelper.exe
```

---

## 🎯 Common Issues & Fixes

### Issue 1: Session Timeout

**Triệu chứng:** Bị kick khỏi session sau vài phút

**Fix:**
```bash
# Run GTA5 optimizer
sudo ./gta5-optimizer.sh

# Check NAT type - phải Open/Moderate
# Enable UPnP trên router
# Restart GTA5
```

### Issue 2: Cannot Join Friends

**Triệu chứng:** "Failed to join session"

**Fix:**
```bash
# 1. Check NAT type
# 2. Port forwarding: 6672, 61455-61458 UDP
# 3. Disable VPN nếu đang bật
# 4. Restart router và PC
```

### Issue 3: High Ping / Lag

**Triệu chứng:** Xe giật, players teleport

**Fix:**
```bash
# Network optimization
sudo ./network-optimizer.sh
sudo ./reduce-bufferbloat.sh
sudo ./anti-ghostbullet.sh

# Test ping
ping -c 50 8.8.8.8

# Nếu ping >100ms, check ISP
```

### Issue 4: Loading Lâu

**Triệu chứng:** Infinite loading cloud

**Fix:**
```bash
# 1. Optimize DNS
sudo ./dns-optimizer.sh

# 2. Clear DNS cache
sudo systemd-resolve --flush-caches

# 3. Verify game files
# Steam: Right-click > Properties > Verify
# Epic: Settings > Verify

# 4. Close background apps
```

### Issue 5: Cannot Create Session

**Triệu chứng:** "Failed to host session"

**Fix:**
```bash
# 1. NAT must be Open or Moderate
# 2. Port forward UDP 6672
# 3. Enable UPnP
# 4. Disable strict firewall
```

---

## 🔍 Testing & Verification

### Test Connection

```bash
# Run test
sudo ./gta5-optimizer.sh test

# Check Rockstar servers
ping -c 10 socialclub.rockstargames.com
ping -c 10 prod.cloud.rockstargames.com
```

### Check Status

```bash
sudo ./gta5-optimizer.sh status
```

### Monitor Network

```bash
# Real-time monitoring
./network-monitor.sh -c

# Check packet loss
ping -c 100 8.8.8.8
```

---

## 💡 Pro Tips

### 1. Best Time to Play

```
- Tránh giờ cao điểm (18:00-22:00)
- Early morning (6:00-10:00) ít người chơi = stable hơn
```

### 2. Server Selection

```
- Join vào session có ít người (10-15 players)
- Tránh full session (30 players) = lag nhiều
```

### 3. Connection Priority

```
Ethernet > Powerline Adapter > 5GHz WiFi > 2.4GHz WiFi

Khuyến nghị: Dùng Ethernet cable cho stable nhất
```

### 4. Background Apps

```
Tắt khi chơi GTA5:
✗ Chrome (nhiều tabs)
✗ Discord (nếu không dùng voice)
✗ Torrent clients
✗ Windows Update
✗ Steam downloads
```

### 5. Graphics vs Performance

```
Lower settings = Higher FPS = Better network performance

Khuyến nghị:
- VSync: OFF
- Population Density: Low
- Distance Scaling: Low-Medium
```

---

## 📈 Expected Results

### Before Optimization

```
❌ NAT Type: Strict
❌ Session timeouts: Thường xuyên
❌ Ping: 80-150ms
❌ Packet loss: 2-5%
❌ Loading time: 3-5 minutes
❌ Connection: Không ổn định
```

### After Optimization

```
✅ NAT Type: Open/Moderate
✅ Session timeouts: Hiếm khi
✅ Ping: 30-60ms (giảm 50%)
✅ Packet loss: <0.5%
✅ Loading time: 1-2 minutes
✅ Connection: Ổn định
```

---

## 🎮 GTA5VN Specific

### Vietnamese Servers

```
- Hầu hết GTA5VN chơi trên P2P (không có dedicated server)
- Host tốt = session ổn định
- Nên chơi với bạn bè có mạng tốt
```

### Discord Communities

```
Join GTA5VN communities:
- Discord servers
- Facebook groups
- Zalo groups

→ Tìm người chơi cùng region (ít lag hơn)
```

---

## 🆘 Still Having Issues?

### Diagnostic Steps

```bash
# 1. Check network
./network-monitor.sh -o

# 2. Check status
sudo ./gta5-optimizer.sh status

# 3. Test Rockstar servers
ping socialclub.rockstargames.com

# 4. Check NAT in-game

# 5. Verify ports
sudo netstat -tulpn | grep -E "6672|61455"
```

### Get Help

1. **README.md** - Main documentation
2. **Create GitHub Issue** - Technical problems
3. **GTA5VN Communities** - Game-specific help

---

## 📚 Additional Resources

- [Rockstar Support](https://support.rockstargames.com/)
- [GTA Online Port Forwarding Guide](https://portforward.com/grand-theft-auto-v/)
- [NAT Type Guide](https://support.rockstargames.com/articles/200525767)

---

**Chúc bạn chơi GTA5VN vui vẻ!** 🚗💨

**No lag, no disconnect, just fun!** 🎮
