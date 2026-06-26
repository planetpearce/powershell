function Enable-VS {
    [CmdletBinding()]
    param()
    process {
        Write-Host "Initializing Visual Studio Build Tools..." -ForegroundColor Cyan
        
        $VsWherePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

        if (Test-Path $VsWherePath) {
            $VsInstallPath = & $VsWherePath -latest -property installationPath
            $VsModulePath = "$VsInstallPath\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"

            if (Test-Path $VsModulePath) {
                # Import the module cleanly
                Import-Module $VsModulePath -ErrorAction SilentlyContinue
                
                # Load the tools without resetting your current active folder directory
                Enter-VsDevShell -VsInstallPath $VsInstallPath -SkipAutomaticLocation
                Write-Host "✓ Visual Studio Developer Prompt Initialized!" -ForegroundColor Green
            } else {
                Write-Host "✗ Visual Studio DevShell module not found" -ForegroundColor Yellow
            }
        } else {
            Write-Host "✗ vswhere.exe not found. Visual Studio might not be installed." -ForegroundColor Red
        }
    }
}
