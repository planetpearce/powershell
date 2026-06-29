<#
.PARAMETER Alias
    find
.PARAMETER Description
    Searches for a string in files recursively.
#>
function Find-In-Files {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$SearchString,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$Extension = "*.*"
    )

Get-ChildItem -Recurse -Filter $Extension -File | 
    Select-String -Pattern $SearchString | 
    Select-Object @{Name = "File"; Expression = { Resolve-Path $_.Path -Relative }}, 
                  LineNumber, 
                  @{Name = "Match"; Expression = { $_.Line.Trim() }} | 
    Format-Table File, LineNumber, Match -AutoSize
}