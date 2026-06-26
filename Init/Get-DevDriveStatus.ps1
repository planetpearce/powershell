function Get-DevDriveStatus {
    [CmdletBinding()]
    param()

    $Letter = "D"
    $TargetVolume = Get-Volume -DriveLetter $Letter -ErrorAction SilentlyContinue

    Write-Host ""
    if (-not $TargetVolume) {
        Write-Host "⚠️ [DevDrive Alert] Volume ${Letter}: not found or unmounted." -ForegroundColor Red
        return
    }

    if ($TargetVolume.FileSystemType -ne "ReFS") {
        Write-Host "❌ [DevDrive Error] Drive ${Letter}: is using $($TargetVolume.FileSystemType). It MUST be formatted as ReFS for developer optimization." -ForegroundColor Red
        return
    }

    $FreeSpaceGB = [math]::Round($TargetVolume.SizeRemaining / 1GB, 1)
    $TotalSpaceGB = [math]::Round($TargetVolume.Size / 1GB, 1)
    $PercentFree = [math]::Round(($FreeSpaceGB / $TotalSpaceGB) * 100, 1)

    # 1. Native check to verify if the current console process is Elevated (Admin)
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    # 2. Only invoke fsutil if running inside your Elevated Terminal Profile
    $TrustStatus = "Requires Admin Privileges to Query 🔒"
    $Color = "DarkGray"
    $IsTrusted = $false

    if ($IsAdmin) {
        $FsutilPath = "${Letter}:"
        $Query = Invoke-Expression "fsutil devdrv query $FsutilPath" 2>&1
        $IsTrusted = $Query -match "This is a trusted developer volume."
        
        $TrustStatus = if ($IsTrusted) { "Trusted (Async Mode Active) ⚡" } else { "Untrusted (Slow Sync Scanning Active) ⚠️" }
        $Color = if ($IsTrusted) { "Green" } else { "Yellow" }
    }
d
    # 3. Output metrics dashboard block
    Write-Host "📦 Dev Drive Health Status (${Letter}:):" -ForegroundColor Cyan
    Write-Host "   • Storage Capacity: " -NoNewline; Write-Host "$FreeSpaceGB GB free / $TotalSpaceGB GB total ($PercentFree% available)" -ForegroundColor White
    Write-Host "   • Defender Security: " -NoNewline; Write-Host $TrustStatus -ForegroundColor $Color
    
    # Only print the configuration advice if Admin mode is active and the drive is untrusted
    if ($IsAdmin -and -not $IsTrusted) {
        Write-Host "   👉 Note: Run 'fsutil devdrv trust ${Letter}:' in this prompt to activate high-speed trust mode." -ForegroundColor DarkYellow
    }
}