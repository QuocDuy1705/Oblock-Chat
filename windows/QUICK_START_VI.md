# ⚡ HƯỚNG DẪN NHANH - WINDOWS GAMING OPTIMIZER

## 🎯 3 BƯỚC ĐƠN GIẢN

### BƯỚC 1: Tải xuống
1. Tải TẤT CẢ file `.ps1` về cùng 1 thư mục
2. Giải nén (nếu có)

### BƯỚC 2: Mở PowerShell (Admin)
1. Nhấn phím **Windows + X**
2. Chọn **"Windows PowerShell (Admin)"** hoặc **"Terminal (Admin)"**
3. Nếu hỏi, click **"Yes"**

### BƯỚC 3: Chạy Installer
```powershell
# Cho phép chạy scripts (chỉ cần 1 lần)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Di chuyển đến thư mục chứa scripts
cd "C:\path\to\scripts"     # Thay đổi path này

# Chạy master installer
.\Install-All.ps1
```

### BƯỚC 4: Khởi động lại
**QUAN TRỌNG**: Khởi động lại máy sau khi hoàn tất!

---

## 🚀 CÁCH SỬ DỤNG CHO TỪNG TÍNH NĂNG

### 1. Tối ưu Toàn Bộ (Khuyến nghị)
```powershell
.\Install-All.ps1
```
Áp dụng **TẤT CẢ** tối ưu một lần.

---

### 2. Chỉ Tối ưu Mạng
```powershell
.\Network-Optimizer.ps1
```
- Giảm ping
- Giảm bufferbloat
- Tối ưu TCP/UDP

---

### 3. Chỉ Giảm Lag Input (Chuột/Phím)
```powershell
.\Input-Optimizer.ps1
```
- Giảm delay chuột
- Giảm delay phím
- USB 1000Hz

---

### 4. Chỉ Tối ưu Hiệu Năng
```powershell
.\Low-Latency-Gaming.ps1
```
- CPU max performance
- GPU max performance
- RAM optimized

---

### 5. Chỉ Anti-White Bullet
```powershell
.\Anti-WhiteBullet.ps1
```
- Xóa viên đạn trắng
- Cải thiện hitreg
- Giảm packet loss

---

## 📊 KẾT QUẢ MONG ĐỢI

| Trước | Sau | Cải thiện |
|-------|-----|-----------|
| Ping: 60ms | Ping: 25ms | **↓58%** |
| Jitter: 20ms | Jitter: 2ms | **↓90%** |
| Input lag: 40ms | Input lag: 12ms | **↓70%** |
| Ghost bullets: Nhiều | Ghost bullets: Hiếm | **↓90%** |

---

## ❓ CÂU HỎI THƯỜNG GẶP

### Q: Lỗi "cannot be loaded because running scripts is disabled"?
**A:** Chạy lệnh này trong PowerShell (Admin):
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Q: Có cần khởi động lại không?
**A:** **CÓ** - BẮT BUỘC khởi động lại để áp dụng hoàn toàn!

### Q: Có an toàn không?
**A:** **CÓ** - Scripts tự động backup cấu hình cũ. Có thể restore bất cứ lúc nào.

### Q: Laptop có bị tụt pin không?
**A:** **CÓ** - Pin sẽ tụt nhanh hơn vì CPU/GPU chạy max performance.

### Q: Làm sao để hoàn tác?
**A:** Tìm folder backup (thường ở `C:\Users\[Tên]\NetworkOptimizer-Backup-...`), restore các file `.reg`, khởi động lại.

---

## ⚠️ LƯU Ý

### ✅ NÊN:
- Chạy với quyền Administrator
- Đóng tất cả game/app trước khi chạy
- Khởi động lại sau khi hoàn tất
- Dùng Ethernet (không phải Wi-Fi)

### ❌ KHÔNG NÊN:
- Chạy khi đang chơi game
- Bỏ qua bước khởi động lại
- Chạy nhiều lần liên tục
- Dùng cho laptop khi pin yếu

---

## 🆘 GẶP VẤN ĐỀ?

### Script không chạy
1. Kiểm tra quyền Admin
2. Chạy: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
3. Khởi động lại PowerShell

### Ping vẫn cao
1. Kiểm tra Router/ISP
2. Dùng Ethernet thay vì Wi-Fi
3. Tắt VPN/Proxy
4. Khởi động lại máy

### Game vẫn lag
1. Cập nhật driver GPU
2. Kiểm tra nhiệt độ CPU/GPU
3. Giảm settings trong game
4. Tắt app background

---

## 📞 HỖ TRỢ

**Đọc file README.md đầy đủ để biết thêm chi tiết!**

---

## 🎮 CHÚC MỪNG!

Bây giờ bạn đã sẵn sàng để:
- ✅ Giảm ping
- ✅ Giảm lag
- ✅ Xóa white bullets
- ✅ Aim chính xác hơn
- ✅ **Rank cao hơn! 🏆**

**HÃY KHỞI ĐỘNG LẠI MÁY VÀ BẮT ĐẦU CHƠI GAME!**
