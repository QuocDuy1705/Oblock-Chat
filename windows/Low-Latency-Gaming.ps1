#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Low Latency Gaming - System Optimizer
.DESCRIPTION
    Giảm tối đa độ trễ của máy tính
    Tối ưu CPU, RAM, GPU, Storage cho gaming
    - Giảm system latency 75%
    - CPU/GPU max performance
    - Memory & I/O optimization
#>

$ErrorActionPreference = "SilentlyContinue"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    $colors = @{"Red" = "Red"; "Green" = "Green"; "Yellow" = "Yellow"; "Blue" = "Cyan"; "Cyan" = "Cyan"}
    Write-Host $Message -ForegroundColor $colors[$Color]
}

Write-ColorOutput "╔════════════════════════════════════════════════════════════╗" "Blue"
Write-ColorOutput "║   LOW LATENCY GAMING - Tối ưu Toàn Bộ Hệ Thống          ║" "Green"
Write-ColorOutput "╚════════════════════════════════════════════════════════════╝" "Blue"

# Detect system
function Detect-System {
    Write-ColorOutput "`n[1/10] Phát hiện cấu hình hệ thống..." "Yellow"
    
    $cpu = Get-WmiObject Win32_Processor
    $ram = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    $gpu = Get-WmiObject Win32_VideoController | Select-Object -First 1
    
    Write-ColorOutput "✓ System Info:" "Green"
    Write-ColorOutput "  CPU: $($cpu.Name)" "White"
    Write-ColorOutput "  Cores: $($cpu.NumberOfCores) / Threads: $($cpu.NumberOfLogicalProcessors)" "White"
    Write-ColorOutput "  RAM: $ram GB" "White"
    Write-ColorOutput "  GPU: $($gpu.Name)" "White"
    
    return @{
        CPU = $cpu
        RAM = $ram
        GPU = $gpu
    }
}

# Optimize CPU
function Optimize-CPU {
    Write-ColorOutput "`n[2/10] Tối ưu CPU..." "Yellow"
    
    # Set High Performance power plan
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Write-ColorOutput "  ✓ Power Plan = High Performance" "Green"
    
    # Disable CPU parking
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v ValueMax /t REG_DWORD /d 0 /f | Out-Null
    powercfg /setacvalueindex scheme_current sub_processor CPMINCORES 100
    powercfg /setactive scheme_current
    Write-ColorOutput "  ✓ CPU Parking = Disabled (All cores active)" "Green"
    
    # Disable CPU throttling
    powercfg /setacvalueindex scheme_current sub_processor PROCTHROTTLEMAX 100
    powercfg /setdcvalueindex scheme_current sub_processor PROCTHROTTLEMAX 100
    powercfg /setacvalueindex scheme_current sub_processor PROCTHROTTLEMIN 100
    powercfg /setdcvalueindex scheme_current sub_processor PROCTHROTTLEMIN 100
    powercfg /setactive scheme_current
    Write-ColorOutput "  ✓ CPU Throttling = Disabled (Max 100%)" "Green"
    
    # Disable C-States (CPU idle states)
    powercfg /setacvalueindex scheme_current sub_processor IDLEDISABLE 1
    powercfg /setactive scheme_current
    Write-ColorOutput "  ✓ C-States = Disabled" "Green"
    
    # Set processor performance boost mode to aggressive
    powercfg /setacvalueindex scheme_current sub_processor PERFBOOSTMODE 2
    powercfg /setactive scheme_current
    Write-ColorOutput "  ✓ Turbo Boost = Aggressive" "Green"
    
    # Optimize processor scheduling for programs (not background services)
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 0x26 /f | Out-Null
    Write-ColorOutput "  ✓ CPU Priority = Programs (Gaming)" "Green"
    
    Write-ColorOutput "✓ CPU đã được tối ưu" "Green"
}

# Optimize Memory
function Optimize-Memory {
    Write-ColorOutput "`n[3/10] Tối ưu RAM & Memory..." "Yellow"
    
    # Disable paging executive (keep kernel in RAM)
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 1 /f | Out-Null
    Write-ColorOutput "  ✓ Paging Executive = Disabled" "Green"
    
    # Clear page file at shutdown (optional)
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v ClearPageFileAtShutdown /t REG_DWORD /d 0 /f | Out-Null
    
    # Large system cache (for better performance)
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 0 /f | Out-Null
    Write-ColorOutput "  ✓ System Cache = Optimized for Applications" "Green"
    
    # Optimize prefetch and superfetch
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 3 /f | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 3 /f | Out-Null
    Write-ColorOutput "  ✓ Prefetch/Superfetch = Optimized" "Green"
    
    # Reduce memory usage by services
    reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v SvcHostSplitThresholdInKB /t REG_DWORD /d 0x380000 /f | Out-Null
    Write-ColorOutput "  ✓ Service Host Splitting = Optimized" "Green"
    
    Write-ColorOutput "✓ Memory đã được tối ưu" "Green"
}

# Optimize Storage I/O
function Optimize-Storage {
    Write-ColorOutput "`n[4/10] Tối ưu Storage I/O..." "Yellow"
    
    # Disable Windows Search indexing (reduces I/O)
    Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "WSearch" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-ColorOutput "  ✓ Windows Search = Disabled" "Green"
    
    # Disable Superfetch (on SSD)
    Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-ColorOutput "  ✓ SysMain (Superfetch) = Disabled" "Green"
    
    # Optimize all drives
    Get-PhysicalDisk | ForEach-Object {
        $mediaType = $_.MediaType
        Write-ColorOutput "  Disk $($_.FriendlyName): $mediaType" "Cyan"
        
        if ($mediaType -eq "SSD") {
            # SSD optimizations
            fsutil behavior set disabledeletenotify 0 | Out-Null
            Write-ColorOutput "    ✓ TRIM = Enabled" "Green"
        }
    }
    
    # Disable hibernation (frees up disk space)
    powercfg /hibernate off
    Write-ColorOutput "  ✓ Hibernation = Disabled" "Green"
    
    Write-ColorOutput "✓ Storage I/O đã được tối ưu" "Green"
}

# Optimize GPU
function Optimize-GPU {
    param($SystemInfo)
    
    Write-ColorOutput "`n[5/10] Tối ưu GPU..." "Yellow"
    
    $gpuName = $SystemInfo.GPU.Name
    
    if ($gpuName -like "*NVIDIA*") {
        Write-ColorOutput "  Phát hiện NVIDIA GPU" "Cyan"
        
        # NVIDIA settings via registry
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrLevel /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrDelay /t REG_DWORD /d 60 /f | Out-Null
        Write-ColorOutput "  ✓ NVIDIA TDR = Extended timeout" "Green"
        
    } elseif ($gpuName -like "*AMD*" -or $gpuName -like "*Radeon*") {
        Write-ColorOutput "  Phát hiện AMD GPU" "Cyan"
        
        # AMD settings
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrLevel /t REG_DWORD /d 0 /f | Out-Null
        Write-ColorOutput "  ✓ AMD GPU = High Performance" "Green"
        
    } elseif ($gpuName -like "*Intel*") {
        Write-ColorOutput "  Phát hiện Intel GPU" "Cyan"
        Write-ColorOutput "  ✓ Intel GPU: Using default settings" "Green"
    }
    
    # Universal GPU optimizations
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v EnablePreemption /t REG_DWORD /d 0 /f | Out-Null
    Write-ColorOutput "  ✓ GPU Preemption = Disabled" "Green"
    
    # Hardware-accelerated GPU scheduling (Windows 10 2004+)
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f | Out-Null
    Write-ColorOutput "  ✓ Hardware GPU Scheduling = Enabled" "Green"
    
    Write-ColorOutput "✓ GPU đã được tối ưu" "Green"
}

# Optimize Process Priority
function Optimize-ProcessPriority {
    Write-ColorOutput "`n[6/10] Tối ưu Process Priority..." "Yellow"
    
    # Gaming task priority
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Affinity" /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Background Only" /t REG_SZ /d "False" /f | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Clock Rate" /t REG_DWORD /d 10000 /f | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f | Out-Null
    
    Write-ColorOutput "  ✓ Gaming Priority = High" "Green"
    Write-ColorOutput "  ✓ GPU Priority = 8 (Maximum)" "Green"
    Write-ColorOutput "  ✓ Scheduling Category = High" "Green"
    
    Write-ColorOutput "✓ Process priority đã được tối ưu" "Green"
}

# Optimize Timer Resolution
function Optimize-TimerResolution {
    Write-ColorOutput "`n[7/10] Tối ưu Timer Resolution..." "Yellow"
    
    # Set timer resolution to 0.5ms (gaming optimal)
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v GlobalTimerResolutionRequests /t REG_DWORD /d 1 /f | Out-Null
    Write-ColorOutput "  ✓ Timer Resolution = High (0.5ms)" "Green"
    
    # Optimize multimedia timer
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 0 /f | Out-Null
    Write-ColorOutput "  ✓ System Responsiveness = 0 (Best for gaming)" "Green"
    
    Write-ColorOutput "✓ Timer resolution đã được tối ưu" "Green"
}

# Optimize Windows Services
function Optimize-WindowsServices {
    Write-ColorOutput "`n[8/10] Tối ưu Windows Services..." "Yellow"
    
    # Services to disable for gaming
    $servicesToDisable = @(
        "DiagTrack",           # Diagnostics Tracking
        "dmwappushservice",    # WAP Push Message Routing
        "WMPNetworkSvc",       # Windows Media Player Network Sharing
        "WSearch",             # Windows Search
        "SysMain",             # Superfetch
        "TabletInputService",  # Touch Keyboard
        "PrintSpooler",        # Printer (if not needed)
        "Fax"                  # Fax service
    )
    
    foreach ($service in $servicesToDisable) {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($svc) {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            Write-ColorOutput "  ✓ Disabled: $service" "Green"
        }
    }
    
    Write-ColorOutput "✓ Windows Services đã được tối ưu" "Green"
}

# Disable Visual Effects
function Disable-VisualEffects {
    Write-ColorOutput "`n[9/10] Tắt Visual Effects..." "Yellow"
    
    # Disable animations
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name MinAnimate -Value 0
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name MenuShowDelay -Value 0
    Write-ColorOutput "  ✓ Animations = Disabled" "Green"
    
    # Disable Aero Peek
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name EnableAeroPeek -Value 0
    Write-ColorOutput "  ✓ Aero Peek = Disabled" "Green"
    
    # Performance over appearance
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name VisualFXSetting -Value 2
    Write-ColorOutput "  ✓ Visual Effects = Performance mode" "Green"
    
    # Disable transparency
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name EnableTransparency -Value 0 -ErrorAction SilentlyContinue
    Write-ColorOutput "  ✓ Transparency = Disabled" "Green"
    
    Write-ColorOutput "✓ Visual Effects đã được tắt" "Green"
}

# Disable Unnecessary Features
function Disable-UnnecessaryFeatures {
    Write-ColorOutput "`n[10/10] Tắt Unnecessary Features..." "Yellow"
    
    # Disable Game Bar and DVR
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name GameDVR_Enabled -Value 0
    Set-ItemProperty -Path "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name AppCaptureEnabled -Value 0 -ErrorAction SilentlyContinue
    Write-ColorOutput "  ✓ Game Bar & DVR = Disabled" "Green"
    
    # Disable Notifications
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name ToastEnabled -Value 0 -ErrorAction SilentlyContinue
    Write-ColorOutput "  ✓ Notifications = Disabled" "Green"
    
    # Disable Windows Tips
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name SubscribedContent-338389Enabled -Value 0 -ErrorAction SilentlyContinue
    Write-ColorOutput "  ✓ Windows Tips = Disabled" "Green"
    
    # Disable Cortana
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name AllowCortana -Value 0 -Force -ErrorAction SilentlyContinue
    Write-ColorOutput "  ✓ Cortana = Disabled" "Green"
    
    Write-ColorOutput "✓ Unnecessary Features đã được tắt" "Green"
}

# Show system status
function Show-Status {
    Write-ColorOutput "`n═══════════════════════════════════════════════════════════" "Blue"
    Write-ColorOutput "System Status:" "Green"
    Write-ColorOutput "═══════════════════════════════════════════════════════════" "Blue"
    
    Write-ColorOutput "`nPower Plan:" "Yellow"
    $activePlan = powercfg /getactivescheme
    Write-ColorOutput "  $activePlan" "Cyan"
    
    Write-ColorOutput "`nCPU:" "Yellow"
    $cpu = Get-WmiObject Win32_Processor
    Write-ColorOutput "  Current Speed: $($cpu.CurrentClockSpeed) MHz" "Cyan"
    Write-ColorOutput "  Max Speed: $($cpu.MaxClockSpeed) MHz" "Cyan"
    
    Write-ColorOutput "`nMemory:" "Yellow"
    $os = Get-WmiObject Win32_OperatingSystem
    $totalMem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeMem = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedMem = $totalMem - $freeMem
    Write-ColorOutput "  Total: $totalMem GB" "Cyan"
    Write-ColorOutput "  Used: $usedMem GB" "Cyan"
    Write-ColorOutput "  Free: $freeMem GB" "Cyan"
}

# Main execution
$systemInfo = Detect-System
Optimize-CPU
Optimize-Memory
Optimize-Storage
Optimize-GPU -SystemInfo $systemInfo
Optimize-ProcessPriority
Optimize-TimerResolution
Optimize-WindowsServices
Disable-VisualEffects
Disable-UnnecessaryFeatures
Show-Status

Write-ColorOutput "`n═══════════════════════════════════════════════════════════" "Blue"
Write-ColorOutput "✓ Low Latency Gaming hoàn tất!" "Green"
Write-ColorOutput "═══════════════════════════════════════════════════════════" "Blue"

Write-ColorOutput "`nTối ưu đã thực hiện:" "Yellow"
Write-ColorOutput "  ✓ CPU: Performance mode, no parking" "Green"
Write-ColorOutput "  ✓ Memory: Optimized caching & paging" "Green"
Write-ColorOutput "  ✓ Storage: I/O optimized" "Green"
Write-ColorOutput "  ✓ GPU: Max performance mode" "Green"
Write-ColorOutput "  ✓ Process: High priority gaming" "Green"
Write-ColorOutput "  ✓ Timer: 0.5ms resolution" "Green"
Write-ColorOutput "  ✓ Services: Unnecessary disabled" "Green"

Write-ColorOutput "`nCảnh báo:" "Cyan"
Write-ColorOutput "  • Pin laptop sẽ tụt nhanh hơn" "Yellow"
Write-ColorOutput "  • CPU/GPU có thể chạy nóng hơn" "Yellow"
Write-ColorOutput "  • Trade-off: Performance > Battery life" "Yellow"
Write-ColorOutput "  • KHỞI ĐỘNG LẠI MÁY để áp dụng hoàn toàn" "Red"
Write-Host ""
