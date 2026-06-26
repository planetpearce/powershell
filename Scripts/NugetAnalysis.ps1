<#
.PARAMETER Description
    Scans all .csproj files in the current solution directory and opens a NuGet package inventory grid view showing installed versions and any version conflicts.
#>
# Run this from the root of your solution directory
$solutionPath = Get-Location
Write-Host "Scanning $solutionPath for NuGet packages..." -ForegroundColor Cyan

# Find all .csproj files and extract PackageReference elements
$packageData = Get-ChildItem -Filter *.csproj -Recurse | Get-Content | 
    Select-String -Pattern '<PackageReference Include="([^"]+)" Version="([^"]+)"' -AllMatches | 
    ForEach-Object { $_.Matches } | 
    Select-Object @{Name='ID'; Expression={$_.Groups[1].Value}}, @{Name='Version'; Expression={$_.Groups[2].Value}}

# Group by ID and list unique versions per package
$packageData | Group-Object ID | ForEach-Object {
    [PSCustomObject]@{
        PackageID = $_.Name
        Versions  = ($_.Group.Version | Select-Object -Unique) -join ", "
    }
} | Sort-Object PackageID | Out-GridView -Title "Solution NuGet Inventory"
