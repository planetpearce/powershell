# =========================================================================
# 🌌 ORBITAL REGISTRY INITIALIZATION (Self-Executing Startup Splash)
# =========================================================================
& {
    # Local variable constraints (Isolated strictly to this block's memory loop)
    $blue = "Cyan"
    $pink = "Magenta"
    $gray = "DarkGray"

    # 🟢 REMOVED: Clear-Host has been deleted so it never wipes out earlier logs!
    
    Write-Host "`n     _____   _                    _     _____                          " -ForegroundColor $blue
    Write-Host "    |  __ \ | |                  | |   |  __ \                         " -ForegroundColor $blue
    Write-Host "    | |__) || |  __ _  _ __   ___| |_  | |__) |___  __ _ _ __ ___ ___  " -ForegroundColor $blue
    Write-Host "    |  ___/ | | / _\` || '_ \ / _ \ __| |  ___// _ \/ _\` || '__/ __/ _ \ " -ForegroundColor $pink
    Write-Host "    | |     | || (_| || | | |  __/ |_  | |   |  __/ (_| || || | (_|  __/ " -ForegroundColor $pink
    Write-Host "    |_|     |_| \__,_||_| |_|\___|\__| |_|    \___|\__,_||_|  \___\___| " -ForegroundColor $pink
    Write-Host ""
    Write-Host "                         🚀 ORBITING: " -NoNewline -ForegroundColor $gray
    Write-Host "PLANET PEARCE" -NoNewline -ForegroundColor $blue
    Write-Host " 🚀" -ForegroundColor $gray
    Write-Host "                         📡 STATION:  " -NoNewline -ForegroundColor $gray
    Write-Host "VIOLETTA" -ForegroundColor $pink
    Write-Host " -----------------------------------------------------------------------`n" -ForegroundColor $gray
}

Write-Host "🚀 Boot Launching" -ForegroundColor Cyan

# Configure Process Environment Paths (Safely handles array formatting)
$env:PSModulePath = "D:\PowerShell\Modules;{0}" -f $env:PSModulePath
$env:Path         = "D:\PowerShell\Scripts;{0}" -f $env:Path

# Redirect ALL temporary compilation, MSBuild, and Roslyn artifacts to the Dev Drive
$env:TEMP = "D:\MSBuild"
$env:TMP  = "D:\MSBuild"

# Ensure the base compiler temp directory exists
if (-not (Test-Path "D:\MSBuild")) {
    # 🏎️ OPTIMIZATION: Swapped pipeline piping out for high-speed $null mapping assignments
    $null = New-Item -ItemType Directory -Path "D:\MSBuild" -Force
}

# Dynamically discover and source all modular initialization files
# 🏎️ OPTIMIZATION: Used native $PSScriptRoot to bypass Split-Path execution loops completely
$InitPath = Join-Path $PSScriptRoot "init"

Write-Host "🔥 Enabling Boosters" -ForegroundColor Cyan
if (Test-Path $InitPath) {
    Get-ChildItem -Path $InitPath -Filter *.ps1 -File | ForEach-Object {
        Write-Host "   ⚡" $_.BaseName -ForegroundColor Gray
        . $_.FullName
    }
}

# Standard Operational Environment Aliases
Set-Alias vsp Set-Project
Set-Alias vst Enable-VS
Set-Alias go  Get-Go

# Visual Terminal On-Boot Dashboard Menu
# 🟢 FIXED: Extracted raw character code leaks and repaired spelling typography tokens
Write-Host "👨‍🚀 Orbit Stabilized" -ForegroundColor Cyan

# Execute your starting repo environment routing hook
Get-Go
