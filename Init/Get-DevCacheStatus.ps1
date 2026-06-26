function Get-DevCacheStatus {
    [CmdletBinding()]
    param()

    # 1. Target your exact high-traffic Dev Drive caching paths
    # Perfectly aligned to monitor your real-time compiler outputs
    $CachePaths = [ordered]@{
        "Resharper Caches" = "D:\ResharperCaches"
        "NuGet Packages"   = "D:\.nuget\packages"
        "MSBuild Metadata" = "D:\MSBuild\Caches"
        "Roslyn Compiles"  = "D:\MSBuild\VBCSCompiler"
        "NuGet Scratch"    = "D:\MSBuild\NuGetScratch"
    }


    Write-Host "`n⚡ Dev Drive Transient Cache Allocation:" -ForegroundColor Cyan

    foreach ($Name in $CachePaths.Keys) {
        $TargetPath = $CachePaths[$Name]
        
        if (Test-Path $TargetPath) {
            # Use high-speed .NET file enumeration to keep shell boots fast
            try {
                $DirInfo = [System.IO.Directory]::EnumerateFiles($TargetPath, "*", [System.IO.SearchOption]::AllDirectories)
                $TotalSize = 0
                $FileCount = 0
                
                foreach ($File in $DirInfo) {
                    $TotalSize += (New-Object System.IO.FileInfo($File)).Length
                    $FileCount++
                }

                $SizeGB = [math]::Round($TotalSize / 1GB, 2)
                $SizeMB = [math]::Round($TotalSize / 1MB, 1)
                
                $DisplaySize = if ($SizeGB -ge 1) { "$SizeGB GB" } else { "$SizeMB MB" }
                
                Write-Host "   • $($Name.PadRight(18)) : " -NoNewline; Write-Host "$DisplaySize " -ForegroundColor White -NoNewline; Write-Host "($FileCount files)" -ForegroundColor DarkGray
            }
            catch {
                Write-Host "   • $($Name.PadRight(18)) : " -NoNewline; Write-Host "Size Calculation Blocked 🔒" -ForegroundColor Yellow
            }
        } else {
            Write-Host "   • $($Name.PadRight(18)) : " -NoNewline; Write-Host "Empty / Not Initialized 🍃" -ForegroundColor DarkGray
        }
    }
}
