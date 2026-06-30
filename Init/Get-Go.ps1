<#
.PARAMETER Alias
    go
.PARAMETER Description
    Smart navigation hub for jumping to bookmarked directories, git repositories, and web URLs. Accepts an optional fuzzy filter argument.
#>
function Get-Go {
    [CmdletBinding()]
    param([Parameter(Mandatory = $false, ValueFromRemainingArguments = $true)][string[]]$FilterArgs)

    # 1. Fully unified saved paths, system directories, web macros, and workspaces
    $StaticBookmarks = [ordered]@{
        "Core User Folders"          = [ordered]@{
            "home" = "$HOME"
            "dt"   = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders").Desktop
            "docs" = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders").Personal
            "pics" = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders")."My Pictures"
            "dl"   = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders")."{374DE290-123F-4565-9164-39C4925E467B}"
        }
        "Web Macros"                 = [ordered]@{
            "emojis" = "https://emojipedia.org"
            "azure"  = "https://portal.azure.com"
            "bs"     = "https://getbootstrap.com/docs/5.3/utilities/vertical-align"
            "icons"  = "https://icons.getbootstrap.com"
        }
        "AppData & Developer Caches" = [ordered]@{
            "local"     = "$env:LOCALAPPDATA"
            "roaming"   = "$env:APPDATA"
            "locallow"  = "$env:USERPROFILE\AppData\LocalLow"
            "resharper" = "$env:LOCALAPPDATA\JetBrains\Transient"
            "nuget"     = "$env:NUGET_PACKAGES"
        }
        "System Admin & Logs"        = [ordered]@{
            "winlogs" = "C:\Windows\System32\Winevt\Logs"
            "hosts"   = "C:\Windows\System32\drivers\etc"
            "ssh"     = "$env:USERPROFILE\.ssh"
        }
        "PowerShell Control Center"  = [ordered]@{
            "ps"      = "D:\PowerShell"
            "modules" = "D:\PowerShell\Modules"
            "scripts" = "D:\PowerShell\Scripts"
            "init"      = "D:\PowerShell\Init"
            "do"        = "D:\repos\Bikini\BikiniGit\dev-ops"
            "templates" = "D:\PowerShell\Templates"
        }
    }

    # Flatten groups into a single ordered lookup table
    $FlatBookmarks = [ordered]@{}
    foreach ($group in $StaticBookmarks.Values) {
        foreach ($key in $group.Keys) { $FlatBookmarks[$key] = $group[$key] }
    }

    $PathMappings = [ordered]@{
       
        "bikini" = "D:\repos\bikini\bikinigit\bikinimain"
        "core"   = "D:\repos\Bikini\BikiniGit\CorePackages"        
        "pp"     = "D:\repos\PlanetPearce"
        "bw"     = "D:\repos\Blackwood Website"
        "repos"  = "D:\repos"
    }

    $TargetKey = $null; $RemainingFilter = @()

    # 2. Process command line direct bypass execution arguments
    if ($FilterArgs.Count -gt 0) {
        $FirstArg = $FilterArgs[0].ToLower()
        if ($FlatBookmarks.Contains($FirstArg)) {
            $target = $FlatBookmarks[$FirstArg]
            if ($target -like "http*") { Start-Process $target; return }
            if (Test-Path $target -PathType Leaf) { $target = Split-Path $target -Parent }
            Set-Location $target; return
        }
        if ($PathMappings.Contains($FirstArg)) {
            $TargetKey = $FirstArg; $RemainingFilter = $FilterArgs[1..($FilterArgs.Count - 1)]
        }
        else {
            $RemainingFilter = $FilterArgs
        }
    }

    # 3. Render Interactive Key Selection Dashboard
    if (-not $TargetKey) {
        $bKeys = @($FlatBookmarks.Keys); $wKeys = @($PathMappings.Keys)
        
        # Generates a-z, aa-zz index scaling natively
        function Get-MenuLetter ($num) {
            $chars = "abcdefghijklmnopqrstuvwxyz"; $res = ""
            do { $res = $chars[$num % 26] + $res; $num = [math]::Floor($num / 26) - 1 } while ($num -ge 0)
            return $res
        }
        function Get-MenuIndex ($str) {
            $chars = "abcdefghijklmnopqrstuvwxyz"; $num = 0
            for ($i = 0; $i -lt $str.Length; $i++) { $num = $num * 26 + $chars.IndexOf($str[$i]); if ($i -lt $str.Length - 1) { $num++ } }
            return $num
        }

        # Display static bookmarks grouped by topic
        if ($bKeys.Count -gt 0) {
            $letterIdx = 0
            foreach ($groupName in $StaticBookmarks.Keys) {
                Write-Host "`n  $groupName" -ForegroundColor Cyan
                foreach ($key in $StaticBookmarks[$groupName].Keys) {
                    Write-Host "  [$(Get-MenuLetter $letterIdx)] " -NoNewline -ForegroundColor Green
                    Write-Host "$($key.PadRight(10)) " -NoNewline -ForegroundColor White
                    Write-Host "($($FlatBookmarks[$key]))" -ForegroundColor DarkGray
                    $letterIdx++
                }
            }
        }

        # Display target workspaces underneath using numbers
        Write-Host "`nTarget Workspaces:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $wKeys.Count; $i++) {
            Write-Host "[$($i + 1)] " -NoNewline -ForegroundColor Green
            Write-Host "$($wKeys[$i].PadRight(10)) " -NoNewline -ForegroundColor White
            Write-Host "($($PathMappings[$wKeys[$i]]))" -ForegroundColor DarkGray
        }
        Write-Host "[Space/Esc] Cancel / Quit`n" -ForegroundColor Red

        Write-Host "Press hotkey: " -NoNewline; $KeyInfo = [Console]::ReadKey($true)
        if ($KeyInfo.Key -eq "Escape" -or $KeyInfo.Key -eq "Spacebar") { Write-Host "Cancelled."; return }
        $Selection = $KeyInfo.KeyChar.ToString().ToLower()
        Write-Host $Selection -ForegroundColor White

        # Route 1: Handle letter selection mapping for static bookmarks
        if ($Selection -match '^[a-z]+$') {
            $bIndex = Get-MenuIndex $Selection
            if ($bIndex -ge 0 -and $bIndex -lt $bKeys.Count) {
                $target = $FlatBookmarks[$bKeys[$bIndex]]
                if ($target -like "http*") { Start-Process $target; return }
                if (Test-Path $target -PathType Leaf) { $target = Split-Path $target -Parent }
                Set-Location $target; return
            }
        }

        # Route 2: Handle number selection mapping for primary workspaces
        $Index = 0
        if ([int]::TryParse($Selection, [ref]$Index)) {
            $ActualIndex = $Index - 1
            if ($ActualIndex -ge 0 -and $ActualIndex -lt $wKeys.Count) { $TargetKey = $wKeys[$ActualIndex] }
        }

        if (-not $TargetKey) { Write-Warning "Invalid selection."; return }
    }

    Set-Project -Filter ($RemainingFilter -join " ") -Path $PathMappings[$TargetKey]
}
