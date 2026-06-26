# =====================================================================
# High-Performance Script Metadata Loader & Dashboard Engine
# =====================================================================

function Get-ScriptMetadata {
    param([string]$FilePath)
    
    $MetaData = @{ Alias = $null; Description = "No description provided." }
    
    if (Test-Path $FilePath) {
        $Tokens = $null
        $Errors = $null
        $AST = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$Tokens, [ref]$Errors)
        
        # Isolate the very first block comment token at the top of the file
        $HeaderComment = $Tokens | Where-Object { $_.Kind -eq 'Comment' -and $_.Text -like '<#*' } | Select-Object -First 1
        
        if ($HeaderComment) {
            $CommentText = $HeaderComment.Text
            
            # Extract Alias: Matches until the end of that specific line
            if ($CommentText -match '(?i)\.PARAMETER\s+Alias\s+(?<Value>[^\r\n]+)') {
                $MetaData.Alias = $Matches['Value'].Trim()
            }
            
            # Extract Description: Matches multi-line blocks until it hits another dot-parameter or the closing comment tag
            if ($CommentText -match '(?i)\.PARAMETER\s+Description\s+(?<Value>(?s).*?)(?=\r?\n\s*\.\w+|\r?\n\s*#>)') {
                # Clean up formatting whitespace and replace internal line breaks with spaces
                $CleanDesc = $Matches['Value'].Trim() -replace '\r?\n\s*', ' '
                $MetaData.Description = $CleanDesc
            }
        }
    }
    return $MetaData
}

function Format-ScriptEntry {
    param(
        [string]$Name,
        [string]$Alias,
        [string]$Description,
        [ValidateSet('Compact', 'Library')]
        [string]$Mode = 'Compact'
    )

    $TermWidth = try { $Host.UI.RawUI.WindowSize.Width } catch { 120 }
    if ($TermWidth -lt 60) { $TermWidth = 120 }

    if ($Mode -eq 'Library') {
        $DisplayAlias = if ($Alias) { " ($Alias)" } else { '' }
        Write-Host "  $Name" -NoNewline -ForegroundColor White
        Write-Host $DisplayAlias -ForegroundColor DarkYellow
        Write-Host "    $Description" -ForegroundColor DarkGray
    } else {
        # Compact: fixed columns, description truncated to terminal width
        $DisplayAlias = if ($Alias) { "($Alias)" } else { '' }
        $FixedWidth = 2 + 25 + 1 + 10 + 3  # '  ' + name + ' ' + alias + ' | '
        $MaxDesc = [Math]::Max(10, $TermWidth - $FixedWidth)
        $TruncDesc = if ($Description.Length -gt $MaxDesc) { $Description.Substring(0, $MaxDesc - 1) + [char]0x2026 } else { $Description }
        Write-Host ("  {0,-25} {1,-10} | {2}" -f $Name, $DisplayAlias, $TruncDesc) -ForegroundColor Gray
    }
}

Write-Host "⚡ Functions Initialized" -ForegroundColor Cyan

# ---------------------------------------------------------------------
# 1. Process and Load Initialization Functions (./Init)
# ---------------------------------------------------------------------
$InitFolder = "D:\PowerShell\Init"
if (Test-Path $InitFolder) {
    Write-Host "`n[+] Loading System Core Utilities (./Init):" -ForegroundColor Green
    
    Get-ChildItem -Path $InitFolder -Filter *.ps1 | ForEach-Object {
        $Meta = Get-ScriptMetadata -FilePath $_.FullName
        
        # Dot-source the file into memory so the functions are globally available
        . $_.FullName
        
        Format-ScriptEntry -Name $_.BaseName -Alias $Meta.Alias -Description $Meta.Description

        # If an alias was defined, dynamically map it to execute this specific utility
        if ($Meta.Alias) {
            $FunctionName = $_.BaseName
            Set-Item -Path "Function:\script-alias-$($Meta.Alias)" -Value ([scriptblock]::Create($FunctionName))
            Set-Alias -Name $Meta.Alias -Value "script-alias-$($Meta.Alias)" -Scope Global -Force
        }
    }
}

# ---------------------------------------------------------------------
# 2. Map and List Operational DevOps Scripts (./Scripts)
# ---------------------------------------------------------------------
$ScriptsFolder = "D:\PowerShell\Scripts"
if (Test-Path $ScriptsFolder) {
    Write-Host "`n[+] Available Deployment & Automation Scripts (./Scripts):" -ForegroundColor Yellow
    
    Get-ChildItem -Path $ScriptsFolder -Filter *.ps1 | ForEach-Object {
        $Meta = Get-ScriptMetadata -FilePath $_.FullName
        
        Format-ScriptEntry -Name $_.BaseName -Alias $Meta.Alias -Description $Meta.Description

        # Dynamically map the alias to execute the standalone script path
        if ($Meta.Alias) {
            $ScriptPath = $_.FullName
            Set-Item -Path "Function:\script-alias-$($Meta.Alias)" -Value [scriptblock]::Create("& '$ScriptPath'")
            Set-Alias -Name $Meta.Alias -Value "script-alias-$($Meta.Alias)" -Scope Global -Force
        }
    }
}
Write-Host "`n=====================================================================" -ForegroundColor Cyan

