param (
    [string]$csprojPath
)

try {
    # 1. Automatically fetch the short git commit hash from the repository
    $commitHash = (git rev-parse --short HEAD 2>$null)
    if ([string]::IsNullOrWhiteSpace($commitHash)) {
        $commitHash = "unknown"
        Write-Warning "Could not retrieve git commit hash. Defaulting to 'unknown'."
    } else {
        $commitHash = $commitHash.Trim()
    }

    # 2. Locate the first .csproj in the current directory if no path is supplied
    if ([string]::IsNullOrWhiteSpace($csprojPath)) {
        $foundFiles = Get-ChildItem -Path "." -Filter "*.csproj" -Recurse -ErrorAction SilentlyContinue
        if ($foundFiles) {
            $csprojPath = $foundFiles.FullName
            Write-Host "No path supplied. Automatically selected project: $($foundFiles.Name)" -ForegroundColor Gray
        } else {
            Write-Warning "No .csproj file detected in the current workspace directory."
        }
    }

    # Force an absolute path evaluation to ensure file system tracking
    $absoluteCsprojPath = $null
    if ($csprojPath -and (Test-Path $csprojPath)) {
        $absoluteCsprojPath = (Get-Item $csprojPath).FullName
    }

    # 3. Read the VersionPrefix or Version directly from the physical file
    $currentVersion = ""
    if ($absoluteCsprojPath) {
        [xml]$csprojTest = Get-Content -Path $absoluteCsprojPath
        $targetGroup = $csprojTest.Project.PropertyGroup | Where-Object { $_.VersionPrefix -or $_.Version } | Select-Object -First 1
        if ($targetGroup.VersionPrefix) { $currentVersion = $targetGroup.VersionPrefix }
        elseif ($targetGroup.Version) { $currentVersion = $targetGroup.Version }
    }

    # Fallback default value if both the path and xml keys are missing
    if ([string]::IsNullOrWhiteSpace($currentVersion)) {
        $currentVersion = "1.0.0"
    }

    $currentVersion = $currentVersion.Trim()

    # 4. Parse the 3-digit version block safely
    $v = [version]$currentVersion
    
    # 5. Increment the third patch digit (e.g., 5.7.71 -> 5.7.72)
    $newVersion = [string]::Format('{0}.{1}.{2}', $v.Major, $v.Minor, ($v.Build + 1))
    $informationalVersion = "$newVersion+$commitHash"
    Write-Host "Incrementing application version to: $newVersion (Info: $informationalVersion)" -ForegroundColor Cyan

    # 6. Update the physical .csproj file on disk
    if ($absoluteCsprojPath) {
        [xml]$csproj = Get-Content -Path $absoluteCsprojPath

        # Force structural tracking on a singular PropertyGroup
        $propertyGroup = $csproj.Project.PropertyGroup | Select-Object -First 1
        
        # Handle standard .NET <VersionPrefix> using native method to avoid wrapper bugs
        $prefixNode = $propertyGroup.SelectSingleNode("VersionPrefix")
        if ($null -ne $prefixNode) {
            $prefixNode.set_InnerText($newVersion)
        } else {
            $prefixNode = $csproj.CreateElement("VersionPrefix")
            $prefixNode.set_InnerText($newVersion)
            $propertyGroup.AppendChild($prefixNode) | Out-Null
        }

        # Handle <InformationalVersion> using native method to bypass wrapper bugs
        $infoNode = $propertyGroup.SelectSingleNode("InformationalVersion")
        if ($null -ne $infoNode) {
            $infoNode.set_InnerText($informationalVersion)
        } else {
            $infoNode = $csproj.CreateElement("InformationalVersion")
            $infoNode.set_InnerText($informationalVersion)
            $propertyGroup.AppendChild($infoNode) | Out-Null
        }

        # Save to absolute path string
        $csproj.Save($absoluteCsprojPath)
        Write-Host "Successfully updated .csproj file VersionPrefix and informational hash tags." -ForegroundColor Green
    }

    # 7. Synchronize cleanly into package.json
    $jsonPath = "package.json"
    if (Test-Path $jsonPath) {
        $json = Get-Content -Raw -Path $jsonPath | ConvertFrom-Json
        $json.version = $newVersion
        
        # Enforce clean UTF-8 formatting without Byte Order Mark (BOM)
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText((Get-Item $jsonPath).FullName, ($json | ConvertTo-Json -Depth 100), $utf8NoBom)
        
        Write-Host "Successfully synced package.json metadata field." -ForegroundColor Green
    } else {
        Write-Warning "Could not locate package.json workspace file."
    }

    # 8. Automate the Git Stage & Commit Process
    # We check if a Publish or Release build is actively running. 
    # If you run the script manually or during local debug, it will safely skip committing.
    $isPublish = ($env:PublishProtocol -or $env:DeployOnBuild -eq "true" -or $env:Configuration -eq "Release")

    if ($isPublish) {
        Write-Host "Publish/Release environment detected. Staging build config files..." -ForegroundColor Gray
        
        git add $jsonPath 2>&1
        if ($absoluteCsprojPath) { git add $absoluteCsprojPath 2>&1 }

        # Check if there are actual changes staged before running commit
        $gitStatus = git status --porcelain 2>&1
        if ($gitStatus) {
            Write-Host "Changes detected. Committing version changes..." -ForegroundColor Yellow
            git commit -m "chore(release): bump application version to $newVersion [skip ci]" 2>&1
            
            Write-Host "Pushing version updates to remote origin..." -ForegroundColor Gray
            git push origin HEAD --quiet
        } else {
            Write-Host "No distinct file changes detected. Skipping Git sequence." -ForegroundColor Gray
        }
    } else {
        Write-Host "Local build or manual test detected. Skipping Git commit and push steps." -ForegroundColor Yellow
    }

    # 9. Return the new version string back cleanly to the parent MSBuild engine
    Write-Output "RESULT_VERSION:$newVersion"

} catch {
    # Isolate variable using braces to prevent trailing colon interference
    $lineNumber = $_.InvocationInfo.ScriptLineNumber
    Write-Error "Failed to run version increment task at line ${lineNumber}: $_"
    exit 1
}
