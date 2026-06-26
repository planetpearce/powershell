<#
.PARAMETER Alias
    ll
.PARAMETER Description
    Linux-style listing helpers: ll (long), la (show hidden), lr (recursive), lss (sort by size), ldu (dir sizes).
#>

function Format-FileSize {
    param([long]$Bytes)
    if     ($Bytes -ge 1GB) { '{0,7:N1} GB' -f ($Bytes / 1GB) }
    elseif ($Bytes -ge 1MB) { '{0,7:N1} MB' -f ($Bytes / 1MB) }
    elseif ($Bytes -ge 1KB) { '{0,7:N1} KB' -f ($Bytes / 1KB) }
    else                    { '{0,7} B ' -f $Bytes }
}

# ll — long listing with human-readable sizes
function Get-LongList {
    [CmdletBinding()]
    param([string]$Path = '.')
    Get-ChildItem -LiteralPath $Path | ForEach-Object {
        [PSCustomObject]@{
            Mode     = $_.Mode
            Modified = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
            Size     = if ($_.PSIsContainer) { '    <DIR>' } else { Format-FileSize $_.Length }
            Name     = $_.Name
        }
    } | Format-Table -AutoSize
}

# la — long listing including hidden and system files
function Get-AllFiles {
    [CmdletBinding()]
    param([string]$Path = '.')
    Get-ChildItem -LiteralPath $Path -Force | ForEach-Object {
        [PSCustomObject]@{
            Mode     = $_.Mode
            Modified = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
            Size     = if ($_.PSIsContainer) { '    <DIR>' } else { Format-FileSize $_.Length }
            Name     = $_.Name
        }
    } | Format-Table -AutoSize
}

# lr — recursive flat listing with relative paths
function Get-RecursiveList {
    [CmdletBinding()]
    param([string]$Path = '.')
    $Base = (Resolve-Path $Path).Path.TrimEnd('\') + '\'
    Get-ChildItem -LiteralPath $Path -Recurse | ForEach-Object {
        [PSCustomObject]@{
            Mode     = $_.Mode
            Modified = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
            Size     = if ($_.PSIsContainer) { '    <DIR>' } else { Format-FileSize $_.Length }
            Path     = $_.FullName.Replace($Base, '')
        }
    } | Format-Table -AutoSize
}

# lss — files sorted by size, largest first
function Get-SortedBySize {
    [CmdletBinding()]
    param([string]$Path = '.')
    Get-ChildItem -LiteralPath $Path -File |
        Sort-Object Length -Descending |
        ForEach-Object {
            [PSCustomObject]@{
                Size     = Format-FileSize $_.Length
                Modified = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
                Name     = $_.Name
            }
        } | Format-Table -AutoSize
}

# ldu — total recursive size per item, sorted largest first (like du -sh *)
function Get-DirSize {
    [CmdletBinding()]
    param([string]$Path = '.')
    Get-ChildItem -LiteralPath $Path | ForEach-Object {
        $Bytes = if ($_.PSIsContainer) {
            (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue |
             Measure-Object -Property Length -Sum).Sum
        } else { $_.Length }
        if ($null -eq $Bytes) { $Bytes = 0 }
        [PSCustomObject]@{ Bytes = $Bytes; Type = if ($_.PSIsContainer) { 'dir' } else { 'file' }; Name = $_.Name }
    } | Sort-Object Bytes -Descending | ForEach-Object {
        [PSCustomObject]@{
            Size = Format-FileSize $_.Bytes
            Type = $_.Type
            Name = $_.Name
        }
    } | Format-Table -AutoSize
}
