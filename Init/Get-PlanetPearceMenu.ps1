# =========================================================================
# 🌌 PLANET PEARCE: AUTOMATED FUZZY COMMAND RADAR INTERFACE
# =========================================================================

# Capture the exact directory where this initialization script lives on boot
$CurrentInitDirectory = $PSScriptRoot

function Get-PlanetPearceMenu {
    # 1. 🟢 FIXED: Uses the pre-captured boot path variable, ensuring it never returns null at runtime
    $InitFolder = $global:CurrentInitDirectory
    
    # 2. Automatically harvest the BaseNames of ALL your customization files inside init/
    if (Test-Path $InitFolder) {
        $InitFunctionNames = Get-ChildItem -Path $InitFolder -Filter "*.ps1" -File | 
            Select-Object -ExpandProperty BaseName

        # 3. Fetch only the valid, currently loaded session functions matching those names
        $CustomFunctions = Get-Command -CommandType Function | 
            Where-Object { $InitFunctionNames -contains $_.Name } | 
            Select-Object -ExpandProperty Name

        # 4. Pipe the complete list into the interactive fzf window buffer
        if ($CustomFunctions) {
            $Selection = $CustomFunctions | Invoke-Fzf -Prompt "🪐 Planet Pearce Radar > " -Height 12 -Reverse
            
            # If an item is selected via Enter, fire its execution loop immediately
            if ($Selection) {
                Write-Host "`n🚀 Executing: $Selection..." -ForegroundColor Cyan
                Invoke-Expression $Selection
            }
        } else {
            Write-Warning "No active initialization functions matched the loaded session space."
        }
    } else {
        Write-Warning "Could not resolve the physical initialization directory map path: $InitFolder"
    }
}

# Register your shorthand alias hook directly inside the session space environment
Set-Alias pp Get-PlanetPearceMenu
