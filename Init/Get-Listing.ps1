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

# Properties prefixed with '_' are metadata (color hints etc.) — excluded from display
function Write-ColorTable {
    param([object[]]$Rows)
    if (-not $Rows -or $Rows.Count -eq 0) { return }

    $Props = $Rows[0].PSObject.Properties.Name | Where-Object { $_ -notmatch '^_' }

    $Widths = @{}
    foreach ($P in $Props) {
        $Widths[$P] = $P.Length
        foreach ($R in $Rows) {
            $Len = "$($R.$P)".Length
            if ($Len -gt $Widths[$P]) { $Widths[$P] = $Len }
        }
    }

    Write-Host (($Props | ForEach-Object { $_.PadRight($Widths[$_]) }) -join '  ') -ForegroundColor DarkGray
    Write-Host (($Props | ForEach-Object { '-' * $Widths[$_] }) -join '  ') -ForegroundColor DarkGray

    foreach ($Row in $Rows) {
        $Color = if ($Row.PSObject.Properties['_Color']) { $Row._Color } else { 'White' }
        Write-Host (($Props | ForEach-Object { "$($Row.$_)".PadRight($Widths[$_]) }) -join '  ') -ForegroundColor $Color
    }
    Write-Host ''
}

function Get-ItemColor {
    param($Item)
    if ($Item.PSIsContainer)                                        { return 'Cyan' }
    if ($Item.Attributes -band [IO.FileAttributes]::System)         { return 'DarkYellow' }
    if ($Item.Attributes -band [IO.FileAttributes]::Hidden)         { return 'DarkGray' }
    return 'White'
}

# ll — long listing with human-readable sizes
function Get-LongList {
    [CmdletBinding()]
    param([string]$Path = '.')
    $Items = Get-ChildItem -LiteralPath $Path | ForEach-Object {
        [PSCustomObject]@{
            Mode     = $_.Mode
            Modified = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
            Size     = if ($_.PSIsContainer) { '    <DIR>' } else { Format-FileSize $_.Length }
            Name     = $_.Name
            _Color   = Get-ItemColor $_
        }
    }
    Write-ColorTable $Items
}

# la — long listing including hidden and system files
function Get-AllFiles {
    [CmdletBinding()]
    param([string]$Path = '.')
    $Items = Get-ChildItem -LiteralPath $Path -Force | ForEach-Object {
        [PSCustomObject]@{
            Mode     = $_.Mode
            Modified = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
            Size     = if ($_.PSIsContainer) { '    <DIR>' } else { Format-FileSize $_.Length }
            Name     = $_.Name
            _Color   = Get-ItemColor $_
        }
    }
    Write-ColorTable $Items
}

# lr — recursive flat listing with relative paths
function Get-RecursiveList {
    [CmdletBinding()]
    param([string]$Path = '.')
    $Base = (Resolve-Path $Path).Path.TrimEnd('\') + '\'
    $Items = Get-ChildItem -LiteralPath $Path -Recurse | ForEach-Object {
        [PSCustomObject]@{
            Mode     = $_.Mode
            Modified = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
            Size     = if ($_.PSIsContainer) { '    <DIR>' } else { Format-FileSize $_.Length }
            Path     = $_.FullName.Replace($Base, '')
            _Color   = Get-ItemColor $_
        }
    }
    Write-ColorTable $Items
}

# lss — files sorted by size, largest first
function Get-SortedBySize {
    [CmdletBinding()]
    param([string]$Path = '.')
    $Items = Get-ChildItem -LiteralPath $Path -File |
        Sort-Object Length -Descending |
        ForEach-Object {
            [PSCustomObject]@{
                Size     = Format-FileSize $_.Length
                Modified = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
                Name     = $_.Name
                _Color   = Get-ItemColor $_
            }
        }
    Write-ColorTable $Items
}

# ldu — total recursive size per item, sorted largest first (like du -sh *)
function Get-DirSize {
    [CmdletBinding()]
    param([string]$Path = '.')
    $RawItems = Get-ChildItem -LiteralPath $Path | ForEach-Object {
        $Item = $_
        $Bytes = if ($Item.PSIsContainer) {
            (Get-ChildItem $Item.FullName -Recurse -File -ErrorAction SilentlyContinue |
             Measure-Object -Property Length -Sum).Sum ?? 0
        } else { $Item.Length }
        [PSCustomObject]@{ Bytes = $Bytes; IsDir = $Item.PSIsContainer; Name = $Item.Name }
    }
    $Items = $RawItems | Sort-Object Bytes -Descending | ForEach-Object {
        [PSCustomObject]@{
            Size   = Format-FileSize $_.Bytes
            Type   = if ($_.IsDir) { 'dir' } else { 'file' }
            Name   = $_.Name
            _Color = if ($_.IsDir) { 'Cyan' } else { 'White' }
        }
    }
    Write-ColorTable $Items
}
