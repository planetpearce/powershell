function Get-Status {
    [CmdletBinding()]
    param()

    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "🖥️  NICK'S CORE DEVELOPMENT ENVIRONMENT DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    # 1. RUN DEV DRIVE INFRASTRUCTURE CHECKS
    if (Get-Command Get-DevDriveStatus -ErrorAction SilentlyContinue) {
        Get-DevDriveStatus
    } else {
        Write-Host "`n📦 Dev Drive Health Status:" -ForegroundColor Cyan
        Write-Host "   • Check-DevDrive.ps1 not initialized in init loop." -ForegroundColor Yellow
    }

    # 2. RUN TRANSIENT FILE CACHE TELEMETRY
    if (Get-Command Get-DevCacheStatus -ErrorAction SilentlyContinue) {
        Get-DevCacheStatus
    }

    # Explicitly calculate npm global cache directory if node exists
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        try {
            $NpmCachePath = (npm config get cache).Trim()
            if (Test-Path $NpmCachePath) {
                $NpmFiles = [System.IO.Directory]::EnumerateFiles($NpmCachePath, "*", [System.IO.SearchOption]::AllDirectories)
                $NpmSize = 0; $NpmCount = 0
                foreach ($f in $NpmFiles) { $NpmSize += (New-Object System.IO.FileInfo($f)).Length; $NpmCount++ }
                $DisplayNpmSize = if ($NpmSize -ge 1GB) { "$([math]::Round($NpmSize / 1GB, 2)) GB" } else { "$([math]::Round($NpmSize / 1MB, 1)) MB" }
                Write-Host "   • npm Global Cache   : " -NoNewline; Write-Host "$DisplayNpmSize " -ForegroundColor White -NoNewline; Write-Host "($NpmCount files)" -ForegroundColor DarkGray
            }
        } catch {
            Write-Host "   • npm Global Cache   : " -NoNewline; Write-Host "Size Calculation Interrupted 🔒" -ForegroundColor Yellow
        }
    }

    # 3. GLOBAL CONFIGURATION DETECTIONS
    Write-Host "`n⚙️  Global Configuration Scopes:" -ForegroundColor Cyan
    $WalkDir = $PWD.Path
    $GlobalJsonFile = $null

    while ($WalkDir) {
        $CheckFile = Join-Path $WalkDir "global.json"
        if (Test-Path $CheckFile) {
            $GlobalJsonFile = Get-Item $CheckFile
            break
        }
        $WalkDir = Split-Path $WalkDir -Parent
    }

    if ($GlobalJsonFile) {
        try {
            $JsonData = Get-Content -Raw $GlobalJsonFile.FullName | ConvertFrom-Json
            $SdkVersion = $JsonData.sdk.version
            if (-not $SdkVersion) { $SdkVersion = "Malformed/Missing version key" }

            Write-Host "   • global.json        : " -NoNewline
            Write-Host "DETECTED 🎯 " -ForegroundColor Green -NoNewline
            Write-Host "[SDK v$SdkVersion] " -ForegroundColor Yellow -NoNewline
            Write-Host "($($GlobalJsonFile.FullName))" -ForegroundColor DarkGray
        }
        catch {
            Write-Host "   • global.json        : " -NoNewline
            Write-Host "DETECTED 🎯 " -ForegroundColor Green -NoNewline
            Write-Host "[JSON Parse Error ❌] " -ForegroundColor Red -NoNewline
            Write-Host "($($GlobalJsonFile.FullName))" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "   • global.json        : " -NoNewline; Write-Host "None active in working tree path 🍃" -ForegroundColor DarkGray
    }

    # 4. RUN SYSTEM SDK & UTILITY FRAMEWORK RUNTIMES
    Write-Host "`n🛠️  Toolchain & Developer SDK Runtimes:" -ForegroundColor Cyan

    # Git Version Check
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $GitVer = (git --version) -replace 'git version ',''
        Write-Host "   • Git Engine Tool    : " -NoNewline; Write-Host "v$GitVer" -ForegroundColor White
    } else {
        Write-Host "   • Git Engine Tool    : " -NoNewline; Write-Host "NOT FOUND ❌" -ForegroundColor Red
    }

    # Node.js & npm Version Checks
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $NodeVer = (node -v) -replace 'v',''
        $HighNpmVer = (npm -v)
        Write-Host "   • Node.js Runtime    : " -NoNewline; Write-Host "v$NodeVer " -ForegroundColor White -NoNewline; Write-Host "(npm v$HighNpmVer)" -ForegroundColor DarkGray
    } else {
        Write-Host "   • Node.js Runtime    : " -NoNewline; Write-Host "NOT FOUND ❌" -ForegroundColor Red
    }

    # .NET SDK Enumeration List & Workload Manifests
    if (Get-Command dotnet -ErrorAction SilentlyContinue) {
        $PrimarySdk = (dotnet --version)
        Write-Host "   • .NET SDK Active    : " -NoNewline; Write-Host "v$PrimarySdk" -ForegroundColor Green
        
        # SDK List
        $DotnetSdks = dotnet --list-sdks
        if ($DotnetSdks) {
            Write-Host "   • Installed .NET SDKs :" -ForegroundColor DarkGray
            foreach ($Sdk in $DotnetSdks) {
                Write-Host "     - $Sdk" -ForegroundColor White
            }
        }

        # FIX: Query and clean parse installed Workload Bundle Manifest assemblies
        try {
            # Extracts lines from workload tool list, discarding header structural garbage
            $Workloads = dotnet workload list | Where-Object { 
                $_ -and $_ -notmatch 'Installed Workload Id' -and $_ -notmatch '^-+$' -and $_ -notmatch 'Use `dotnet workload search`' 
            }
            if ($Workloads) {
                Write-Host "   • Active Workloads    :" -ForegroundColor DarkGray
                foreach ($WL in $Workloads) {
                    # Strip extra whitespace tracking to keep dashboard print tightly aligned
                    $CleanWL = ($WL -replace '\s+', ' ').Trim()
                    Write-Host "     - $CleanWL" -ForegroundColor Gray
                }
            } else {
                Write-Host "   • Active Workloads    : " -NoNewline; Write-Host "None installed / core SDK defaults only 🍃" -ForegroundColor DarkGray
            }
        } catch {
            Write-Host "   • Active Workloads    : " -NoNewline; Write-Host "Query Failed 🔒" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   • .NET SDK Toolchain : " -NoNewline; Write-Host "NOT FOUND ❌" -ForegroundColor Red
    }

    Write-Host "========================================================`n" -ForegroundColor Cyan
}

if (Get-Alias status -ErrorAction SilentlyContinue) { Remove-Item Alias:status }
Set-Alias status Get-Status
