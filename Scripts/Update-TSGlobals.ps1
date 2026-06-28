<#
.PARAMETER Description
    Build tool entry point for Update-TSGlobals. Loads the profile and forwards arguments — call with pwsh -File instead of powershell -Command.
#>

param (
    [Parameter(Position = 0)]
    [string]$SourcePath = ".",

    [Parameter(Position = 1)]
    [string]$OutputFilePath = "globals.d.ts",

    [switch]$Force
)

# Local functions to run when building
. "D:\PowerShell\_profile.ps1"

Update-TSGlobals -SourcePath $SourcePath -OutputFilePath $OutputFilePath -Force:$Force
