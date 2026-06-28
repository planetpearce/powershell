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
    Write-Host "    | |__) || |  __ _  _ __   ___| |_  | |__) |___  __ _  _ __ ___ ___  " -ForegroundColor $blue
    Write-Host "    |  ___/ | | / _\` || '_ \ / _ \ __| |  ___// _ \/ _\` || '__/ __/ _ \ " -ForegroundColor $pink
    Write-Host "    | |     | || (_| || | | |  __/ |_  | |   |  __/ (_| || | | (_|  __/ " -ForegroundColor $pink
    Write-Host "    |_|     |_| \__,_||_| |_|\___|\__| |_|    \___|\__,_||_|  \___\___| " -ForegroundColor $pink
    Write-Host ""
    Write-Host "                         🛰️ ORBITING: " -NoNewline -ForegroundColor $gray
    Write-Host "PLANET PEARCE" -ForegroundColor $blue
    Write-Host "                         🌑 SYSTEM:   " -NoNewline -ForegroundColor $gray
    Write-Host "VIOLETTA" -ForegroundColor $pink
    Write-Host " -----------------------------------------------------------------------`n" -ForegroundColor $gray
}

# Helper function to inject paths cleanly without array nesting bugs
function Inject-UniquePath {
    param(
        [Parameter(Mandatory=$true)][string]$EnvironmentVariable,
        [Parameter(Mandatory=$true)][string]$TargetDirectory
    )
    if (Test-Path $TargetDirectory) {
        # Dynamically retrieve the environment variable string value
        $CurrentRaw   = (Get-Item "Env:\$EnvironmentVariable").Value
        $CurrentPaths = $CurrentRaw -split [IO.Path]::PathSeparator
        
        # Filter out empty entries and any existing copies of our target path
        $CleanPaths   = $CurrentPaths | Where-Object { $_ -and $_ -ne $TargetDirectory }
        
        # Flatten the elements by combining them into a single-layer array
        $FlatArray    = @($TargetDirectory) + $CleanPaths
        
        # Join the flattened paths back together with the proper system separator
        $NewValue     = $FlatArray -join [IO.Path]::PathSeparator
        
        # Update the global environment profile variable
        Set-Item "Env:\$EnvironmentVariable" -Value $NewValue
    }
}

# Safely inject your Dev Drive paths to the absolute front of the stack
Inject-UniquePath -EnvironmentVariable "PSModulePath" -TargetDirectory "D:\PowerShell\Modules"
Inject-UniquePath -EnvironmentVariable "Path"         -TargetDirectory "D:\PowerShell\Scripts"

# Clean up the helper function so it doesn't clutter your session global scope
Remove-Item Function:\Inject-UniquePath

# Redirect ALL temporary compilation, MSBuild, and Roslyn artifacts to the Dev Drive
$env:TEMP = "D:\MSBuild"
$env:TMP  = "D:\MSBuild"

# Ensure the base compiler temp directory exists
if (-not (Test-Path "D:\MSBuild")) {
    # 🏎️ OPTIMIZATION: Swapped pipeline piping out for high-speed $null mapping assignments
    $null = New-Item -ItemType Directory -Path "D:\MSBuild" -Force
}

. "D:/PowerShell/Init-Logs.ps1"
. "D:/PowerShell/Init-Functions.ps1"

# Standard Operational Environment Aliases
Set-Alias ..   cd..
Set-Alias la   Get-AllFiles
Set-Alias lr   Get-RecursiveList
Set-Alias lss  Get-SortedBySize
Set-Alias ldu  Get-DirSize

# Visual Terminal On-Boot Dashboard Menu
# 🟢 FIXED: Extracted raw character code leaks and repaired spelling typography tokens
Write-Host "👨‍🚀 Orbit Stabilized" -ForegroundColor Cyan
Write-Host
