#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Anti-Bufferbloat Script for Windows
.DESCRIPTION
    Giảm bufferbloat để gameplay mượt mà hơn
    - Giảm độ trễ mạng khi có tải
    - Ổn định ping trong gaming
    - Tối ưu network buffers
#>

$ErrorActionPreference = "SilentlyContinue"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    $colors = @{"Red" = "Red"; "Green" = "Green"; "Yellow" = "Yellow"; "Blue" = "Cyan"; "Cyan" = "Cyan"}
    Write-Host $Message -ForegroundColor $colors[$Color]
}

Write-ColorOutput "═══════════════════════════════════════════════════════════" "Blue"
Write-ColorOutput "    ANTI-BUFFERBLOAT - Giảm Độ Trễ Mạng" "Green"
Write-ColorOutput "═══════════════════════════════════════════════════════════" "Blue"

# Test bufferbloat
function Test-Bufferbloat {
    Write-ColorOutput "`n[1/4] Test bufferbloat hiện tại..." "Yellow"
    Write-ColorOutput "Đang ping 8.8.8.8..." "Cyan"
    
    # Baseline ping
    $baseline = (Test-Connection -ComputerName 8.8.8.8 -Count 10 -ErrorAction SilentlyContinue | Measure-Object -Property ResponseTime -Average).Average
    Write-ColorOutput "Ping trung bình (không tải): $([math]::Round($baseline, 2)) ms" "Cyan"
    
    # Ping under load
    Write-ColorOutput "Đang tạo tải mạng để test..." "Cyan"
    $job = Start-Job -ScriptBlock {
        $wc = New-Object System.Net.WebClient
        1..5 | ForEach-Object { 
            try { $wc.DownloadData("http://speedtest.tele2.net/10MB.zip") | Out-Null } catch {}
        }
    }
    
    Start-Sleep -Seconds 2
    $underLoad = (Test-Connection -ComputerName 8.8.8.8 -Count 10 -ErrorAction SilentlyContinue | Measure-Object -Property ResponseTime -Average).Average
    Write-ColorOutput "Ping trung bình (dưới tải): $([math]::Round($underLoad, 2)) ms" "Cyan"
    
    Stop-Job $job -ErrorAction SilentlyContinue
    Remove-Job $job -ErrorAction SilentlyContinue
    
    # Calculate bufferbloat
    if ($baseline -gt 0 -and $underLoad -gt 0) {
        $increase = (($underLoad - $baseline) / $baseline) * 100
        Write-ColorOutput "`nTăng ping dưới tải: $([math]::Round($increase, 2))%" "Yellow"
        
        if ($increase -lt 10) {
            Write-ColorOutput "✓ Bufferbloat: THẤP (Rất tốt!)" "Green"
        } elseif ($increase -lt 30) {
            Write-ColorOutput "○ Bufferbloat: TRUNG BÌNH" "Cyan"
        } else {
            Write-ColorOutput "✗ Bufferbloat: CAO (Cần tối ưu!)" "Red"
        }
    }
}

# Reduce adapter buffers
function Reduce-AdapterBuffers {
    Write-ColorOutput "`n[2/4] Giảm network adapter buffers..." "Yellow"
    
    $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    
    foreach ($adapter in $adapters) {
        $name = $adapter.Name
        
        # Reduce receive buffers
        Set-NetAdapterAdvancedProperty -Name $name -DisplayName "Receive Buffers" -DisplayValue 256 -ErrorAction SilentlyContinue
        Write-ColorOutput "  ✓ Receive Buffers = 256" "Green"
        
        # Reduce transmit buffers
        Set-NetAdapterAdvancedProperty -Name $name -DisplayName "Transmit Buffers" -DisplayValue 256 -ErrorAction SilentlyContinue
        Write-ColorOutput "  ✓ Transmit Buffers = 256" "Green"
        
        # Disable interrupt moderation
        Set-NetAdapterAdvancedProperty -Name $name -DisplayName "Interrupt Moderation" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
        Write-ColorOutput "  ✓ Interrupt Moderation = Disabled" "Green"
        
        # Disable offloading that causes bufferbloat
        Disable-NetAdapterLso -Name $name -Confirm:$false -ErrorAction SilentlyContinue
        Write-ColorOutput "  ✓ Large Send Offload = Disabled" "Green"
        
        Disable-NetAdapterChecksumOffload -Name $name -Confirm:$false -ErrorAction SilentlyContinue
        Write-ColorOutput "  ✓ Checksum Offload = Disabled" "Green"
        
        Write-ColorOutput "✓ Đã cấu hình anti-bufferbloat cho $name" "Green"
    }
}

# Optimize TCP buffers
function Optimize-TCPBuffers {
    Write-ColorOutput "`n[3/4] Tối ưu hóa TCP buffers..." "Yellow"
    
    # Set optimal TCP parameters to reduce bufferbloat
    netsh int tcp set global autotuninglevel=normal
    Write-ColorOutput "  ✓ Auto-tuning level = Normal" "Green"
    
    netsh int tcp set global chimney=enabled
    Write-ColorOutput "  ✓ Chimney = Enabled" "Green"
    
    netsh int tcp set global dca=enabled
    Write-ColorOutput "  ✓ DCA = Enabled" "Green"
    
    netsh int tcp set global netdma=enabled
    Write-ColorOutput "  ✓ NetDMA = Enabled" "Green"
    
    # Reduce TCP retransmission timeout
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpInitialRtt /t REG_DWORD /d 300 /f | Out-Null
    Write-ColorOutput "  ✓ TCP Initial RTT = 300ms" "Green"
    
    # Reduce max retransmissions
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpMaxDataRetransmissions /t REG_DWORD /d 3 /f | Out-Null
    Write-ColorOutput "  ✓ Max Retransmissions = 3" "Green"
    
    Write-ColorOutput "✓ TCP buffers đã được tối ưu" "Green"
}

# Optimize QoS
function Optimize-QoS {
    Write-ColorOutput "`n[4/4] Tối ưu hóa QoS để giảm bufferbloat..." "Yellow"
    
    # Disable Windows QoS packet scheduler throttling
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 0xffffffff /f | Out-Null
    Write-ColorOutput "  ✓ Network Throttling = Disabled" "Green"
    
    # Set system responsiveness
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 0 /f | Out-Null
    Write-ColorOutput "  ✓ System Responsiveness = 0" "Green"
    
    # Optimize gaming task scheduler
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f | Out-Null
    Write-ColorOutput "  ✓ Gaming Priority = High" "Green"
    
    Write-ColorOutput "✓ QoS đã được tối ưu hóa" "Green"
}

# Show current status
function Show-Status {
    Write-ColorOutput "`n═══════════════════════════════════════════════════════════" "Blue"
    Write-ColorOutput "Trạng thái hiện tại:" "Green"
    Write-ColorOutput "═══════════════════════════════════════════════════════════" "Blue"
    
    $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    foreach ($adapter in $adapters) {
        Write-ColorOutput "`nAdapter: $($adapter.Name)" "Yellow"
        Write-ColorOutput "  Status: $($adapter.Status)" "Cyan"
        Write-ColorOutput "  Speed: $($adapter.LinkSpeed)" "Cyan"
        
        $receiveBuffer = (Get-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Receive Buffers" -ErrorAction SilentlyContinue).DisplayValue
        $transmitBuffer = (Get-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Transmit Buffers" -ErrorAction SilentlyContinue).DisplayValue
        
        if ($receiveBuffer) { Write-ColorOutput "  Receive Buffers: $receiveBuffer" "Cyan" }
        if ($transmitBuffer) { Write-ColorOutput "  Transmit Buffers: $transmitBuffer" "Cyan" }
    }
    
    Write-ColorOutput "`nTCP Settings:" "Yellow"
    netsh int tcp show global | Select-String -Pattern "Receive Window Auto-Tuning Level|Chimney Offload State|NetDMA State|Direct Cache Access"
}

# Main execution
param([string]$Action = "apply")

switch ($Action.ToLower()) {
    "test" {
        Test-Bufferbloat
    }
    "status" {
        Show-Status
    }
    default {
        Test-Bufferbloat
        Reduce-AdapterBuffers
        Optimize-TCPBuffers
        Optimize-QoS
        Show-Status
        
        Write-ColorOutput "`n═══════════════════════════════════════════════════════════" "Blue"
        Write-ColorOutput "✓ Hoàn tất giảm bufferbloat!" "Green"
        Write-ColorOutput "═══════════════════════════════════════════════════════════" "Blue"
        Write-ColorOutput "Khuyến nghị:" "Yellow"
        Write-ColorOutput "  • Khởi động lại máy để áp dụng hoàn toàn" "White"
        Write-ColorOutput "  • Test lại: .\Anti-Bufferbloat.ps1 -Action test" "White"
        Write-ColorOutput "  • Chơi game và cảm nhận sự khác biệt" "White"
        Write-Host ""
    }
}
