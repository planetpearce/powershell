<#
.PARAMETER Description
    Safely deletes bin, obj, and .vs build artifacts under verified project footprints. Supports -Deep flag to also flush the local NuGet package cache.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$Path = $PWD.Path,
    
    [Parameter(Mandatory=$false)]
    [switch]$Deep
)

Write-Host "`n🧹 Initializing Safe Target Purge in: $Path" -ForegroundColor Cyan

# 1. Broadly target intermediate directory candidates
$Candidates = Get-ChildItem -Path $Path -Directory -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -eq 'bin' -or $_.Name -eq 'obj' -or $_.Name -eq '.vs' }

$Targets = @()

# 2. Safety Validator: Confirm the candidate belongs to an actual development project
foreach ($Dir in $Candidates) {
    $ParentDir = Split-Path $Dir.FullName -Parent
    
    # Check for visual studio solutions or project file footprints nearby
    $HasProjectFootprint = Get-ChildItem -Path $ParentDir -File -ErrorAction SilentlyContinue | 
        Where-Object { $_.Extension -match '\.[c|f|v]sproj$' -or $_.Extension -eq '.sln' -or $_.Extension -eq '.slnx' }
        
    if ($HasProjectFootprint) {
        $Targets += $Dir
    } else {
        # Log skipped modules or system items silently in gray
        Write-Host "   [SAFE SKIP] Ignored isolated path: $($Dir.FullName)" -ForegroundColor DarkGray
    }
}

# 3. Add Deep Clean global NuGet cache target safely if flagged
if ($Deep -and $env:NUGET_PACKAGES -and (Test-Path $env:NUGET_PACKAGES)) {
    Write-Host "📦 Deep Clean Flag Enabled: Targeting Global NuGet Staging Cache..." -ForegroundColor DarkCyan
    $Targets += Get-Item -Path $env:NUGET_PACKAGES
}

if ($Targets.Count -eq 0) {
    Write-Host "✨ Workspace is completely clean. No valid project build directories found." -ForegroundColor Green
    return
}

Write-Host "🔍 Found $($Targets.Count) valid project targets to destroy..." -ForegroundColor Yellow

# 4. Final Purge Loop
$LockedCount = 0
foreach ($Folder in $Targets) {
    if ($PSCmdlet.ShouldProcess($Folder.FullName, "Delete Project Build Directories")) {
        try {
            Remove-Item -Path $Folder.FullName -Recurse -Force -ErrorAction Stop
            Write-Host "   [WIPED] $($Folder.FullName)" -ForegroundColor Gray
        }
        catch {
            Write-Host "   [LOCKED] Could not delete $($Folder.FullName) (File lock active)" -ForegroundColor Red
            $LockedCount++
        }
    }
}

Write-Host "`n✓ Safe Cleanup Complete!" -ForegroundColor Green
if ($LockedCount -gt 0) {
    Write-Warning "[$LockedCount] folders were locked by active IDE/Roslyn processes."
}
