<#
.PARAMETER Alias
    cmds
.PARAMETER Description
    Lists all loaded Init utilities and available Scripts with their aliases and descriptions. Use -Library for an expanded view.
#>
function Get-Commands {
    [CmdletBinding()]
    param(
        [switch]$Library
    )

    $Mode = if ($Library) { 'Library' } else { 'Compact' }

    Write-Host "`n⚡ Loaded System Core Utilities (./Init)" -ForegroundColor Cyan

    Get-ChildItem -Path "D:\PowerShell\Init" -Filter *.ps1 | ForEach-Object {
        $Meta = Get-ScriptMetadata -FilePath $_.FullName
        Format-ScriptEntry -Name $_.BaseName -Alias $Meta.Alias -Description $Meta.Description -Mode $Mode
    }

    Write-Host "`n⚡ Initialized Scripts (./Scripts)" -ForegroundColor Cyan
    
    Get-ChildItem -Path "D:\PowerShell\Scripts" -Filter *.ps1 | ForEach-Object {
        $Meta = Get-ScriptMetadata -FilePath $_.FullName
        Format-ScriptEntry -Name $_.BaseName -Alias $Meta.Alias -Description $Meta.Description -Mode $Mode
    }

    Write-Host "`n⚡ Profile Aliases" -ForegroundColor Cyan

    Select-String -Path "D:\PowerShell\_profile.ps1" -Pattern '^\s*Set-Alias\s+(\S+)\s+(\S+)' |
        ForEach-Object {
            $Groups = $_.Matches[0].Groups
            $AliasName = $Groups[1].Value
            $Target    = $Groups[2].Value
            Write-Host ("   {0,-15} → {1}" -f $AliasName, $Target) -ForegroundColor Gray
        }
}
