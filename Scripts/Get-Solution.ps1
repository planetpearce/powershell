param(
	[string]$SolutionPath = "CorePackages\CorePackages.slnx"
)

function Get-ProjectType {
	param([string]$ProjectPath)

	if (-not (Test-Path $ProjectPath)) {
		return "Unknown (file not found)"
	}

	try {
		[xml]$proj = Get-Content $ProjectPath
		$sdk = $proj.Project.Sdk
		$outputType = $proj.Project.PropertyGroup.OutputType | Select-Object -First 1
		$targetFramework = $proj.Project.PropertyGroup.TargetFramework | Select-Object -First 1
		$targetFrameworks = $proj.Project.PropertyGroup.TargetFrameworks | Select-Object -First 1

		# Determine project type
		$type = "Unknown"

		if ($sdk) {
			# SDK-style project
			switch ($sdk) {
				"Microsoft.NET.Sdk" {
					if ($outputType -eq "Exe") { $type = "Console Application" }
					elseif ($outputType -eq "Library") { $type = "Class Library" }
					elseif ($outputType -eq "WinExe") { $type = "Windows Application" }
					else { $type = "Class Library" }
				}
				"Microsoft.NET.Sdk.Web" { $type = "ASP.NET Core Web Application" }
				"Microsoft.NET.Sdk.Worker" { $type = "Worker Service" }
				"Microsoft.NET.Sdk.Razor" { $type = "Razor Class Library" }
				"Microsoft.NET.Sdk.BlazorWebAssembly" { $type = "Blazor WebAssembly" }
				default { $type = "SDK: $sdk" }
			}
		}
		else {
			# Legacy project format
			$projectTypeGuids = $proj.Project.PropertyGroup.ProjectTypeGuids
			if ($projectTypeGuids -match "{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") {
				$type = "C# Project (Legacy)"
			}
		}

		# Add output type if available
		if ($outputType -and $type -ne "Unknown") {
			$type += " ($outputType)"
		}

		# Add framework info
		$framework = if ($targetFrameworks) { $targetFrameworks } else { $targetFramework }
		if ($framework) {
			$type += " [$framework]"
		}

		return $type
	}
	catch {
		return "Error reading project: $_"
	}
}

# Resolve solution path
$solutionFullPath = if ([System.IO.Path]::IsPathRooted($SolutionPath)) {
	$SolutionPath
} else {
	Join-Path (Get-Location) $SolutionPath
}

if (-not (Test-Path $solutionFullPath)) {
	Write-Error "Solution file not found: $solutionFullPath"
	exit 1
}

Write-Host "`nSolution: $solutionFullPath" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

$solutionDir = Split-Path $solutionFullPath -Parent
$extension = [System.IO.Path]::GetExtension($solutionFullPath)

$projects = @()

if ($extension -eq ".slnx") {
	# Parse .slnx (XML format)
	Write-Host "Parsing .slnx solution file..." -ForegroundColor Yellow
	[xml]$slnx = Get-Content $solutionFullPath

	foreach ($project in $slnx.Solution.Projects.Project) {
		$projectPath = $project.path
		if ($projectPath) {
			$fullProjectPath = Join-Path $solutionDir $projectPath
			$projects += [PSCustomObject]@{
				Name = [System.IO.Path]::GetFileNameWithoutExtension($projectPath)
				Path = $projectPath
				FullPath = $fullProjectPath
			}
		}
	}
}
else {
	# Parse .sln (text format)
	Write-Host "Parsing .sln solution file..." -ForegroundColor Yellow
	$slnContent = Get-Content $solutionFullPath

	foreach ($line in $slnContent) {
		if ($line -match 'Project\("\{[A-F0-9-]+\}"\)\s*=\s*"([^"]+)",\s*"([^"]+)"') {
			$projectName = $matches[1]
			$projectPath = $matches[2]

			# Skip solution folders
			if ($projectPath -match '\.(csproj|vbproj|fsproj)$') {
				$fullProjectPath = Join-Path $solutionDir $projectPath
				$projects += [PSCustomObject]@{
					Name = $projectName
					Path = $projectPath
					FullPath = $fullProjectPath
				}
			}
		}
	}
}

if ($projects.Count -eq 0) {
	Write-Host "`nNo projects found in solution." -ForegroundColor Yellow
	exit 0
}

Write-Host "`nFound $($projects.Count) project(s):`n" -ForegroundColor Green

# Output projects with their types
$results = @()
foreach ($project in $projects) {
	$type = Get-ProjectType -ProjectPath $project.FullPath
	$results += [PSCustomObject]@{
		Name = $project.Name
		Type = $type
		Path = $project.Path
	}
}

# Display in a formatted table
$results | Format-Table -AutoSize -Wrap

Write-Host "`n" -ForegroundColor Cyan
