#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Network Performance Tester
.DESCRIPTION
    Test ping, jitter, and packet loss after optimization
#>

$ErrorActionPreference = "SilentlyContinue"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    $colors = @{"Red" = "Red"; "Green" = "Green"; "Yellow" = "Yellow"; "Blue" = "Cyan"; "Cyan" = "Cyan"; "Magenta" = "Magenta"}
    Write-Host $Message -ForegroundColor $colors[$Color]
}

Write-ColorOutput "╔═══════════════════════════════════════════════════════════╗" "Blue"
Write-ColorOutput "║   NETWORK PERFORMANCE TESTER                              ║" "Green"
Write-ColorOutput "╚═══════════════════════════════════════════════════════════╝" "Blue"

# Test servers
$testServers = @(
    @{Name="Google DNS"; IP="8.8.8.8"},
    @{Name="Cloudflare"; IP="1.1.1.1"},
    @{Name="Singapore"; IP="103.28.152.1"}
)

Write-ColorOutput "`n🌐 Testing network performance..." "Yellow"
Write-ColorOutput "This will take about 30 seconds...`n" "Cyan"

foreach ($server in $testServers) {
    Write-ColorOutput "═══════════════════════════════════════════════════════════" "Blue"
    Write-ColorOutput "Testing: $($server.Name) ($($server.IP))" "Yellow"
    Write-ColorOutput "═══════════════════════════════════════════════════════════" "Blue"
    
    # Ping test
    $pingResults = Test-Connection -ComputerName $server.IP -Count 50 -ErrorAction SilentlyContinue
    
    if ($pingResults) {
        # Calculate statistics
        $responseTimes = $pingResults | Where-Object {$_.ResponseTime -ne $null} | Select-Object -ExpandProperty ResponseTime
        
        $avgPing = ($responseTimes | Measure-Object -Average).Average
        $minPing = ($responseTimes | Measure-Object -Minimum).Minimum
        $maxPing = ($responseTimes | Measure-Object -Maximum).Maximum
        $jitter = $maxPing - $minPing
        
        # Packet loss
        $sent = 50
        $received = $responseTimes.Count
        $packetLoss = (($sent - $received) / $sent) * 100
        
        # Display results
        Write-ColorOutput "`n📊 Results:" "Yellow"
        Write-ColorOutput "  Average Ping: $([math]::Round($avgPing, 2)) ms" "White"
        Write-ColorOutput "  Min Ping: $minPing ms" "White"
        Write-ColorOutput "  Max Ping: $maxPing ms" "White"
        Write-ColorOutput "  Jitter: $jitter ms" "White"
        Write-ColorOutput "  Packet Loss: $([math]::Round($packetLoss, 2))%" "White"
        
        # Evaluation
        Write-ColorOutput "`n✅ Evaluation:" "Yellow"
        
        # Ping evaluation
        if ($avgPing -lt 30) {
            Write-ColorOutput "  Ping: EXCELLENT (< 30ms)" "Green"
        } elseif ($avgPing -lt 50) {
            Write-ColorOutput "  Ping: GOOD (30-50ms)" "Green"
        } elseif ($avgPing -lt 100) {
            Write-ColorOutput "  Ping: ACCEPTABLE (50-100ms)" "Yellow"
        } else {
            Write-ColorOutput "  Ping: POOR (> 100ms)" "Red"
        }
        
        # Jitter evaluation
        if ($jitter -lt 5) {
            Write-ColorOutput "  Jitter: EXCELLENT (< 5ms)" "Green"
        } elseif ($jitter -lt 15) {
            Write-ColorOutput "  Jitter: GOOD (5-15ms)" "Green"
        } elseif ($jitter -lt 30) {
            Write-ColorOutput "  Jitter: ACCEPTABLE (15-30ms)" "Yellow"
        } else {
            Write-ColorOutput "  Jitter: POOR (> 30ms)" "Red"
        }
        
        # Packet loss evaluation
        if ($packetLoss -eq 0) {
            Write-ColorOutput "  Packet Loss: EXCELLENT (0%)" "Green"
        } elseif ($packetLoss -lt 1) {
            Write-ColorOutput "  Packet Loss: GOOD (< 1%)" "Green"
        } elseif ($packetLoss -lt 3) {
            Write-ColorOutput "  Packet Loss: ACCEPTABLE (1-3%)" "Yellow"
        } else {
            Write-ColorOutput "  Packet Loss: POOR (> 3%)" "Red"
        }
        
        Write-Host ""
        
    } else {
        Write-ColorOutput "  ✗ Could not connect to $($server.Name)" "Red"
    }
}

# Final summary
Write-ColorOutput "═══════════════════════════════════════════════════════════" "Blue"
Write-ColorOutput "Test completed!" "Green"
Write-ColorOutput "═══════════════════════════════════════════════════════════" "Blue"

Write-ColorOutput "`n💡 Tips:" "Yellow"
Write-ColorOutput "  • If ping is high, check your ISP/Router" "White"
Write-ColorOutput "  • If jitter is high, run Anti-Bufferbloat.ps1" "White"
Write-ColorOutput "  • If packet loss is high, run Anti-WhiteBullet.ps1" "White"
Write-ColorOutput "  • Use Ethernet instead of Wi-Fi for best results" "White"
Write-ColorOutput "  • Close background downloads/uploads" "White"

# Network adapter info
Write-ColorOutput "`n🔌 Network Adapters:" "Yellow"
Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Format-Table Name, InterfaceDescription, LinkSpeed, Status -AutoSize

Write-ColorOutput "`n✅ Recommended ping for gaming:" "Cyan"
Write-ColorOutput "  FPS Games (CS:GO, Valorant): < 30ms" "White"
Write-ColorOutput "  MOBA (LoL, Dota 2): < 50ms" "White"
Write-ColorOutput "  MMO/RPG: < 100ms" "White"

Write-Host ""
