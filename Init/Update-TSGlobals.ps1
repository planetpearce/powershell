<#
.PARAMETER Description
    Recursively walks JavaScript module directories, parses structural variables and function signatures, and generates a strongly-typed globals.d.ts declaration file for IntelliSense.
#>
function Update-TSGlobals {
    <#
    .SYNOPSIS
        Recursive TypeScript Declaration Compiler with Automation Protections.
    .DESCRIPTION
        This script walks your JavaScript module directory structures, parses out the 
        structural variables, properties, and parameters, and builds a comprehensive, 
        strongly-typed globals.d.ts sheet for Visual Studio / ReSharper IntelliSense.
    .LOCATION GUIDELINES
        - TARGET FOLDER: src/globals.d.ts
        - Placement next to the core 'src/js/' code directory guarantees that type definitions 
          bubble up and apply to all custom modules and server-side Razor view .cshtml sections [5.3].
        - This location allows Webpack to completely skip bundling the file, ensuring 0 bytes 
          of tracking weight or bloat leak into your highly compressed app.js production file [5.3].
    .SAFETY & LIFECYCLE CONTROLS
        - SupportsShouldProcess: Uses native validation checks before executing destructive hard-drive updates.
        - Safety Intercept Interruption: PromptForChoice checks for an existing globals.d.ts sheet. If missing, 
          it assumes execution may be running in the wrong folder path and triggers an interactive block.
        - [-Force] Automation Override: Bypasses user choice validations entirely. This allows your Webpack watch 
          lifecycle runner (compiler.hooks.watchRun) to trigger the tool silently and instantly on file save [5.3].
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Position = 0)]
        [string]$SourcePath = ".",

        [Parameter(Position = 1)]
        [string]$OutputFilePath = "globals.d.ts",

        [Switch]$Force
    )

    process {
        # 1. Resolve and validate the target source directory paths cleanly
        $resolvedSource = Resolve-Path $SourcePath
        
        # 2. Check if a globals.d.ts tracker file already exists in the destination path
        $FileExists = Test-Path $OutputFilePath

        # 3. THE SAFETY INTERCEPT LAYER: If file is NOT found and -Force is NOT passed, demand user confirmation
        if (-not $FileExists -and -not $Force) {
            Write-Host "`n⚠️  WARNING: 'globals.d.ts' was not found in the target directory." -ForegroundColor Yellow
            Write-Host "You may be executing this script inside the wrong project folder location." -ForegroundColor Yellow
            Write-Host "Target Directory: $resolvedSource`n" -ForegroundColor Gray
            
            # Fire a native, interactive confirmation prompt window directly inside VIOLETTA
            $Title   = "Confirm TypeScript Declaration Generation"
            $Message = "Are you sure you want to initialize a new globals.d.ts file here?"
            $Choices = [Management.Automation.Host.ChoiceDescription[]] @(
                (New-Object Management.Automation.Host.ChoiceDescription "&Yes", "Proceed and generate the declaration map definitions."),
                (New-Object Management.Automation.Host.ChoiceDescription "&No", "Abort the compilation loop safely.")
            )
            
            $Decision = $Host.UI.PromptForChoice($Title, $Message, $Choices, 1) # Default selection is 'No' (Index 1)
            
            if ($Decision -ne 0) {
                Write-Host "❌ Compilation aborted by user sequence safety stop." -ForegroundColor Red
                return
            }
        }

        # 4. Target destination file path creation can now execute safely
        $resolvedOutput = New-Item -ItemType File -Path $OutputFilePath -Force
        
        Write-Host "=========================================================================" -ForegroundColor DarkYellow
        Write-Host "🚀 STARTING RECURSIVE TYPESCRIPT DECLARATION COMPILER" -ForegroundColor Cyan
        Write-Host "=========================================================================" -ForegroundColor DarkYellow
        Write-Host "📁 SCANNING PATH : $resolvedSource" -ForegroundColor Gray
        Write-Host "📝 WRITING FILE  : $resolvedOutput" -ForegroundColor Gray
        Write-Host "-------------------------------------------------------------------------" -ForegroundColor DarkYellow

        $interfacesBuffer = @()
        $globalLibraryMap = @()

        $jsFiles = Get-ChildItem -Path $resolvedSource -Filter "*.js" -Recurse
        
        foreach ($file in $jsFiles) {
            $content = Get-Content $file.FullName -Raw
            
            # Broadened regular expression matching boundaries to absorb any custom name lengths
            if ($content -match '(?:var|const|let)\s+(?<moduleName>\w+)\s*=\s*\{(?<objectContent>[\s\S]*?)\}\s*(?:export|$)') {
                $moduleName = $Matches['moduleName']
                $objectContent = $Matches['objectContent']
                
                $interfaceName = (Get-Culture).TextInfo.ToTitleCase($moduleName) + "Module"
                
                Write-Host "📦 Processing: ${moduleName} ➔ ${interfaceName}" -ForegroundColor Yellow

                $moduleLines = @()
                $moduleLines += "interface $interfaceName {"

                $lines = $objectContent -split "`r?`n"
                foreach ($line in $lines) {
                    $trimmed = $line.Trim()
                    
                    if ($trimmed -match '^(?<funcName>\w+)\s*:\s*function\s*\((?<params>[^)]*)\)') {
                        $funcName = $Matches['funcName']
                        $params = $Matches['params'].Trim()
                        
                        if ($params) {
                            $typedParams = ($params -split ',' | ForEach-Object { "$($_.Trim()): any" }) -join ', '
                        } else {
                            $typedParams = ""
                        }
                        $moduleLines += "    $funcName($typedParams): void;"
                    }
                    elseif ($trimmed -match '^(?<propName>\w+)\s*:\s*(?<value>[^,]+),?') {
                        $propName = $Matches['propName']
                        $val = $Matches['value'].Trim()
                        
                        $type = "any"
                        if ($val -match '^["''\`](.*)["''\`]') { $type = "string" }
                        elseif ($val -match '^(true|false)$') { $type = "boolean" }
                        elseif ($val -match '^\d+$') { $type = "number" }
                        
                        if ($val -notmatch 'function') {
                            $moduleLines += "    ${propName}: ${type};"
                        }
                    }
                }
                $moduleLines += "}`n"
                $interfacesBuffer += ($moduleLines -join "`r`n")
                $globalLibraryMap += "    ${moduleName}: ${interfaceName};"
            }
        }

        # Rebuild the final globals.d.ts payload cleanly
        $finalFileContents = @()
        $finalFileContents += "/* =========================================================================`r`n   📁 AUTOMATICALLY GENERATED DEPLOYMENT TYPE DEFINITIONS`r`n   ========================================================================= */`r`n"
        $finalFileContents += ($interfacesBuffer -join "`r`n")
        $finalFileContents += "interface GlobalOopsLib {"
        $finalFileContents += ($globalLibraryMap -join "`r`n")
        $finalFileContents += "}`n"
        $finalFileContents += "/** Centralized design-time contract mapping for the background IDE indexer. */"
        $finalFileContents += "declare var OopsLib: GlobalOopsLib;"

        $finalFileContents -join "`r`n" | Set-Content -Path $resolvedOutput -NoNewline
        Write-Host "=========================================================================" -ForegroundColor DarkYellow
    }
}
