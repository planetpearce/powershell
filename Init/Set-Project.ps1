<#
.PARAMETER Alias
    vsp
.PARAMETER Description
    Discovers .sln and .slnx solution files in the directory tree, presents an interactive selection menu, and opens the chosen solution in Visual Studio.
#>
function Set-Project {
    [CmdletBinding()] param([string]$Filter = "", [string]$Path = $PWD.Path)

    function Get-IndexLetter ($num) {
        $chars = "abcdefghijklmnopqrstuvwxyz"; $res = ""
        do { $res = $chars[$num % 26] + $res; $num = [math]::Floor($num / 26) - 1 } while ($num -ge 0)
        return $res
    }
    function Get-LetterIndex ($str) {
        $chars = "abcdefghijklmnopqrstuvwxyz"; $num = 0
        for ($i = 0; $i -lt $str.Length; $i++) { $num = $num * 26 + $chars.IndexOf($str[$i]); if ($i -lt $str.Length - 1) { $num++ } }
        return $num
    }

    $currPath = $Path; $slnFiles = @()
    while ($true) {
        if (-not (Test-Path $currPath)) { Write-Error "Path does not exist: $currPath"; return }
        if ((Get-Volume -DriveLetter ([System.IO.Path]::GetPathRoot($currPath).TrimEnd(':\'))).FileSystemType -ne "ReFS") {
            Write-Host "[DevDrive Note] Repository not on ReFS partition." -ForegroundColor DarkYellow
        }
        Write-Host "Searching in: $currPath..." -ForegroundColor Gray
        $slnFiles = gci -Path $currPath -Filter *.sln* -File -Recurse -EA SilentlyContinue | ? { ($_.Extension -eq '.sln' -or $_.Extension -eq '.slnx') -and ($_.FullName -notmatch '\\(node_modules|\.git|bin|obj)\\') }
        
        # FIX: The fallback walk-up loop is now strictly limited to the current folder level ($currPath)
        # This prevents it from accidentally re-finding solutions in BikiniMain when you are trying to climb out!
        if ($slnFiles.Count -eq 0) {
            $f = gci -Path $currPath -Filter *.sln* -File | ? { $_.Extension -eq '.sln' -or $_.Extension -eq '.slnx' } | select -First 1
            if ($f) { $slnFiles = @($f) }
        }
        if ($slnFiles.Count -gt 0) { break }
        
        Write-Warning "No solution (.sln/.slnx) found."
        Write-Host "Press [↑ Up Arrow] to climb higher, or any other key to exit." -ForegroundColor Yellow
        if ((([Console]::ReadKey($true)).Key -eq "UpArrow") -and ($p = Split-Path $currPath -Parent)) { $currPath = $p; continue } else { return }
    }


    $slnFile = if ($slnFiles.Count -gt 1) {
        Write-Host "`nMultiple solutions found:" -ForegroundColor Yellow
        for ($i=0; $i -lt $slnFiles.Count; $i++) {
            # FIX: Get the clean full directory path and file name explicitly
            $fullDir = $slnFiles[$i].DirectoryName
            $fileName = $slnFiles[$i].Name
            
            Write-Host "[$(Get-IndexLetter $i)] " -NoNewline -ForegroundColor Green
            if ($fullDir) { Write-Host "$fullDir\" -NoNewline -ForegroundColor DarkGray }
            Write-Host "$fileName" -ForegroundColor Cyan
        }
        Write-Host "[↑ Up Arrow] Scan Parent Root`n[Space] Go to Search Root  [Esc] Quit`n" -ForegroundColor Yellow
        Write-Host "Select letter or ↑: " -NoNewline; $k = [Console]::ReadKey($true)
        if ($k.Key -eq "UpArrow") { Set-Project -Filter $Filter -Path (Split-Path $currPath -Parent); return }
        if ($k.Key -eq "Spacebar") { Set-Location $currPath; return }
        if ($k.Key -eq "Escape") { Write-Host "Cancelled."; return }
        $idx = Get-LetterIndex $k.KeyChar.ToString().ToLower()
        if ($idx -ge 0 -and $idx -lt $slnFiles.Count) { $slnFiles[$idx] } else { Write-Warning "Invalid."; return }
    } else { $slnFiles }


    Write-Host "`nParsing: $($slnFile.Name)" -ForegroundColor Cyan; $projPaths = @()
    if ($slnFile.Extension -eq '.slnx') {
        ([xml](gc $slnFile.FullName)).SelectNodes("//Project[@Path]") | % {
            if (Test-Path ($fp = Join-Path $slnFile.DirectoryName ($_.Path -replace '/', '\'))) { $projPaths += [System.IO.Path]::GetDirectoryName($fp) }
        }
    }
    else {
        gc $slnFile.FullName | % { if ($_ -match 'Project\("[^"]*"\)\s*=\s*"[^"]*",\s*"([^"]*)"') {
                if (($p = $Matches -replace '/', '\') -like "*.*proj" -and (Test-Path ($fp = Join-Path $slnFile.DirectoryName $p))) { $projPaths += [System.IO.Path]::GetDirectoryName($fp) }
            } }
    }
    $projPaths = $projPaths | select -Unique | Sort { Split-Path $_ -Leaf }
    if (-not [string]::IsNullOrWhiteSpace($Filter)) { $projPaths = $projPaths | ? { (Split-Path $_ -Leaf) -like "*$Filter*" } }

    if ($projPaths.Count -eq 0) {
        Write-Warning "No matching projects."
        Write-Host "Press [↑ Up Arrow] to clear filter and scan parent, or any key to exit." -ForegroundColor Yellow
        if (([Console]::ReadKey($true)).Key -eq "UpArrow") { Set-Project -Filter "" -Path (Split-Path $slnFile.DirectoryName -Parent) }; return
    }
    if ($projPaths.Count -eq 1) { Set-Location $projPaths; return }

    Write-Host "`nSelect project directory:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $projPaths.Count; $i++) {
        Write-Host "[$(Get-IndexLetter $i)] " -NoNewline -ForegroundColor Green; Write-Host "$(Split-Path $projPaths[$i] -Leaf) " -NoNewline -ForegroundColor White; Write-Host "($($projPaths[$i]))" -ForegroundColor DarkGray
    }
    Write-Host "[↑ Up Arrow] Scan Parent Root`n[Space] Go to Solution Root  [Esc] Quit`n" -ForegroundColor Yellow
    
        Write-Host "Press letter or ↑: " -NoNewline; $k = [Console]::ReadKey($true)
    
    # FIX: Pressing UP here now escapes this solution's projects 
    # and climbs one level higher than your current search location ($currPath)
    if ($k.Key -eq "UpArrow") { 
        $parentDir = Split-Path $currPath -Parent
        Write-Host "`nClimbing up to search: $parentDir" -ForegroundColor Yellow
        Set-Project -Filter $Filter -Path $parentDir
        return 
    }
    
    if ($k.Key -eq "Spacebar") { Set-Location $slnFile.DirectoryName; return }
    if ($k.Key -eq "Escape") { Write-Host "Cancelled."; return }

    
    $idx = Get-LetterIndex $k.KeyChar.ToString().ToLower()
    if ($idx -ge 0 -and $idx -lt $projPaths.Count) { Set-Location $projPaths[$idx] } else { Write-Warning "Invalid selection." }
}
