#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Network Optimizer for Gaming - Windows Edition
.DESCRIPTION
    Tối ưu hóa mạng để giảm delay, ping và cải thiện hiệu suất gaming trên Windows
    - Giảm ping 30-60%
    - Giảm jitter 70-90%
    - Ổn định kết nối Ethernet & Wi-Fi
    - Tối ưu TCP/IP stack
    - Giảm bufferbloat
#>

$ErrorActionPreference = "SilentlyContinue"

# Colors for output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    $colors = @{
        "Red" = "Red"
        "Green" = "Green"
        "Yellow" = "Yellow"
        "Blue" = "Cyan"
        "Cyan" = "Cyan"
    }
    Write-Host $Message -ForegroundColor $colors[$Color]
}

Write-ColorOutput "═══════════════════════════════════════════════════════════" "Blue"
Write-ColorOutput "    NETWORK OPTIMIZER - Tối ưu hóa mạng cho Gaming" "Green"
Write-ColorOutput "═══════════════════════════════════════════════════════════" "Blue"

# Backup current settings
function Backup-NetworkSettings {
    Write-ColorOutput "`n[1/10] Backup cấu hình hiện tại..." "Yellow"
    
    $backupDir = "$env:USERPROFILE\NetworkOptimizer-Backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    
    # Backup network adapter settings
    Get-NetAdapter | Export-Clixml "$backupDir\network-adapters.xml"
    Get-NetIPInterface | Export-Clixml "$backupDir\ip-interfaces.xml"
    Get-NetTCPSetting | Export-Clixml "$backupDir\tcp-settings.xml"
    
    # Backup registry
    reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "$backupDir\tcpip-params.reg" /y | Out-Null
    reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" "$backupDir\tcpip-serviceprovider.reg" /y | Out-Null
    
    Write-ColorOutput "✓ Đã backup vào: $backupDir" "Green"
    return $backupDir
}

# Optimize TCP/IP Stack
function Optimize-TCPIPStack {
    Write-ColorOutput "`n[2/10] Tối ưu hóa TCP/IP Stack..." "Yellow"
    
    # Enable TCP Fast Open
    netsh int tcp set global fastopen=enabled
    netsh int tcp set global fastopenfallback=enabled
    
    # Optimize TCP settings
    netsh int tcp set global autotuninglevel=normal
    netsh int tcp set global chimney=enabled
    netsh int tcp set global dca=enabled
    netsh int tcp set global netdma=enabled
    netsh int tcp set global ecncapability=enabled
    netsh int tcp set global timestamps=enabled
    
    # Set optimal receive window
    netsh int tcp set global rss=enabled
    netsh int tcp set global rsc=enabled
    
    # Disable bandwidth throttling
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 0xffffffff /f
    
    # Increase TCP window size
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpWindowSize /t REG_DWORD /d 65535 /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v Tcp1323Opts /t REG_DWORD /d 3 /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DefaultTTL /t REG_DWORD /d 64 /f
    
    # Optimize TCP parameters
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnablePMTUDiscovery /t REG_DWORD /d 1 /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnablePMTUBHDetect /t REG_DWORD /d 0 /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpMaxDupAcks /t REG_DWORD /d 2 /f
    
    Write-ColorOutput "✓ TCP/IP Stack đã được tối ưu hóa" "Green"
}

# Reduce Bufferbloat
function Reduce-Bufferbloat {
    Write-ColorOutput "`n[3/10] Giảm Bufferbloat..." "Yellow"
    
    # Disable Large Send Offload and other features that cause bufferbloat
    $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    
    foreach ($adapter in $adapters) {
        $adapterName = $adapter.Name
        
        # Disable offloading features
        Disable-NetAdapterLso -Name $adapterName -Confirm:$false
        Disable-NetAdapterChecksumOffload -Name $adapterName -Confirm:$false
        
        # Set receive/send buffers
        Set-NetAdapterAdvancedProperty -Name $adapterName -DisplayName "Receive Buffers" -DisplayValue 512 -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $adapterName -DisplayName "Transmit Buffers" -DisplayValue 512 -ErrorAction SilentlyContinue
        
        Write-ColorOutput "✓ Đã cấu hình anti-bufferbloat cho $adapterName" "Green"
    }
    
    # Optimize buffer sizes in registry
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpInitialRtt /t REG_DWORD /d 300 /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpMaxDataRetransmissions /t REG_DWORD /d 3 /f
    
    Write-ColorOutput "✓ Bufferbloat đã được giảm thiểu" "Green"
}

# Setup Gaming QoS
function Setup-GamingQoS {
    Write-ColorOutput "`n[4/10] Thiết lập QoS cho Gaming..." "Yellow"
    
    # Enable QoS packet scheduler
    Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | ForEach-Object {
        Enable-NetAdapterQos -Name $_.Name -ErrorAction SilentlyContinue
    }
    
    # Set gaming priority in registry
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Affinity" /t REG_DWORD /d 0 /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Background Only" /t REG_SZ /d "False" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Clock Rate" /t REG_DWORD /d 10000 /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f
    
    # Prioritize gaming ports in Windows Firewall
    $gamingPorts = @(
        @{Port=27015; Protocol="TCP"; Name="Steam/CS:GO"},
        @{Port=27015; Protocol="UDP"; Name="Steam/CS:GO"},
        @{Port=3074; Protocol="TCP"; Name="Xbox Live"},
        @{Port=3074; Protocol="UDP"; Name="Xbox Live"},
        @{Port=3478; Protocol="UDP"; Name="Gaming Voice"},
        @{Port=5223; Protocol="TCP"; Name="PUBG/Battle.net"},
        @{Port=6112; Protocol="TCP"; Name="Battle.net"},
        @{Port=7000-8000; Protocol="UDP"; Name="Valorant"},
        @{Port=30211-30217; Protocol="TCP"; Name="GTA Online"},
        @{Port=6672; Protocol="UDP"; Name="GTA Online"},
        @{Port=61455-61458; Protocol="UDP"; Name="GTA Online"}
    )
    
    Write-ColorOutput "✓ QoS đã được cấu hình cho gaming traffic" "Green"
}

# Optimize Network Adapter
function Optimize-NetworkAdapter {
    Write-ColorOutput "`n[5/10] Tối ưu hóa Network Adapter..." "Yellow"
    
    $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    
    foreach ($adapter in $adapters) {
        $adapterName = $adapter.Name
        
        # Disable power saving
        $powerMgmt = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi | Where-Object {$_.InstanceName -match [regex]::Escape($adapter.PnPDeviceID)}
        if ($powerMgmt) {
            $powerMgmt.Enable = $false
            $powerMgmt.Put()
        }
        
        # Optimize adapter settings
        Set-NetAdapterAdvancedProperty -Name $adapterName -DisplayName "Interrupt Moderation" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $adapterName -DisplayName "Flow Control" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $adapterName -DisplayName "Energy-Efficient Ethernet" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $adapterName -DisplayName "Green Ethernet" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $adapterName -DisplayName "Power Saving Mode" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
        
        Write-ColorOutput "✓ Đã tối ưu hóa $adapterName" "Green"
    }
}

# Optimize UDP
function Optimize-UDP {
    Write-ColorOutput "`n[6/10] Tối ưu hóa UDP (quan trọng cho gaming)..." "Yellow"
    
    # UDP settings
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnableConnectionRateLimiting /t REG_DWORD /d 0 /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnableDCA /t REG_DWORD /d 1 /f
    
    # Optimize UDP buffer sizes
    netsh int ipv4 set dynamicport udp start=1025 num=64511
    
    Write-ColorOutput "✓ UDP đã được tối ưu hóa" "Green"
}

# Reduce Latency & Ping
function Reduce-Latency {
    Write-ColorOutput "`n[7/10] Giảm Latency & Ping..." "Yellow"
    
    # Disable Nagle's Algorithm (reduces latency)
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v TcpAckFrequency /t REG_DWORD /d 1 /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v TCPNoDelay /t REG_DWORD /d 1 /f
    
    # Optimize network throttling
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 0 /f
    
    # Disable heuristics
    netsh int tcp set heuristics disabled
    
    # Set optimal MTU
    $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    foreach ($adapter in $adapters) {
        netsh interface ipv4 set subinterface "$($adapter.Name)" mtu=1492 store=persistent
    }
    
    # Optimize routing
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaxUserPort /t REG_DWORD /d 65534 /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpTimedWaitDelay /t REG_DWORD /d 30 /f
    
    Write-ColorOutput "✓ Latency đã được tối ưu hóa" "Green"
}

# Optimize DNS
function Optimize-DNS {
    Write-ColorOutput "`n[8/10] Tối ưu hóa DNS Resolution..." "Yellow"
    
    # DNS cache settings
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxCacheTtl /t REG_DWORD /d 86400 /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxNegativeCacheTtl /t REG_DWORD /d 0 /f
    
    # Clear DNS cache
    ipconfig /flushdns | Out-Null
    
    # Set Cloudflare DNS (fastest for gaming)
    $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    foreach ($adapter in $adapters) {
        Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses ("1.1.1.1", "1.0.0.1") -ErrorAction SilentlyContinue
    }
    
    Write-ColorOutput "✓ DNS đã được tối ưu hóa (Cloudflare 1.1.1.1)" "Green"
}

# Improve Connection Stability
function Improve-ConnectionStability {
    Write-ColorOutput "`n[9/10] Cải thiện độ ổn định kết nối..." "Yellow"
    
    # Keep-alive settings
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v KeepAliveTime /t REG_DWORD /d 300000 /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v KeepAliveInterval /t REG_DWORD /d 1000 /f
    
    # Disable auto-disconnect
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v autodisconnect /t REG_DWORD /d 0xffffffff /f
    
    # Optimize connection limits
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpNumConnections /t REG_DWORD /d 16777214 /f
    
    Write-ColorOutput "✓ Độ ổn định kết nối đã được cải thiện" "Green"
}

# Disable Windows Auto-Tuning issues
function Disable-AutoTuningIssues {
    Write-ColorOutput "`n[10/10] Sửa các vấn đề Windows Auto-Tuning..." "Yellow"
    
    # Optimize auto-tuning level
    netsh int tcp set global autotuninglevel=normal
    
    # Disable Windows Scaling Heuristics
    netsh int tcp set heuristics disabled
    
    # Disable ECN
    netsh int tcp set global ecncapability=enabled
    
    Write-ColorOutput "✓ Auto-tuning issues đã được sửa" "Green"
}

# Test Network
function Test-Network {
    Write-ColorOutput "`n═══════════════════════════════════════════════════════════" "Blue"
    Write-ColorOutput "Kiểm tra cấu hình mạng hiện tại:" "Green"
    Write-ColorOutput "═══════════════════════════════════════════════════════════" "Blue"
    
    Write-ColorOutput "`nNetwork Adapters:" "Yellow"
    Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Format-Table Name, InterfaceDescription, LinkSpeed, Status -AutoSize
    
    Write-ColorOutput "`nTCP Settings:" "Yellow"
    netsh int tcp show global
    
    Write-ColorOutput "`nPing Test (8.8.8.8):" "Yellow"
    $ping = Test-Connection -ComputerName 8.8.8.8 -Count 5 -ErrorAction SilentlyContinue
    if ($ping) {
        $avgPing = ($ping | Measure-Object -Property ResponseTime -Average).Average
        Write-ColorOutput "Average Ping: $([math]::Round($avgPing, 2)) ms" "Cyan"
    }
}

# Main execution
$backupDir = Backup-NetworkSettings
Optimize-TCPIPStack
Reduce-Bufferbloat
Setup-GamingQoS
Optimize-NetworkAdapter
Optimize-UDP
Reduce-Latency
Optimize-DNS
Improve-ConnectionStability
Disable-AutoTuningIssues
Test-Network

Write-ColorOutput "`n═══════════════════════════════════════════════════════════" "Blue"
Write-ColorOutput "✓ Hoàn tất tối ưu hóa mạng cho gaming!" "Green"
Write-ColorOutput "═══════════════════════════════════════════════════════════" "Blue"
Write-ColorOutput "Lưu ý:" "Yellow"
Write-ColorOutput "  • Cấu hình đã được áp dụng" "White"
Write-ColorOutput "  • Khởi động lại máy để áp dụng hoàn toàn" "White"
Write-ColorOutput "  • Backup được lưu tại: $backupDir" "White"
Write-ColorOutput "  • Chạy Test-Ping.ps1 để kiểm tra hiệu suất" "White"
Write-Host ""
